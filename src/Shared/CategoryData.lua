--!strict
-- CategoryData.lua
-- Battle archetypes and elemental themes. Category decides how a blade's
-- stat budget is distributed; element decides the visual palette + a minor
-- combat affinity used by the battle resolver.

local CategoryData = {}

-- Archetypes (classic Beyblade types). StatBias is added on top of a blade's
-- own stats, nudging each archetype toward its identity.
export type Category = {
	Id: string,
	Name: string,
	Icon: string,
	StatBias: { Attack: number, Defense: number, Stamina: number, Speed: number, Weight: number },
}

CategoryData.Categories = {
	Attack = {
		Id = "Attack", Name = "Ataque", Icon = "⚔️",
		StatBias = { Attack = 18, Defense = -6, Stamina = -4, Speed = 10, Weight = -2 },
	},
	Defense = {
		Id = "Defense", Name = "Defensa", Icon = "🛡️",
		StatBias = { Attack = -4, Defense = 20, Stamina = 4, Speed = -8, Weight = 12 },
	},
	Stamina = {
		Id = "Stamina", Name = "Resistencia", Icon = "♾️",
		StatBias = { Attack = -6, Defense = 2, Stamina = 22, Speed = -2, Weight = 2 },
	},
	Balance = {
		Id = "Balance", Name = "Balance", Icon = "⚖️",
		StatBias = { Attack = 6, Defense = 6, Stamina = 6, Speed = 4, Weight = 4 },
	},
} :: { [string]: Category }

-- Elements drive palette + a rock/paper/scissors style affinity ring.
export type Element = {
	Id: string,
	Name: string,
	Primary: Color3,
	Secondary: Color3,
	Material: Enum.Material,
	StrongVs: string, -- element this one has advantage against
	Particle: string, -- logical id used by the VFX layer
}

CategoryData.Elements = {
	Fire = { Id = "Fire", Name = "Fuego", Primary = Color3.fromRGB(255, 86, 24), Secondary = Color3.fromRGB(255, 196, 64), Material = Enum.Material.Neon, StrongVs = "Ice", Particle = "embers" },
	Ice = { Id = "Ice", Name = "Hielo", Primary = Color3.fromRGB(120, 224, 255), Secondary = Color3.fromRGB(228, 252, 255), Material = Enum.Material.Glass, StrongVs = "Wind", Particle = "frost" },
	Lightning = { Id = "Lightning", Name = "Rayo", Primary = Color3.fromRGB(255, 232, 32), Secondary = Color3.fromRGB(140, 96, 255), Material = Enum.Material.Neon, StrongVs = "Metal", Particle = "sparks" },
	Earth = { Id = "Earth", Name = "Tierra", Primary = Color3.fromRGB(150, 104, 56), Secondary = Color3.fromRGB(96, 168, 72), Material = Enum.Material.Slate, StrongVs = "Lightning", Particle = "dust" },
	Wind = { Id = "Wind", Name = "Viento", Primary = Color3.fromRGB(168, 255, 210), Secondary = Color3.fromRGB(236, 255, 248), Material = Enum.Material.SmoothPlastic, StrongVs = "Earth", Particle = "gust" },
	Metal = { Id = "Metal", Name = "Metal", Primary = Color3.fromRGB(196, 204, 214), Secondary = Color3.fromRGB(120, 128, 140), Material = Enum.Material.Metal, StrongVs = "Fire", Particle = "shards" },
	Shadow = { Id = "Shadow", Name = "Sombra", Primary = Color3.fromRGB(78, 32, 120), Secondary = Color3.fromRGB(20, 16, 32), Material = Enum.Material.Glass, StrongVs = "Light", Particle = "void" },
	Light = { Id = "Light", Name = "Luz", Primary = Color3.fromRGB(255, 244, 200), Secondary = Color3.fromRGB(255, 212, 96), Material = Enum.Material.Neon, StrongVs = "Shadow", Particle = "halo" },
} :: { [string]: Element }

-- Affinity multiplier applied to attacker effectiveness in the resolver.
function CategoryData.affinity(attacker: string, defender: string): number
	local a = CategoryData.Elements[attacker]
	if a and a.StrongVs == defender then
		return 1.12
	end
	local d = CategoryData.Elements[defender]
	if d and d.StrongVs == attacker then
		return 0.92
	end
	return 1.0
end

return CategoryData
