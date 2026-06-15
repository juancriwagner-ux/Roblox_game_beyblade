--!strict
-- GachaService.lua — authoritative crate opening. Validates currency, rolls a
-- biased rarity (respecting any guaranteed floor), grants the blade and returns
-- the result so the client can play the reveal animation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local CrateData = require(Shared.CrateData)
local RarityData = require(Shared.RarityData)
local BeybladeData = require(Shared.BeybladeData)
local Net = require(Shared.Net)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local BeybladeService = require(script.Parent.BeybladeService)

local GachaService = {}

local rng = Random.new()

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

-- Index of a rarity id in the ordered tier list (1 = Common).
local function rarityOrder(id: string): number
	return table.find(RarityData.Order, id) or 1
end

function GachaService.open(player: Player, crateId: string): any
	local p = DataService.get(player)
	local crate = CrateData.get(crateId)
	if not p or not crate then
		return { ok = false, reason = "invalid" }
	end
	if not EconomyService.canAfford(player, crate.Currency, crate.Price) then
		notify(player, "Saldo insuficiente para este cofre", "error")
		return { ok = false, reason = "insufficient" }
	end
	if not EconomyService.spend(player, crate.Currency, crate.Price) then
		return { ok = false, reason = "insufficient" }
	end

	-- Roll rarity (biased), then enforce the guaranteed floor.
	local rarity = RarityData.roll(crate.Bias, rng)
	if crate.MinRarity and rarityOrder(rarity) < rarityOrder(crate.MinRarity) then
		rarity = crate.MinRarity
	end

	local ids = BeybladeData.spawnableIds()
	local bladeId = ids[rng:NextInteger(1, #ids)]
	BeybladeService.grant(player, bladeId, rarity)

	return { ok = true, bladeId = bladeId, rarity = rarity, crateId = crateId }
end

return GachaService
