--!strict
-- SkinData.lua
-- Developed cosmetic skins. Skins are purely visual overrides applied on top
-- of any blade model (palette, material, emissive, trail + aura particle).
-- They are bought with the premium "Cores" currency and never affect stats.

export type Skin = {
	Id: string,
	Name: string,
	Price: number, -- in Cores (premium currency)
	Rarity: string, -- presentation tier
	Primary: Color3,
	Secondary: Color3,
	Material: Enum.Material,
	Emissive: number, -- 0..2 glow strength
	Trail: Color3,
	Aura: string, -- VFX id: "none" | "embers" | "frost" | "sparks" | "void" | "halo" | "rainbow"
	Limited: boolean?, -- exclusive / rotating
}

local SkinData = {}

SkinData.Catalog = {
	default = {
		Id = "default", Name = "Estándar", Price = 0, Rarity = "Common",
		Primary = Color3.fromRGB(210, 214, 222), Secondary = Color3.fromRGB(90, 96, 110),
		Material = Enum.Material.Metal, Emissive = 0, Trail = Color3.fromRGB(255, 255, 255), Aura = "none",
	},
	molten = {
		Id = "molten", Name = "Núcleo Fundido", Price = 40, Rarity = "Rare",
		Primary = Color3.fromRGB(255, 96, 24), Secondary = Color3.fromRGB(60, 12, 8),
		Material = Enum.Material.Neon, Emissive = 1.2, Trail = Color3.fromRGB(255, 150, 40), Aura = "embers",
	},
	glacier = {
		Id = "glacier", Name = "Glaciar", Price = 40, Rarity = "Rare",
		Primary = Color3.fromRGB(150, 230, 255), Secondary = Color3.fromRGB(40, 90, 140),
		Material = Enum.Material.Glass, Emissive = 0.6, Trail = Color3.fromRGB(190, 240, 255), Aura = "frost",
	},
	voltage = {
		Id = "voltage", Name = "Voltaje", Price = 65, Rarity = "Epic",
		Primary = Color3.fromRGB(255, 232, 32), Secondary = Color3.fromRGB(80, 40, 160),
		Material = Enum.Material.Neon, Emissive = 1.5, Trail = Color3.fromRGB(180, 140, 255), Aura = "sparks",
	},
	obsidian = {
		Id = "obsidian", Name = "Obsidiana Abisal", Price = 90, Rarity = "Epic",
		Primary = Color3.fromRGB(40, 30, 60), Secondary = Color3.fromRGB(150, 40, 220),
		Material = Enum.Material.Glass, Emissive = 1.0, Trail = Color3.fromRGB(150, 40, 220), Aura = "void",
	},
	celestial = {
		Id = "celestial", Name = "Aureola Celestial", Price = 150, Rarity = "Legendary",
		Primary = Color3.fromRGB(255, 244, 200), Secondary = Color3.fromRGB(255, 196, 64),
		Material = Enum.Material.Neon, Emissive = 1.8, Trail = Color3.fromRGB(255, 224, 150), Aura = "halo",
	},
	prism = {
		Id = "prism", Name = "Prisma Mítico", Price = 300, Rarity = "Mythic", Limited = true,
		Primary = Color3.fromRGB(255, 120, 200), Secondary = Color3.fromRGB(120, 220, 255),
		Material = Enum.Material.Neon, Emissive = 2.0, Trail = Color3.fromRGB(255, 180, 255), Aura = "rainbow",
	},
	venom = {
		Id = "venom", Name = "Veneno", Price = 70, Rarity = "Epic",
		Primary = Color3.fromRGB(120, 255, 64), Secondary = Color3.fromRGB(24, 56, 16),
		Material = Enum.Material.Neon, Emissive = 1.3, Trail = Color3.fromRGB(150, 255, 80), Aura = "venom",
	},
} :: { [string]: Skin }

function SkinData.get(id: string): Skin?
	return SkinData.Catalog[id]
end

function SkinData.allIds(): { string }
	local ids = {}
	for id in SkinData.Catalog do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

return SkinData
