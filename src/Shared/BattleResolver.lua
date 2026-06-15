--!strict
-- BattleResolver.lua
-- Pure, deterministic, seed-driven probabilistic battle simulation.
--
-- The SERVER is authoritative: it picks a random seed, runs resolve(), stores
-- the winner and rewards, then ships the seed + loadouts to both clients. Each
-- client re-runs resolve() with the same seed to animate the *exact* same
-- clash. No combat trust is placed on the client.

local Config = require(script.Parent.Config)
local BeybladeData = require(script.Parent.BeybladeData)
local CategoryData = require(script.Parent.CategoryData)

local BattleResolver = {}

export type Loadout = {
	BladeId: string,
	Rarity: string,
}

export type RoundLog = {
	Index: number,
	ScoreA: number,
	ScoreB: number,
	Winner: number, -- 1, 2, or 0 (clash/tie)
	StaminaA: number,
	StaminaB: number,
	Crit: boolean,
	Dodge: boolean,
}

export type Result = {
	Seed: number,
	Winner: number, -- 1 or 2
	Rounds: { RoundLog },
	A: Loadout,
	B: Loadout,
	WinChanceA: number, -- pre-battle estimate, for UI
}

type Fighter = {
	loadout: Loadout,
	atk: number,
	def: number,
	speed: number,
	weight: number,
	stamina: number,
	maxStamina: number,
	element: string,
	effect: string,
	power: number,
	roundsWon: number,
	usedRevive: boolean,
}

local function buildFighter(loadout: Loadout): Fighter
	local def = BeybladeData.get(loadout.BladeId)
	local stats = BeybladeData.effectiveStats(loadout.BladeId, loadout.Rarity)
	assert(def and stats, "unknown blade: " .. tostring(loadout.BladeId))
	return {
		loadout = loadout,
		atk = stats.Attack,
		def = stats.Defense,
		speed = stats.Speed,
		weight = stats.Weight,
		stamina = stats.Stamina,
		maxStamina = stats.Stamina,
		element = def.Element,
		effect = def.Ability.Effect,
		power = stats.Attack + stats.Defense + stats.Stamina,
		roundsWon = 0,
		usedRevive = false,
	}
end

-- Offensive score for one fighter striking the other in a given round.
local function strikeScore(self: Fighter, foe: Fighter, roundIndex: number, rng: Random): (number, boolean, boolean)
	local def = BeybladeData.get(self.loadout.BladeId)
	local ability = def and def.Ability
	local power = ability and ability.Power or 0

	local atk = self.atk
	local pierce = 0
	local crit = false
	local dodge = false

	-- Ability effects that modify offense.
	if self.effect == "first_round_attack" and roundIndex == 1 then
		atk *= (1 + power)
	elseif self.effect == "ramp_attack" then
		atk *= (1 + power * self.roundsWon)
	elseif self.effect == "defense_pierce" then
		pierce = power
	elseif self.effect == "crit_chance" and rng:NextNumber() < power then
		atk *= 1.6
		crit = true
	elseif self.effect == "desperation" and self.stamina < self.maxStamina * 0.4 then
		atk *= (1 + power)
	end

	-- Element affinity (rock/paper/scissors ring).
	atk *= CategoryData.affinity(self.element, foe.element)

	-- Effective enemy defense (after pierce + defensive abilities).
	local foeDef = foe.def
	if foe.effect == "high_stamina_defense" and foe.stamina > foe.maxStamina * 0.5 then
		local fb = BeybladeData.get(foe.loadout.BladeId)
		foeDef *= (1 + (fb and fb.Ability.Power or 0))
	end
	foeDef *= (1 - pierce)

	-- Defender may evade entirely.
	if foe.effect == "dodge_chance" and rng:NextNumber() < (BeybladeData.get(foe.loadout.BladeId).Ability.Power) then
		dodge = true
		return 0, crit, true
	end

	-- Core probabilistic score: attack vs defense, plus speed initiative and
	-- a variance term so weaker blades can still upset stronger ones.
	local base = atk * 1.0 - foeDef * 0.55 + self.speed * 0.25
	local variance = Config.Battle.Variance
	local noise = rng:NextNumber(1 - variance, 1 + variance)
	local score = math.max(0, base) * noise
	return score, crit, dodge
end

