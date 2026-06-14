--!strict
-- BeybladeData.lua
-- The master catalog of collectible beyblades. Each entry defines base stats
-- (before rarity multiplier), its archetype/element, a unique ability and a
-- procedural model recipe consumed by ModelBuilder.

export type Stats = {
	Attack: number,
	Defense: number,
	Stamina: number,
	Speed: number,
	Weight: number,
}

export type ModelRecipe = {
	Profile: string, -- silhouette: "spike" | "disc" | "blade" | "orb" | "star"
	Tips: number, -- number of contact points / blades on the ring
	Height: number, -- studs
	Radius: number, -- studs
	Metalness: number, -- 0..1 cosmetic
}

export type Ability = {
	Id: string,
	Name: string,
	Desc: string,
	-- Resolver hook id; BattleResolver interprets these.
	Effect: string,
	Power: number,
}

export type Blade = {
	Id: string,
	Name: string,
	Category: string,
	Element: string,
	Rarity: string, -- the "intended" rarity floor for catalog display
	Stats: Stats,
	Ability: Ability,
	Model: ModelRecipe,
}

local BeybladeData = {}

local function blade(t: Blade): Blade
	return t
end

BeybladeData.Catalog = {
	-- ===== ATTACK =====
	ember_striker = blade({
		Id = "ember_striker", Name = "Ember Striker", Category = "Attack", Element = "Fire", Rarity = "Common",
		Stats = { Attack = 62, Defense = 38, Stamina = 40, Speed = 58, Weight = 42 },
		Ability = { Id = "blaze_rush", Name = "Furia Ígnea", Desc = "+12% de ataque en la primera ronda.", Effect = "first_round_attack", Power = 0.12 },
		Model = { Profile = "blade", Tips = 3, Height = 1.1, Radius = 1.5, Metalness = 0.4 },
	}),
	storm_fang = blade({
		Id = "storm_fang", Name = "Storm Fang", Category = "Attack", Element = "Lightning", Rarity = "Rare",
		Stats = { Attack = 78, Defense = 36, Stamina = 42, Speed = 74, Weight = 44 },
		Ability = { Id = "overcharge", Name = "Sobrecarga", Desc = "5% de probabilidad de golpe crítico que gana la ronda.", Effect = "crit_chance", Power = 0.05 },
		Model = { Profile = "spike", Tips = 4, Height = 1.0, Radius = 1.45, Metalness = 0.6 },
	}),
	void_reaper = blade({
		Id = "void_reaper", Name = "Void Reaper", Category = "Attack", Element = "Shadow", Rarity = "Legendary",
		Stats = { Attack = 96, Defense = 48, Stamina = 52, Speed = 82, Weight = 50 },
		Ability = { Id = "drain", Name = "Drenaje Abisal", Desc = "Roba 8% de la resistencia rival al ganar una ronda.", Effect = "stamina_drain", Power = 0.08 },
		Model = { Profile = "star", Tips = 5, Height = 1.05, Radius = 1.5, Metalness = 0.5 },
	}),
	solar_lance = blade({
		Id = "solar_lance", Name = "Solar Lance", Category = "Attack", Element = "Light", Rarity = "Epic",
		Stats = { Attack = 88, Defense = 44, Stamina = 50, Speed = 78, Weight = 46 },
		Ability = { Id = "pierce", Name = "Lanza Solar", Desc = "Ignora 15% de la defensa rival.", Effect = "defense_pierce", Power = 0.15 },
		Model = { Profile = "spike", Tips = 6, Height = 1.0, Radius = 1.4, Metalness = 0.55 },
	}),

	-- ===== DEFENSE =====
	tide_guardian = blade({
		Id = "tide_guardian", Name = "Tide Guardian", Category = "Defense", Element = "Ice", Rarity = "Common",
		Stats = { Attack = 36, Defense = 66, Stamina = 50, Speed = 34, Weight = 64 },
		Ability = { Id = "bulwark", Name = "Bastión", Desc = "+10% de defensa mientras la resistencia esté por encima del 50%.", Effect = "high_stamina_defense", Power = 0.10 },
		Model = { Profile = "disc", Tips = 8, Height = 0.9, Radius = 1.7, Metalness = 0.3 },
	}),
	iron_aegis = blade({
		Id = "iron_aegis", Name = "Iron Aegis", Category = "Defense", Element = "Metal", Rarity = "Rare",
		Stats = { Attack = 40, Defense = 84, Stamina = 54, Speed = 30, Weight = 80 },
		Ability = { Id = "counter", Name = "Contragolpe", Desc = "20% de devolver el daño de un golpe perdido.", Effect = "counter_chance", Power = 0.20 },
		Model = { Profile = "disc", Tips = 10, Height = 0.85, Radius = 1.8, Metalness = 0.8 },
	}),
	mountain_breaker = blade({
		Id = "mountain_breaker", Name = "Mountain Breaker", Category = "Defense", Element = "Earth", Rarity = "Epic",
		Stats = { Attack = 50, Defense = 92, Stamina = 64, Speed = 26, Weight = 92 },
		Ability = { Id = "anchor", Name = "Ancla", Desc = "Inmune a empujes; +6% defensa por ronda sobrevivida.", Effect = "ramp_defense", Power = 0.06 },
		Model = { Profile = "orb", Tips = 12, Height = 0.95, Radius = 1.85, Metalness = 0.7 },
	}),

	-- ===== STAMINA =====
	aurora_spin = blade({
		Id = "aurora_spin", Name = "Aurora Spin", Category = "Stamina", Element = "Ice", Rarity = "Uncommon",
		Stats = { Attack = 34, Defense = 48, Stamina = 78, Speed = 44, Weight = 50 },
		Ability = { Id = "endure", Name = "Perseverancia", Desc = "Pierde 30% menos resistencia por ronda.", Effect = "stamina_save", Power = 0.30 },
		Model = { Profile = "disc", Tips = 6, Height = 1.0, Radius = 1.6, Metalness = 0.35 },
	}),
	zephyr_dancer = blade({
		Id = "zephyr_dancer", Name = "Zephyr Dancer", Category = "Stamina", Element = "Wind", Rarity = "Rare",
		Stats = { Attack = 38, Defense = 44, Stamina = 88, Speed = 60, Weight = 38 },
		Ability = { Id = "evade", Name = "Evasión", Desc = "12% de esquivar por completo un golpe rival.", Effect = "dodge_chance", Power = 0.12 },
		Model = { Profile = "star", Tips = 4, Height = 1.1, Radius = 1.45, Metalness = 0.3 },
	}),
	eternal_halo = blade({
		Id = "eternal_halo", Name = "Eternal Halo", Category = "Stamina", Element = "Light", Rarity = "Legendary",
		Stats = { Attack = 48, Defense = 60, Stamina = 102, Speed = 56, Weight = 52 },
		Ability = { Id = "second_wind", Name = "Segundo Aliento", Desc = "Una vez por batalla, recupera 25% de resistencia al caer bajo 20%.", Effect = "revive_stamina", Power = 0.25 },
		Model = { Profile = "disc", Tips = 9, Height = 1.05, Radius = 1.7, Metalness = 0.45 },
	}),

	-- ===== BALANCE =====
	jade_comet = blade({
		Id = "jade_comet", Name = "Jade Comet", Category = "Balance", Element = "Wind", Rarity = "Uncommon",
		Stats = { Attack = 56, Defense = 56, Stamina = 58, Speed = 56, Weight = 54 },
		Ability = { Id = "adapt", Name = "Adaptación", Desc = "Copia 5% del mejor stat del rival.", Effect = "adapt", Power = 0.05 },
		Model = { Profile = "blade", Tips = 5, Height = 1.0, Radius = 1.55, Metalness = 0.4 },
	}),
	magma_core = blade({
		Id = "magma_core", Name = "Magma Core", Category = "Balance", Element = "Fire", Rarity = "Epic",
		Stats = { Attack = 72, Defense = 70, Stamina = 70, Speed = 64, Weight = 66 },
		Ability = { Id = "ignite", Name = "Combustión", Desc = "Cada ronda ganada aumenta el ataque 4%.", Effect = "ramp_attack", Power = 0.04 },
		Model = { Profile = "star", Tips = 6, Height = 1.05, Radius = 1.6, Metalness = 0.5 },
	}),
	celestial_prime = blade({
		Id = "celestial_prime", Name = "Celestial Prime", Category = "Balance", Element = "Lightning", Rarity = "Mythic",
		Stats = { Attack = 96, Defense = 92, Stamina = 96, Speed = 90, Weight = 78 },
		Ability = { Id = "ascend", Name = "Ascensión", Desc = "+8% a todos los stats por debajo del 40% de resistencia.", Effect = "desperation", Power = 0.08 },
		Model = { Profile = "star", Tips = 8, Height = 1.15, Radius = 1.7, Metalness = 0.65 },
	}),
} :: { [string]: Blade }

