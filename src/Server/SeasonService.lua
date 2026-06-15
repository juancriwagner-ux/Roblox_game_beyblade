--!strict
-- SeasonService.lua — Battle Pass progression, premium unlock, reward claiming
-- and automatic monthly season rotation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local SeasonData = require(Shared.SeasonData)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local BeybladeService = require(script.Parent.BeybladeService)

local SeasonService = {}

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

-- Reset the player's season state when the calendar season changes.
function SeasonService.ensure(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	local cur = SeasonData.currentId()
	if p.Season.Id ~= cur then
		p.Season.Id = cur
		p.Season.XP = 0
		p.Season.Tier = 0
		p.Season.Premium = false
		p.Season.ClaimedFree = {}
		p.Season.ClaimedPremium = {}
		DataService.push(player)
	end
end

-- Add season XP (fed automatically from every XP gain). Bumps tiers + notifies.
function SeasonService.addXP(player: Player, amount: number)
	local p = DataService.get(player)
	if not p or amount <= 0 then
		return
	end
	SeasonService.ensure(player)
	p.Season.XP += amount
	local newTier = math.min(SeasonData.MaxTier, math.floor(p.Season.XP / SeasonData.XpPerTier))
	if newTier > p.Season.Tier then
		p.Season.Tier = newTier
		notify(player, ("🎟️ ¡Pase: nivel %d alcanzado!"):format(newTier), "success")
	end
	DataService.push(player)
end

local function grantReward(player: Player, reward: any)
	if reward.Bolts then
		EconomyService.add(player, "Bolts", reward.Bolts, true)
	end
	if reward.Cores then
		EconomyService.add(player, "Cores", reward.Cores, true)
	end
	if reward.Skin then
		local pf = DataService.get(player)
		if pf then
			pf.Skins[reward.Skin] = true
		end
	end
	if reward.Blade then
		BeybladeService.grant(player, reward.Blade.Id, reward.Blade.Rarity)
	end
end

function SeasonService.claim(player: Player, tier: number, track: string): any
	local p = DataService.get(player)
	if not p or typeof(tier) ~= "number" then
		return { ok = false }
	end
	tier = math.floor(tier)
	if tier < 1 or tier > SeasonData.MaxTier then
		return { ok = false, reason = "invalid_tier" }
	end
	if tier > p.Season.Tier then
		return { ok = false, reason = "locked" }
	end
	local key = tostring(tier)
	local rewards = SeasonData.rewardFor(tier)

	if track == "premium" then
		if not p.Season.Premium then
			return { ok = false, reason = "no_premium" }
		end
		if p.Season.ClaimedPremium[key] then
			return { ok = false, reason = "claimed" }
		end
		p.Season.ClaimedPremium[key] = true
		grantReward(player, rewards.Premium)
		DataService.push(player)
		return { ok = true, reward = rewards.Premium }
	else
		if p.Season.ClaimedFree[key] then
			return { ok = false, reason = "claimed" }
		end
		p.Season.ClaimedFree[key] = true
		grantReward(player, rewards.Free)
		DataService.push(player)
		return { ok = true, reward = rewards.Free }
	end
end

-- Buy the premium pass with the premium currency (Cores). A Robux developer
-- product can be wired in MonetizationService for real-money purchases too.
function SeasonService.buyPremium(player: Player): any
	local p = DataService.get(player)
	if not p then
		return { ok = false }
	end
	SeasonService.ensure(player)
	if p.Season.Premium then
		return { ok = false, reason = "owned" }
	end
	if not EconomyService.spend(player, "Cores", SeasonData.PremiumPriceCores) then
		notify(player, "Núcleos insuficientes para el Pase Premium", "error")
		return { ok = false, reason = "insufficient" }
	end
	p.Season.Premium = true
	DataService.push(player)
	notify(player, "🌟 ¡Pase Premium activado! Reclama las recompensas premium.", "success")
	return { ok = true }
end

return SeasonService
