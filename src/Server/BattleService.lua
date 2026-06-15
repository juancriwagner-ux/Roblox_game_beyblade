--!strict
-- BattleService.lua
-- PvP matchmaking + authoritative probabilistic resolution.
--
-- Flow: client calls StartBattle -> server validates the equipped loadout and
-- either pairs the player with a waiting human or (after a short timeout) with
-- a power-matched bot. The server picks the seed, runs BattleResolver (the
-- single source of truth), grants rewards, and fires BattleResult to each
-- human so their client replays the *identical* clash animation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)
local BattleResolver = require(Shared.BattleResolver)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local ProgressService = require(script.Parent.ProgressService)
local QuestService = require(script.Parent.QuestService)

local BattleService = {}

type Ticket = { player: Player, loadout: any, power: number, trophies: number, since: number }

-- Trophies gained/lost; beating a stronger opponent is worth more.
local function trophyDelta(my: number, opp: number, won: boolean): number
	local diff = (opp - my) / 25
	if won then
		return math.clamp(math.floor(30 + diff), 12, 50)
	end
	return -math.clamp(math.floor(30 - diff), 8, 40)
end

local queue: { Ticket } = {}
local inBattle: { [Player]: boolean } = {}
local rng = Random.new()

local BOT_NAMES = {
	"Blader Kai", "Ronin", "Valt", "Shu", "Drago", "Nyx", "Tempest",
	"Aiger", "Lui", "Free", "Phantom", "Orochi", "Selena", "Xeno",
}

-- ===== Spectator: registry of recent "live" battles ===================
-- Every resolved battle (1v1 or 2v2) is registered briefly in a normalised,
-- team-style payload so spectators can replay the exact same clash.
local liveBattles: { [number]: { payload: any, expires: number } } = {}
local liveCounter = 0

local function registerLive(payload: any)
	liveCounter += 1
	local id = liveCounter
	liveBattles[id] = { payload = payload, expires = os.clock() + 12 }
	task.delay(13, function()
		liveBattles[id] = nil
	end)
end

-- Normalise a 1v1 result into the unified team payload (one blade per side).
local function normalize1v1(result: any, nameA: string, nameB: string): any
	local rounds = {}
	for _, r in result.Rounds do
		table.insert(rounds, {
			Index = r.Index, ScoreA = r.ScoreA, ScoreB = r.ScoreB, Winner = r.Winner,
			StaminaA = { r.StaminaA }, StaminaB = { r.StaminaB }, Crit = r.Crit, Dodge = r.Dodge,
		})
	end
	return {
		Seed = result.Seed, Winner = result.Winner, Mode = "1v1", Rounds = rounds,
		SideA = { Name = nameA, Blades = { result.A } },
		SideB = { Name = nameB, Blades = { result.B } },
	}
end

-- Normalise a 2v2 result (stamina already per-blade lists).
local function normalizeTeam(result: any, nameA: string, nameB: string): any
	return {
		Seed = result.Seed, Winner = result.Winner, Mode = "2v2", Rounds = result.Rounds,
		SideA = { Name = nameA, Blades = result.A },
		SideB = { Name = nameB, Blades = result.B },
	}
end

local function loadoutOf(player: Player): any?
	local p = DataService.get(player)
	if not p then
		return nil
	end
	local eq = p.Equipped
	-- Validate ownership.
	local key = eq.BladeId .. "|" .. eq.Rarity
	if not p.Inventory[key] then
		-- fall back to any owned blade
		local k = next(p.Inventory)
		if not k then
			return nil
		end
		local entry = p.Inventory[k]
		eq = { BladeId = entry.BladeId, Rarity = entry.Rarity }
		p.Equipped = eq
	end
	return { BladeId = eq.BladeId, Rarity = eq.Rarity }
end