-- Stamina spent by the loser of a round (winner spends less).
local function spendStamina(f: Fighter, amount: number)
	local saved = 0
	if f.effect == "stamina_save" then
		saved = BeybladeData.get(f.loadout.BladeId).Ability.Power
	end
	f.stamina = math.max(0, f.stamina - amount * (1 - saved))
	-- "Second wind" revive.
	if f.effect == "revive_stamina" and not f.usedRevive and f.stamina < f.maxStamina * 0.2 then
		f.usedRevive = true
		f.stamina = math.min(f.maxStamina, f.stamina + f.maxStamina * BeybladeData.get(f.loadout.BladeId).Ability.Power)
	end
end

-- Static pre-battle win estimate for A (for the matchup UI). Logistic on power.
function BattleResolver.estimate(a: Loadout, b: Loadout): number
	local pa = BeybladeData.power(a.BladeId, a.Rarity)
	local pb = BeybladeData.power(b.BladeId, b.Rarity)
	local diff = (pa - pb) / 120
	local p = 1 / (1 + math.exp(-diff))
	return math.clamp(p, 0.05, 0.95)
end

-- Full deterministic resolution. Same seed -> identical Result everywhere.
function BattleResolver.resolve(a: Loadout, b: Loadout, seed: number): Result
	local rng = Random.new(seed)
	local fa = buildFighter(a)
	local fb = buildFighter(b)
	local rounds: { RoundLog } = {}

	local totalRounds = Config.Battle.Rounds
	for i = 1, totalRounds do
		-- Both strike; higher score wins the exchange.
		local sa, critA, _ = strikeScore(fa, fb, i, rng)
		local sb, critB, dodgeB = strikeScore(fb, fa, i, rng)

		local winner: number
		if math.abs(sa - sb) < 1e-3 then
			winner = 0
		elseif sa > sb then
			winner = 1
		else
			winner = 2
		end

		-- Loser loses stamina proportional to the score gap + winner's weight.
		local gap = math.abs(sa - sb)
		if winner == 1 then
			fa.roundsWon += 1
			spendStamina(fb, 18 + gap * 0.2 + fa.weight * 0.15)
			-- counter ability
			if fb.effect == "counter_chance" and rng:NextNumber() < BeybladeData.get(fb.loadout.BladeId).Ability.Power then
				spendStamina(fa, 12)
			end
			if fa.effect == "stamina_drain" then
				fa.stamina = math.min(fa.maxStamina, fa.stamina + fb.stamina * BeybladeData.get(fa.loadout.BladeId).Ability.Power)
			end
		elseif winner == 2 then
			fb.roundsWon += 1
			spendStamina(fa, 18 + gap * 0.2 + fb.weight * 0.15)
			if fa.effect == "counter_chance" and rng:NextNumber() < BeybladeData.get(fa.loadout.BladeId).Ability.Power then
				spendStamina(fb, 12)
			end
			if fb.effect == "stamina_drain" then
				fb.stamina = math.min(fb.maxStamina, fb.stamina + fa.stamina * BeybladeData.get(fb.loadout.BladeId).Ability.Power)
			end
		end

		table.insert(rounds, {
			Index = i,
			ScoreA = math.floor(sa),
			ScoreB = math.floor(sb),
			Winner = winner,
			StaminaA = math.floor(fa.stamina),
			StaminaB = math.floor(fb.stamina),
			Crit = critA or critB,
			Dodge = dodgeB,
		})

		-- A blade with zero stamina is "out of spin" -> immediate loss.
		if fa.stamina <= 0 or fb.stamina <= 0 then
			break
		end
	end

	-- Decide the match: rounds won, then remaining stamina, then power.
	local winner: number
	if fa.stamina <= 0 and fb.stamina > 0 then
		winner = 2
	elseif fb.stamina <= 0 and fa.stamina > 0 then
		winner = 1
	elseif fa.roundsWon ~= fb.roundsWon then
		winner = (fa.roundsWon > fb.roundsWon) and 1 or 2
	elseif math.abs(fa.stamina - fb.stamina) > 1 then
		winner = (fa.stamina > fb.stamina) and 1 or 2
	else
		winner = (fa.power >= fb.power) and 1 or 2
	end

	return {
		Seed = seed,
		Winner = winner,
		Rounds = rounds,
		A = a,
		B = b,
		WinChanceA = BattleResolver.estimate(a, b),
	}
end

