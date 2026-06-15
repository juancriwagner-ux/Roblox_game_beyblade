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
	local ids = BeybladeData.allIds()
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

local function grantRewards(player: Player, won: boolean, oppTrophies: number)
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

	if a.player then
		inBattle[a.player] = false
		grantRewards(a.player, aWon, b.trophies)
		local oppName = b.player and b.player.DisplayName or ("🤖 " .. BOT_NAMES[rng:NextInteger(1, #BOT_NAMES)])
		sendResult(a.player, result, 1, oppName, aWon)
	end
	if b.player then
		inBattle[b.player] = false
		grantRewards(b.player, bWon, a.trophies)
		local oppName = a.player and a.player.DisplayName or ("🤖 " .. BOT_NAMES[rng:NextInteger(1, #BOT_NAMES)])
		sendResult(b.player, result, 2, oppName, bWon)
	end
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

function BattleService.cleanup(player: Player)
	inBattle[player] = nil
	for i = #queue, 1, -1 do
		if queue[i].player == player then
			table.remove(queue, i)
		end
	end
end

return BattleService
