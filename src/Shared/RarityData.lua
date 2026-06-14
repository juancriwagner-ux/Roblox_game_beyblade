--!strict
-- RarityData.lua
-- Rarity tiers: drop weights, stat multipliers and presentation.

export type Rarity = {
	Id: string,
	Name: string,
	Order: number,
	Weight: number, -- base drop weight (higher = more common)
	StatMult: number, -- multiplies a blade's base stats
	Color: Color3,
	Glow: number, -- emissive intensity for VFX
}

local RarityData = {}

RarityData.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

RarityData.Tiers = {
	Common = {
		Id = "Common", Name = "Común", Order = 1, Weight = 1000, StatMult = 1.0,
		Color = Color3.fromRGB(176, 184, 196), Glow = 0.0,
	},
	Uncommon = {
		Id = "Uncommon", Name = "Poco común", Order = 2, Weight = 520, StatMult = 1.18,
		Color = Color3.fromRGB(86, 214, 112), Glow = 0.15,
	},
	Rare = {
		Id = "Rare", Name = "Raro", Order = 3, Weight = 240, StatMult = 1.4,
		Color = Color3.fromRGB(64, 156, 255), Glow = 0.35,
	},
	Epic = {
		Id = "Epic", Name = "Épico", Order = 4, Weight = 95, StatMult = 1.7,
		Color = Color3.fromRGB(178, 92, 255), Glow = 0.6,
	},
	Legendary = {
		Id = "Legendary", Name = "Legendario", Order = 5, Weight = 28, StatMult = 2.15,
		Color = Color3.fromRGB(255, 176, 32), Glow = 1.0,
	},
	Mythic = {
		Id = "Mythic", Name = "Mítico", Order = 6, Weight = 4, StatMult = 2.8,
		Color = Color3.fromRGB(255, 64, 132), Glow = 1.6,
	},
} :: { [string]: Rarity }

-- Returns a rarity id using weighted random, with `bias` shifting odds toward
-- rarer tiers (each bias point roughly halves the weight of the lowest tiers).
function RarityData.roll(bias: number?, rng: Random?): string
	local b = bias or 0
	local r = rng or Random.new()
	local total = 0
	local weights: { [string]: number } = {}
	for i, id in RarityData.Order do
		local tier = RarityData.Tiers[id]
		-- Bias raises the relative weight of higher-order tiers.
		local w = tier.Weight * (1 + b * (i - 1) * 0.6)
		weights[id] = w
		total += w
	end
	local pick = r:NextNumber(0, total)
	local acc = 0
	for _, id in RarityData.Order do
		acc += weights[id]
		if pick <= acc then
			return id
		end
	end
	return "Common"
end

return RarityData
