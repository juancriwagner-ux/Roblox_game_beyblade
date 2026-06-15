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

return CrateData