-- Build a bot loadout near a target power level.
local function makeBot(targetPower: number): any
	local ids = BeybladeData.spawnableIds()
	local best, bestDiff
	-- Try a handful of random blade+rarity combos, keep the closest power.
	for _ = 1, 24 do
		local bladeId = ids[rng:NextInteger(1, #ids)]
		local rarity = RarityData.Order[rng:NextInteger(1, #RarityData.Order)]
		local power = BeybladeData.power(bladeId, rarity)
		local diff = math.abs(power - targetPower)
		if not bestDiff or diff < bestDiff then
			best = { BladeId = bladeId, Rarity = rarity }
			bestDiff = diff
		end
	end
	return best
end

local function grantRewards(player: Player, won: boolean, oppTrophies: number, oppName: string, oppLoadout: any)
	local p = DataService.get(player)
	if not p then
		return
	end
	p.Stats.Battles += 1
	-- Trophies (competitive ladder).
	local delta = trophyDelta(p.Trophies, oppTrophies, won)
	p.Trophies = math.max(0, p.Trophies + delta)
	p.PeakTrophies = math.max(p.PeakTrophies, p.Trophies)

	if won then
		p.Stats.Wins += 1
		p.Stats.Streak += 1
		p.Stats.BestStreak = math.max(p.Stats.BestStreak, p.Stats.Streak)
		local streakBonus = math.min(p.Stats.Streak, Config.Rewards.WinStreakCap) * Config.Rewards.WinStreakBonusBolts
		EconomyService.add(player, "Bolts", Config.Rewards.BattleWinBolts + streakBonus, true)
		EconomyService.add(player, "Cores", Config.Rewards.BattleWinCores, true)
	else
		p.Stats.Losses += 1
		p.Stats.Streak = 0
		EconomyService.add(player, "Bolts", Config.Rewards.BattleLoseBolts, true)
	end

	-- Battle history (newest first, capped at 15).
	table.insert(p.History, 1, {
		When = os.time(),
		Won = won,
		Opp = oppName,
		MyBlade = p.Equipped.BladeId,
		OppBlade = oppLoadout and oppLoadout.BladeId or nil,
		Delta = delta,
	})
	while #p.History > 15 do
		table.remove(p.History)
	end

	DataService.push(player)

	-- Progression + quests.
	ProgressService.addXP(player, won and 60 or 25)
	QuestService.report(player, "battle", 1)
	if won then
		QuestService.report(player, "win", 1)
	end
end

local function sendResult(player: Player, result: any, youAre: number, opponentName: string, won: boolean)
	local rewards = won
		and { Bolts = Config.Rewards.BattleWinBolts, Cores = Config.Rewards.BattleWinCores, Won = true }
		or { Bolts = Config.Rewards.BattleLoseBolts, Cores = 0, Won = false }
	;(Net.get("BattleResult") :: RemoteEvent):FireClient(player, result, youAre, opponentName, rewards)
end

-- Resolve a match between two tickets (b may be a bot ticket with no player).
local function runMatch(a: Ticket, b: Ticket)
	local seed = rng:NextInteger(1, 2 ^ 31 - 1)
	local result = BattleResolver.resolve(a.loadout, b.loadout, seed)

	local aWon = result.Winner == 1
	local bWon = result.Winner == 2

	local aOppName = b.player and b.player.DisplayName or ("🤖 " .. BOT_NAMES[rng:NextInteger(1, #BOT_NAMES)])
	local bOppName = a.player and a.player.DisplayName or ("🤖 " .. BOT_NAMES[rng:NextInteger(1, #BOT_NAMES)])

	if a.player then
		inBattle[a.player] = false
		grantRewards(a.player, aWon, b.trophies, aOppName, b.loadout)
		sendResult(a.player, result, 1, aOppName, aWon)
	end
	if b.player then
		inBattle[b.player] = false
		grantRewards(b.player, bWon, a.trophies, bOppName, a.loadout)
		sendResult(b.player, result, 2, bOppName, bWon)
	end

	-- Register for spectators (SideA = a's name, SideB = b's name).
	registerLive(normalize1v1(result, bOppName, aOppName))
end

-- Called from the StartBattle RemoteFunction.
function BattleService.start(player: Player): any
	if inBattle[player] then
		return { ok = false, reason = "already_battling" }
	end
	local loadout = loadoutOf(player)
	if not loadout then
		return { ok = false, reason = "no_blade" }
	end

	inBattle[player] = true
	local power = BeybladeData.power(loadout.BladeId, loadout.Rarity)
	local prof = DataService.get(player)
	local ticket: Ticket = { player = player, loadout = loadout, power = power, trophies = prof and prof.Trophies or 0, since = os.clock() }

	-- Try to pair with a waiting human.
	for i, other in queue do
		if other.player and other.player ~= player and other.player.Parent then
			table.remove(queue, i)
			runMatch(ticket, other)
			return { ok = true, matched = "human" }
		end
	end

	-- No human available: queue, then fall back to a bot.
	table.insert(queue, ticket)
	task.delay(Config.Battle.QueueTimeout, function()
		-- Still waiting? Pair with a bot.
		local idx = table.find(queue, ticket)
		if idx then
			table.remove(queue, idx)
			if player.Parent and inBattle[player] then
				local bot: Ticket = { player = nil :: any, loadout = makeBot(power), power = power, trophies = ticket.trophies, since = os.clock() }
				runMatch(ticket, bot)
			end
		end
	end)
	return { ok = true, matched = "queued" }
end

-- ===== 2v2 team battles ===============================================
local queue2: { Ticket } = {}

local function teamName(team: { Ticket }): string
	local names = {}
	for _, t in team do
		table.insert(names, t.player and t.player.DisplayName or ("🤖 " .. BOT_NAMES[rng:NextInteger(1, #BOT_NAMES)]))
	end
	return table.concat(names, " & ")
end

local function avgTrophies(team: { Ticket }): number
	local sum = 0
	for _, t in team do
		sum += t.trophies
	end
	return math.floor(sum / math.max(1, #team))
end

local function sendTeam(player: Player, payload: any, youTeam: number, won: boolean)
	local rewards = won
		and { Bolts = Config.Rewards.BattleWinBolts, Cores = Config.Rewards.BattleWinCores, Won = true }
		or { Bolts = Config.Rewards.BattleLoseBolts, Cores = 0, Won = false }
	;(Net.get("TeamBattleResult") :: RemoteEvent):FireClient(player, payload, youTeam, rewards)
end

local function runTeamMatch(teamA: { Ticket }, teamB: { Ticket })
	local seed = rng:NextInteger(1, 2 ^ 31 - 1)
	local laA = { teamA[1].loadout, teamA[2].loadout }
	local laB = { teamB[1].loadout, teamB[2].loadout }
	local result = BattleResolver.resolveTeams(laA, laB, seed)
	local aWon = result.Winner == 1

	local nameA, nameB = teamName(teamA), teamName(teamB)
	local trA, trB = avgTrophies(teamA), avgTrophies(teamB)

	for _, t in teamA do
		if t.player then
			inBattle[t.player] = false
			grantRewards(t.player, aWon, trB, "Equipo " .. nameB, nil)
		end
	end
	for _, t in teamB do
		if t.player then
			inBattle[t.player] = false
			grantRewards(t.player, not aWon, trA, "Equipo " .. nameA, nil)
		end
	end

	local payload = normalizeTeam(result, nameA, nameB)
	registerLive(payload)

	for _, t in teamA do
		if t.player then
			sendTeam(t.player, payload, 1, aWon)
		end
	end
	for _, t in teamB do
		if t.player then
			sendTeam(t.player, payload, 2, not aWon)
		end
	end
end

-- Called from the StartTeamBattle RemoteFunction.
function BattleService.startTeam(player: Player): any
	if inBattle[player] then
		return { ok = false, reason = "already_battling" }
	end
	local loadout = loadoutOf(player)
	if not loadout then
		return { ok = false, reason = "no_blade" }
	end
	inBattle[player] = true
	local prof = DataService.get(player)
	local ticket: Ticket = {
		player = player, loadout = loadout, power = BeybladeData.power(loadout.BladeId, loadout.Rarity),
		trophies = prof and prof.Trophies or 0, since = os.clock(),
	}
	table.insert(queue2, ticket)

	-- Four humans ready? Split the first joiners across teams for balance.
	if #queue2 >= 4 then
		local g = { table.remove(queue2, 1), table.remove(queue2, 1), table.remove(queue2, 1), table.remove(queue2, 1) }
		runTeamMatch({ g[1], g[3] }, { g[2], g[4] })
		return { ok = true, matched = "human" }
	end

	-- Otherwise wait briefly, then fill the lobby with bots.
	task.delay(Config.Battle.QueueTimeout * 2, function()
		local idx = table.find(queue2, ticket)
		if not idx or not player.Parent or not inBattle[player] then
			return
		end
		table.remove(queue2, idx)
		local group = { ticket }
		while #group < 4 and #queue2 > 0 do
			table.insert(group, table.remove(queue2, 1))
		end
		while #group < 4 do
			local p = group[1].power
			table.insert(group, { player = nil :: any, loadout = makeBot(p), power = p, trophies = ticket.trophies, since = os.clock() })
		end
		runTeamMatch({ group[1], group[3] }, { group[2], group[4] })
	end)
	return { ok = true, matched = "queued" }
end

-- Called from the SpectateBattle RemoteFunction.
function BattleService.spectate(_player: Player): any
	local now = os.clock()
	local ids = {}
	for id, e in liveBattles do
		if e.expires > now then
			table.insert(ids, id)
		end
	end
	if #ids == 0 then
		return { ok = false, reason = "none" }
	end
	local pick = liveBattles[ids[rng:NextInteger(1, #ids)]]
	return { ok = true, payload = pick.payload }
end

function BattleService.cleanup(player: Player)
	inBattle[player] = nil
	for i = #queue, 1, -1 do
		if queue[i].player == player then
			table.remove(queue, i)
		end
	end
	for i = #queue2, 1, -1 do
		if queue2[i].player == player then
			table.remove(queue2, i)
		end
	end
end

return BattleService