-- A flat list of catalog ids for iteration / random selection.
function BeybladeData.allIds(): { string }
	local ids = {}
	for id in BeybladeData.Catalog do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

function BeybladeData.get(id: string): Blade?
	return BeybladeData.Catalog[id]
end

-- Effective stats for an owned blade once rarity + category bias are applied.
function BeybladeData.effectiveStats(bladeId: string, rarity: string): Stats?
	local def = BeybladeData.Catalog[bladeId]
	if not def then
		return nil
	end
	local RarityData = require(script.Parent.RarityData)
	local CategoryData = require(script.Parent.CategoryData)
	local mult = (RarityData.Tiers[rarity] or RarityData.Tiers.Common).StatMult
	local bias = CategoryData.Categories[def.Category].StatBias
	return {
		Attack = math.floor((def.Stats.Attack + bias.Attack) * mult),
		Defense = math.floor((def.Stats.Defense + bias.Defense) * mult),
		Stamina = math.floor((def.Stats.Stamina + bias.Stamina) * mult),
		Speed = math.floor((def.Stats.Speed + bias.Speed) * mult),
		Weight = math.floor((def.Stats.Weight + bias.Weight) * mult),
	}
end

-- A blade's overall power rating, used for matchmaking + collection sorting.
function BeybladeData.power(bladeId: string, rarity: string): number
	local s = BeybladeData.effectiveStats(bladeId, rarity)
	if not s then
		return 0
	end
	return math.floor(s.Attack * 1.1 + s.Defense + s.Stamina + s.Speed * 0.9 + s.Weight * 0.4)
end

return BeybladeData
