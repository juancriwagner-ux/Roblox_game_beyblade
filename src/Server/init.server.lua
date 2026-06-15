--!strict
-- Server bootstrap for Beyblade Arena.
-- Wires every service, builds the world, sets up remotes and the player
-- lifecycle. This is the single entry point that runs on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)

local DataService = require(script.DataService)
local EconomyService = require(script.EconomyService)
local BeybladeService = require(script.BeybladeService)
local SpawnService = require(script.SpawnService)
local BattleService = require(script.BattleService)
local ShopService = require(script.ShopService)
local RewardService = require(script.RewardService)
local MonetizationService = require(script.MonetizationService)
local ProgressService = require(script.ProgressService)
local QuestService = require(script.QuestService)
local CodesService = require(script.CodesService)
local LeaderboardService = require(script.LeaderboardService)
local GachaService = require(script.GachaService)
local Hub = require(script.Hub)

-- ===== Boot =====
Net.init()
local gardenCenter = Hub.build()
SpawnService.setCenter(gardenCenter)

DataService.init()
ProgressService.init()
SpawnService.init()
MonetizationService.init()
LeaderboardService.init()

-- ===== Remote handlers =====
-- Per-player, per-remote rate limiting (basic anti-exploit / spam guard).
local lastCall: { [Player]: { [string]: number } } = {}
local MIN_INTERVAL: { [string]: number } = {
	StartBattle = 0.5,
	BuySkin = 0.4,
	RedeemCode = 1.0,
	ClaimQuest = 0.3,
	PrestigeBlade = 0.3,
	ClaimDaily = 0.5,
	default = 0.15,
}

local function rateLimited(player: Player, name: string): boolean
	local now = os.clock()
	local bucket = lastCall[player]
	if not bucket then
		bucket = {}
		lastCall[player] = bucket
	end
	local minGap = MIN_INTERVAL[name] or MIN_INTERVAL.default
	if bucket[name] and now - bucket[name] < minGap then
		return true
	end
	bucket[name] = now
	return false
end

local function onInvoke(name: string, handler: (Player, ...any) -> any)
	(Net.get(name) :: RemoteFunction).OnServerInvoke = function(player, ...)
		if not DataService.isLoaded(player) then
			return { ok = false, reason = "loading" }
		end
		if rateLimited(player, name) then
			return { ok = false, reason = "rate_limited" }
		end
		return handler(player, ...)
	end
end

onInvoke("RequestProfile", function(player)
	return DataService.snapshot(player)
end)

onInvoke("StartBattle", function(player, bladeId, rarity)
	-- Optional: equip the requested loadout before battling.
	if typeof(bladeId) == "string" and typeof(rarity) == "string" then
		BeybladeService.equip(player, bladeId, rarity)
	end
	return BattleService.start(player)
end)

onInvoke("BuySkin", function(player, skinId)
	if typeof(skinId) ~= "string" then
		return { ok = false }
	end
	return ShopService.buySkin(player, skinId)
end)

onInvoke("EquipBlade", function(player, bladeId, rarity)
	if typeof(bladeId) ~= "string" or typeof(rarity) ~= "string" then
		return { ok = false }
	end
	return { ok = BeybladeService.equip(player, bladeId, rarity) }
end)

onInvoke("EquipSkin", function(player, bladeId, skinId)
	if typeof(bladeId) ~= "string" or typeof(skinId) ~= "string" then
		return { ok = false }
	end
	return { ok = BeybladeService.equipSkin(player, bladeId, skinId) }
end)

onInvoke("ClaimDaily", function(player)
	return RewardService.claim(player)
end)

onInvoke("PrestigeBlade", function(player, bladeId, rarity)
	if typeof(bladeId) ~= "string" or typeof(rarity) ~= "string" then
		return { ok = false }
	end
	local ok, reason = BeybladeService.prestige(player, bladeId, rarity)
	return { ok = ok, reason = reason }
end)

onInvoke("GetLeaderboard", function(_player, board)
	if board ~= "Trophies" and board ~= "Wins" then
		board = "Trophies"
	end
	return LeaderboardService.getTop(board)
end)

onInvoke("RedeemCode", function(player, code)
	return CodesService.redeem(player, code)
end)

onInvoke("ClaimQuest", function(player, questId)
	if typeof(questId) ~= "string" then
		return { ok = false }
	end
	return QuestService.claim(player, questId)
end)

onInvoke("OpenCrate", function(player, crateId)
	if typeof(crateId) ~= "string" then
		return { ok = false }
	end
	return GachaService.open(player, crateId)
end)

onInvoke("CompleteTutorial", function(player)
	local p = DataService.get(player)
	if not p then
		return { ok = false }
	end
	if p.TutorialDone then
		return { ok = false, reason = "done" }
	end
	p.TutorialDone = true
	-- Onboarding reward.
	EconomyService.add(player, "Bolts", 750, true)
	EconomyService.add(player, "Cores", 10, true)
	DataService.push(player)
	;(Net.get("Notify") :: RemoteEvent):FireClient(player, "🎁 Regalo de bienvenida: +750 Tuercas, +10 Núcleos", "success")
	return { ok = true, reward = { Bolts = 750, Cores = 10 } }
end)

onInvoke("SaveSettings", function(player, settings)
	local p = DataService.get(player)
	if not p or typeof(settings) ~= "table" then
		return { ok = false }
	end
	p.Settings.Music = settings.Music == true
	p.Settings.Sfx = settings.Sfx == true
	DataService.push(player)
	return { ok = true }
end)

-- ===== Player lifecycle =====
local function onPlayerAdded(player: Player)
	local profile = DataService.load(player)
	if not profile then
		-- Could not acquire the session lock (data is busy elsewhere).
		player:Kick("No pudimos cargar tus datos (sesión ocupada). Vuelve a entrar en unos segundos.")
		return
	end
	ProgressService.setupLeaderstats(player)
	BeybladeService.grantStarters(player)
	QuestService.ensureDaily(player)
	DataService.push(player)
	LeaderboardService.update(player)
	-- Welcome message.
	;(Net.get("Notify") :: RemoteEvent):FireClient(player, "¡Bienvenido a Beyblade Arena!", "success")
end

local function onPlayerRemoving(player: Player)
	BattleService.cleanup(player)
	LeaderboardService.update(player)
	DataService.release(player)
	lastCall[player] = nil
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("[BeybladeArena] Server ready.")
