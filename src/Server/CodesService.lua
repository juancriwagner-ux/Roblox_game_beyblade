--!strict
-- CodesService.lua — redeemable promo codes (launch hype, YouTubers, events).
-- Codes live server-side only so clients can't datamine them. Add/disable codes
-- here; each player can redeem each code once.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local BeybladeService = require(script.Parent.BeybladeService)

local CodesService = {}

type Reward = { Bolts: number?, Cores: number?, Blade: { Id: string, Rarity: string }? }

-- code (UPPERCASE) -> reward + optional expiry/active flag.
local CODES: { [string]: { Active: boolean, Reward: Reward } } = {
	LAUNCH = { Active = true, Reward = { Bolts = 1000, Cores = 25 } },
	BEYBLADE = { Active = true, Reward = { Bolts = 500, Cores = 10 } },
	SPINSTORM = { Active = true, Reward = { Cores = 15 } },
	FREEMYTHIC = { Active = true, Reward = { Blade = { Id = "celestial_prime", Rarity = "Legendary" } } },
}

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

function CodesService.redeem(player: Player, raw: string): any
	local p = DataService.get(player)
	if not p or typeof(raw) ~= "string" then
		return { ok = false, reason = "invalid" }
	end
	local code = string.upper((raw:gsub("%s", "")))
	local entry = CODES[code]
	if not entry or not entry.Active then
		return { ok = false, reason = "invalid" }
	end
	if p.Codes[code] then
		return { ok = false, reason = "used" }
	end
	p.Codes[code] = true
	local r = entry.Reward
	if r.Bolts then
		EconomyService.add(player, "Bolts", r.Bolts, true)
	end
	if r.Cores then
		EconomyService.add(player, "Cores", r.Cores, true)
	end
	if r.Blade then
		BeybladeService.grant(player, r.Blade.Id, r.Blade.Rarity)
	end
	DataService.push(player)
	notify(player, ("🎟️ Código '%s' canjeado!"):format(code), "success")
	return { ok = true, reward = r }
end

return CodesService
