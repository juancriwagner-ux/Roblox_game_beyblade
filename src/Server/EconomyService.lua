--!strict
-- EconomyService.lua — authoritative currency mutations.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)

local EconomyService = {}

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

function EconomyService.balance(player: Player, currency: string): number
	local p = DataService.get(player)
	return p and p.Currencies[currency] or 0
end

function EconomyService.add(player: Player, currency: string, amount: number, silent: boolean?)
	local p = DataService.get(player)
	if not p or amount == 0 then
		return
	end
	assert(Config.Currencies[currency], "unknown currency " .. currency)
	p.Currencies[currency] = math.max(0, (p.Currencies[currency] or 0) + amount)
	DataService.push(player)
	if not silent and amount > 0 then
		local def = Config.Currencies[currency]
		notify(player, ("+%d %s"):format(amount, def.Name), "currency")
	end
end

function EconomyService.canAfford(player: Player, currency: string, amount: number): boolean
	return EconomyService.balance(player, currency) >= amount
end

-- Returns true if the spend succeeded.
function EconomyService.spend(player: Player, currency: string, amount: number): boolean
	local p = DataService.get(player)
	if not p then
		return false
	end
	if (p.Currencies[currency] or 0) < amount then
		return false
	end
	p.Currencies[currency] -= amount
	DataService.push(player)
	return true
end

return EconomyService
