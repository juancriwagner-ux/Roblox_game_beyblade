--!strict
-- BeybladeService.lua — inventory grants, equip and prestige (duplicate fusion).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local BeybladeService = {}

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

local function invKey(bladeId: string, rarity: string): string
	return bladeId .. "|" .. rarity
end

-- Give a blade of a specific rarity to a player.
function BeybladeService.grant(player: Player, bladeId: string, rarity: string, count: number?)
	local p = DataService.get(player)
	if not p or not BeybladeData.get(bladeId) then
		return
	end
	local key = invKey(bladeId, rarity)
	local entry = p.Inventory[key]
	if entry then
		entry.Count += (count or 1)
	else
		p.Inventory[key] = { BladeId = bladeId, Rarity = rarity, Count = count or 1 }
	end
	p.Stats.Collected += (count or 1)
	DataService.push(player)
end

-- Ensure new players actually own their starter blades.
function BeybladeService.grantStarters(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	if next(p.Inventory) == nil then
		for _, id in Config.StartingInventory do
			BeybladeService.grant(player, id, "Common")
		end
		-- Equip the first starter.
		p.Equipped = { BladeId = Config.StartingInventory[1], Rarity = "Common" }
		DataService.push(player)
	end
end

function BeybladeService.owns(player: Player, bladeId: string, rarity: string): boolean
	local p = DataService.get(player)
	if not p then
		return false
	end
	local entry = p.Inventory[invKey(bladeId, rarity)]
	return entry ~= nil and entry.Count > 0
end

function BeybladeService.equip(player: Player, bladeId: string, rarity: string): boolean
	local p = DataService.get(player)
	if not p or not BeybladeService.owns(player, bladeId, rarity) then
		return false
	end
	p.Equipped = { BladeId = bladeId, Rarity = rarity }
	DataService.push(player)
	return true
end

function BeybladeService.equipSkin(player: Player, bladeId: string, skinId: string): boolean
	local p = DataService.get(player)
	if not p then
		return false
	end
	if skinId ~= "default" and not p.Skins[skinId] then
		return false
	end
	p.SkinByBlade[bladeId] = skinId
	DataService.push(player)
	return true
end

-- Prestige: fuse duplicates of a blade to upgrade it one rarity tier.
-- Cost: 3 duplicates of the same blade at the same rarity.
local PRESTIGE_COST = 3

function BeybladeService.prestige(player: Player, bladeId: string, rarity: string): (boolean, string?)
	local p = DataService.get(player)
	if not p then
		return false, "no_profile"
	end
	local entry = p.Inventory[invKey(bladeId, rarity)]
	if not entry or entry.Count < PRESTIGE_COST then
		return false, "need_duplicates"
	end
	-- Find next rarity.
	local nextId
	for i, id in RarityData.Order do
		if id == rarity then
			nextId = RarityData.Order[i + 1]
			break
		end
	end
	if not nextId then
		return false, "max_rarity"
	end
	entry.Count -= PRESTIGE_COST
	if entry.Count <= 0 then
		p.Inventory[invKey(bladeId, rarity)] = nil
	end
	BeybladeService.grant(player, bladeId, nextId)
	notify(player, ("¡%s ascendió a %s!"):format(BeybladeData.get(bladeId).Name, RarityData.Tiers[nextId].Name), "success")
	return true
end

return BeybladeService
