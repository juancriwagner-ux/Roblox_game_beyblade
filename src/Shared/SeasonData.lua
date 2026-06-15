--!strict
-- SeasonData.lua — Battle Pass / season definitions. Rewards are deterministic
-- per tier so client and server render/grant exactly the same thing. A season
-- maps to a calendar month, so it rotates automatically.

local SeasonData = {}

SeasonData.MaxTier = 30
SeasonData.XpPerTier = 800
SeasonData.PremiumPriceCores = 150 -- can also be sold via Robux (see Monetization)

local MONTHS = {
	"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
	"Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
}

-- Current season id = year*100 + month (UTC). New month => new season.
function SeasonData.currentId(): number
	local t = os.date("!*t")
	return t.year * 100 + t.month
end

function SeasonData.name(id: number): string
	local year = math.floor(id / 100)
	local month = id % 100
	return ("Temporada %s %d"):format(MONTHS[month] or "?", year)
end

export type Reward = {
	Bolts: number?,
	Cores: number?,
	Skin: string?,
	Blade: { Id: string, Rarity: string }?,
}

export type TierReward = { Free: Reward, Premium: Reward }

-- Deterministic reward for a given tier (1..MaxTier).
function SeasonData.rewardFor(tier: number): TierReward
	local free: Reward = { Bolts = 150 + tier * 15 }
	if tier % 5 == 0 then
		free.Cores = 2
	end

	local premium: Reward = { Bolts = 300 + tier * 30, Cores = 2 + math.floor(tier / 4) }
	-- Milestone cosmetics on the premium track.
	if tier == 10 then
		premium.Skin = "voltage"
	elseif tier == 20 then
		premium.Skin = "obsidian"
	elseif tier == SeasonData.MaxTier then
		premium.Blade = { Id = "void_reaper", Rarity = "Legendary" }
	end
	return { Free = free, Premium = premium }
end

return SeasonData
