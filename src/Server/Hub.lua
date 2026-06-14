--!strict
-- Hub.lua
-- Procedurally builds the playable world: a central Beyblade stadium dish, a
-- collection garden where loot spawns, a spawn pad and neon set dressing. All
-- generated from primitives so the place is presentable with zero asset uploads.

local Workspace = game:GetService("Workspace")

local Hub = {}

local ARENA_CENTER = Vector3.new(0, 0, 0)
local GARDEN_CENTER = Vector3.new(0, 4, -120)

local function part(props: { [string]: any }, parent: Instance): BasePart
	local p = Instance.new(props.Class or "Part") :: BasePart
	props.Class = nil
	p.Anchored = true
	p.CanCollide = true
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function buildArena(parent: Instance)
	-- Outer ring base.
	part({
		Class = "Part", Name = "ArenaBase", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 110, 110), CFrame = CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Metal, Color = Color3.fromRGB(38, 42, 54),
	}, parent)

	-- Stadium dish (slightly raised lip via stacked thin cylinders).
	for i = 0, 5 do
		local r = 96 - i * 6
		part({
			Class = "Part", Name = "Dish" .. i, Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, r, r),
			CFrame = CFrame.new(ARENA_CENTER + Vector3.new(0, 2.2 + i * 0.18, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(48 + i * 4, 52 + i * 4, 70 + i * 6),
			CanCollide = i == 0,
		}, parent)
	end

	-- Glowing center seal.
	part({
		Class = "Part", Name = "CenterSeal", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 18, 18),
		CFrame = CFrame.new(ARENA_CENTER + Vector3.new(0, 3.4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon, Color = Color3.fromRGB(0, 224, 255), Transparency = 0.2,
	}, parent)

	-- Neon perimeter pillars.
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local pos = ARENA_CENTER + Vector3.new(math.cos(angle) * 60, 9, math.sin(angle) * 60)
		part({
			Class = "Part", Name = "Pillar" .. i, Size = Vector3.new(2, 18, 2),
			CFrame = CFrame.new(pos), Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 34, 44),
		}, parent)
		part({
			Class = "Part", Name = "PillarGlow" .. i, Size = Vector3.new(2.3, 2, 2.3),
			CFrame = CFrame.new(pos + Vector3.new(0, 8, 0)), Material = Enum.Material.Neon,
			Color = Color3.fromRGB(0, 224, 255), CanCollide = false,
		}, parent)
	end
end

local function buildGarden(parent: Instance)
	-- Floating collection island.
	part({
		Class = "Part", Name = "GardenBase", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 160, 160),
		CFrame = CFrame.new(GARDEN_CENTER - Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Grass, Color = Color3.fromRGB(58, 96, 64),
	}, parent)
	-- Bridge connecting arena to garden.
	part({
		Class = "Part", Name = "Bridge", Size = Vector3.new(12, 1, 64),
		CFrame = CFrame.new((ARENA_CENTER + GARDEN_CENTER) / 2 + Vector3.new(0, 2.6, 0)),
		Material = Enum.Material.Metal, Color = Color3.fromRGB(44, 48, 60),
	}, parent)
	-- Decorative arch.
	for _, side in { -1, 1 } do
		part({
			Class = "Part", Name = "GardenLight", Size = Vector3.new(1.5, 14, 1.5),
			CFrame = CFrame.new(GARDEN_CENTER + Vector3.new(side * 40, 7, 0)),
			Material = Enum.Material.Neon, Color = Color3.fromRGB(120, 220, 255), CanCollide = false,
		}, parent)
	end
end

function Hub.build(): Vector3
	-- Clear any baseplate/default terrain part.
	local existing = Workspace:FindFirstChild("Baseplate")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Model")
	world.Name = "World"
	world.Parent = Workspace

	buildArena(world)
	buildGarden(world)

	-- Spawn location near the arena.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(0, 4, 45)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(0, 224, 255)
	spawn.Transparency = 0.3
	spawn.Parent = world

	return GARDEN_CENTER
end

Hub.ArenaCenter = ARENA_CENTER
Hub.GardenCenter = GARDEN_CENTER

return Hub
