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
local Hub = require(script.Hub)

-- ===== Boot =====
Net.init()
local gardenCenter = Hub.build()
SpawnService.setCenter(gardenCenter)

DataService.init()
SpawnService.init()
MonetizationService.init()

-- ===== Remote handlers =====
local function onInvoke(name: string, handler: (Player, ...any) -> any)
	(Net.get(name) :: RemoteFunction).OnServerInvoke = function(player, ...)
		if not DataService.isLoaded(player) then
			return { ok = false, reason = "loading" }
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

-- ===== Player lifecycle =====
local function onPlayerAdded(player: Player)
	DataService.load(player)
	BeybladeService.grantStarters(player)
	DataService.push(player)
	-- Welcome message.
	;(Net.get("Notify") :: RemoteEvent):FireClient(player, "¡Bienvenido a Beyblade Arena!", "success")
end

local function onPlayerRemoving(player: Player)
	BattleService.cleanup(player)
	DataService.release(player)
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("[BeybladeArena] Server ready.")
