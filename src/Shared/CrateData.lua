--!strict
-- CrateData.lua — gacha crates. Each crate rolls a random blade with a rarity
-- bias (and optional guaranteed floor). Shared so the shop can render crates.

export type Crate = {
	Id: string,
	Name: string,
	Desc: string,
	Currency: string, -- "Bolts" | "Cores"
	Price: number,
	Bias: number, -- feeds RarityData.roll (higher = rarer pulls)
	MinRarity: string?, -- guaranteed floor (rarity id)
	Color: Color3,
	Glow: number,
}

local CrateData = {}

CrateData.Order = { "starter", "premium", "elite" }

CrateData.Crates = {
	starter = {
		Id = "starter", Name = "Cofre Inicial", Desc = "Un Beyblade aleatorio. Ideal para empezar.",
		Currency = "Bolts", Price = 600, Bias = 0, MinRarity = nil,
		Color = Color3.fromRGB(120, 200, 255), Glow = 0.4,
	},
	premium = {
		Id = "premium", Name = "Cofre Premium", Desc = "Mejores probabilidades. Garantiza Raro o superior.",
		Currency = "Bolts", Price = 3000, Bias = 1.6, MinRarity = "Rare",
		Color = Color3.fromRGB(178, 92, 255), Glow = 0.8,
	},
	elite = {
		Id = "elite", Name = "Cofre Élite", Desc = "Tiradas de alta rareza. Garantiza Épico o superior.",
		Currency = "Cores", Price = 35, Bias = 3.2, MinRarity = "Epic",
		Color = Color3.fromRGB(255, 176, 32), Glow = 1.4,
	},
} :: { [string]: Crate }

function CrateData.get(id: string): Crate?
	return CrateData.Crates[id]
end

-- Exact drop odds for a crate, mirroring GachaService's roll: RarityData
-- weights biased by crate.Bias, then tiers below MinRarity folded into the
-- floor tier. Returns { { Rarity = id, Percent = number } } ordered low→high.
-- Shown in the shop UI (required disclosure for paid random items).
function CrateData.odds(crateId: string): { { Rarity: string, Percent: number } }
	local RarityData = require(script.Parent.RarityData)
	local crate = CrateData.Crates[crateId]
	if not crate then
		return {}
	end
	-- Raw biased weights (same formula as RarityData.roll).
	local weights: { [string]: number } = {}
	local total = 0
	for i, id in RarityData.Order do
		local w = RarityData.Tiers[id].Weight * (1 + crate.Bias * (i - 1) * 0.6)
		weights[id] = w
		total += w
	end
	-- Fold everything below the guaranteed floor into the floor tier.
	local floorIndex = crate.MinRarity and table.find(RarityData.Order, crate.MinRarity) or 1
	local probs: { [string]: number } = {}
	for i, id in RarityData.Order do
		local p = weights[id] / total
		local target = RarityData.Order[math.max(i, floorIndex)]
		probs[target] = (probs[target] or 0) + p
	end
	local out = {}
	for _, id in RarityData.Order do
		if probs[id] and probs[id] > 0 then
			table.insert(out, { Rarity = id, Percent = probs[id] * 100 })
		end
	end
	return out
end

return CrateData