-- ===== Team (2v2) battles =============================================
-- Each team is a list of loadouts. Per round, every living blade strikes a
-- random living foe; team scores are summed and the losing team's living blades
-- share the stamina loss. Per-blade stamina is reported as a list so the client
-- can drain each blade's bar. Deterministic from the seed, like the 1v1 path.

local function livingMembers(team: { Fighter }): { Fighter }
	local alive = {}
	for _, f in team do
		if f.stamina > 0 then
			table.insert(alive, f)
		end
	end
	return alive
end

function BattleResolver.estimateTeams(teamA: { Loadout }, teamB: { Loadout }): number
	local pa, pb = 0, 0
	for _, l in teamA do
		pa += BeybladeData.power(l.BladeId, l.Rarity)
	end
	for _, l in teamB do
		pb += BeybladeData.power(l.BladeId, l.Rarity)
	end
	local diff = (pa - pb) / 200
	return math.clamp(1 / (1 + math.exp(-diff)), 0.05, 0.95)
end

function BattleResolver.resolveTeams(teamA: { Loadout }, teamB: { Loadout }, seed: number): any
	local rng = Random.new(seed)
	local fa: { Fighter } = {}
	local fb: { Fighter } = {}
	for _, l in teamA do
		table.insert(fa, buildFighter(l))
	end
	for _, l in teamB do
		table.insert(fb, buildFighter(l))
	end

	local rounds = {}
	local wonA, wonB = 0, 0

	for i = 1, Config.Battle.Rounds do
		local scoreA, scoreB = 0, 0
		local critAny, dodgeAny = false, false

		for _, self in fa do
			if self.stamina > 0 then
				local foes = livingMembers(fb)
				if #foes > 0 then
					local s, c, d = strikeScore(self, foes[rng:NextInteger(1, #foes)], i, rng)
					scoreA += s
					critAny = critAny or c
					dodgeAny = dodgeAny or d
				end
			end
		end
		for _, self in fb do
			if self.stamina > 0 then
				local foes = livingMembers(fa)
				if #foes > 0 then
					local s, c, d = strikeScore(self, foes[rng:NextInteger(1, #foes)], i, rng)
					scoreB += s
					critAny = critAny or c
					dodgeAny = dodgeAny or d
				end
			end
		end

		local winner = 0
		if math.abs(scoreA - scoreB) < 1e-3 then
			winner = 0
		elseif scoreA > scoreB then
			winner = 1
		else
			winner = 2
		end

		local gap = math.abs(scoreA - scoreB)
		if winner == 1 then
			wonA += 1
			local living = livingMembers(fb)
			for _, f in living do
				spendStamina(f, (18 + gap * 0.2) / math.max(1, #living) + 6)
			end
		elseif winner == 2 then
			wonB += 1
			local living = livingMembers(fa)
			for _, f in living do
				spendStamina(f, (18 + gap * 0.2) / math.max(1, #living) + 6)
			end
		end

		local staminaA, staminaB = {}, {}
		for _, f in fa do
			table.insert(staminaA, math.floor(f.stamina))
		end
		for _, f in fb do
			table.insert(staminaB, math.floor(f.stamina))
		end
		table.insert(rounds, {
			Index = i,
			ScoreA = math.floor(scoreA),
			ScoreB = math.floor(scoreB),
			Winner = winner,
			StaminaA = staminaA,
			StaminaB = staminaB,
			Crit = critAny,
			Dodge = dodgeAny,
		})

		if #livingMembers(fa) == 0 or #livingMembers(fb) == 0 then
			break
		end
	end

	local aliveA = #livingMembers(fa)
	local aliveB = #livingMembers(fb)
	local sumA, sumB = 0, 0
	for _, f in fa do
		sumA += f.stamina
	end
	for _, f in fb do
		sumB += f.stamina
	end

	local winner: number
	if aliveA == 0 and aliveB > 0 then
		winner = 2
	elseif aliveB == 0 and aliveA > 0 then
		winner = 1
	elseif wonA ~= wonB then
		winner = (wonA > wonB) and 1 or 2
	elseif math.abs(sumA - sumB) > 1 then
		winner = (sumA > sumB) and 1 or 2
	else
		winner = 1
	end

	return {
		Seed = seed,
		Winner = winner,
		Rounds = rounds,
		A = teamA,
		B = teamB,
		WinChanceA = BattleResolver.estimateTeams(teamA, teamB),
	}
end

return BattleResolver

