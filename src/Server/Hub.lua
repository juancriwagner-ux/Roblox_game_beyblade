--!strict
-- Hub.lua
-- Procedurally builds a large, presentable "Beyblade City" hub: a central
-- stadium, a neon plaza, two rings of skyscrapers, holographic billboards,
-- street lamps, giant beyblade monuments and a collection garden — plus
-- cinematic post-processing (atmosphere, bloom, sun rays). All from primitives,
-- zero asset uploads required.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelBuilder = require(ReplicatedStorage.Shared.ModelBuilder)
local Assets = require(ReplicatedStorage.Shared.Assets)

local Hub = {}

local ARENA_CENTER = Vector3.new(0, 0, 0)
local GARDEN_CENTER = Vector3.new(0, 4, -260)

local rng = Random.new(20260615)

-- Neon accent palette (cyberpunk city).
local ACCENTS = {
	Color3.fromRGB(0, 224, 255),
	Color3.fromRGB(178, 92, 255),
	Color3.fromRGB(255, 96, 160),
	Color3.fromRGB(255, 176, 32),
	Color3.fromRGB(86, 255, 180),
}

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

local function randomAccent(): Color3
	return ACCENTS[rng:NextInteger(1, #ACCENTS)]
end

-- ===== Lighting / post-processing =====================================
local function applyLighting()
	Lighting.Brightness = 2.2
	Lighting.ClockTime = 15.2
	Lighting.GeographicLatitude = 20
	Lighting.ExposureCompensation = 0.2
	Lighting.Ambient = Color3.fromRGB(34, 36, 50)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 76, 100)
	Lighting.FogEnd = 1400
	Lighting.FogColor = Color3.fromRGB(120, 130, 160)

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.36
	atmo.Offset = 0.2
	atmo.Haze = 2.4
	atmo.Glare = 0.4
	atmo.Color = Color3.fromRGB(199, 209, 230)
	atmo.Decay = Color3.fromRGB(106, 112, 150)
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.9
	bloom.Size = 24
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.12
	rays.Spread = 0.6
	rays.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.02
	cc.Contrast = 0.12
	cc.Saturation = 0.18
	cc.TintColor = Color3.fromRGB(255, 250, 245)
	cc.Parent = Lighting

	local sky = Instance.new("Sky")
	sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
	sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
	sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
	sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
	sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
	sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
	sky.StarCount = 3000
	sky.SunAngularSize = 14
	sky.Parent = Lighting
end

-- ===== Ground plaza ===================================================
local function buildPlaza(parent: Instance)
	-- Big dark slab.
	part({
		Class = "Part", Name = "Plaza", Size = Vector3.new(760, 4, 760),
		CFrame = CFrame.new(0, -2, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(26, 28, 38),
	}, parent)
	-- Glowing concentric ring around the arena.
	for i = 1, 3 do
		local r = 70 + i * 6
		part({
			Class = "Part", Name = "Ring" .. i, Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, r * 2, r * 2),
			CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Neon, Color = ACCENTS[i], Transparency = 0.2, CanCollide = false,
		}, parent)
	end
	-- Radial neon "streets".
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		part({
			Class = "Part", Name = "Street" .. i, Size = Vector3.new(6, 0.4, 300),
			CFrame = CFrame.new(math.cos(angle) * 190, 0.2, math.sin(angle) * 190) * CFrame.Angles(0, -angle, 0),
			Material = Enum.Material.Neon, Color = Color3.fromRGB(40, 60, 90), Transparency = 0.3, CanCollide = false,
		}, parent)
	end
end

-- ===== Central stadium ================================================
local function buildArena(parent: Instance)
	part({
		Class = "Part", Name = "ArenaBase", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 116, 116), CFrame = CFrame.new(ARENA_CENTER) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Metal, Color = Color3.fromRGB(38, 42, 54),
	}, parent)
	for i = 0, 6 do
		local r = 104 - i * 6
		part({
			Class = "Part", Name = "Dish" .. i, Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, r, r),
			CFrame = CFrame.new(ARENA_CENTER + Vector3.new(0, 2.2 + i * 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(46 + i * 4, 50 + i * 4, 68 + i * 6),
			CanCollide = i == 0,
		}, parent)
	end
	part({
		Class = "Part", Name = "CenterSeal", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 20, 20), CFrame = CFrame.new(ARENA_CENTER + Vector3.new(0, 3.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon, Color = Color3.fromRGB(0, 224, 255), Transparency = 0.15, CanCollide = false,
	}, parent)
	-- Stadium grandstand pillars with floodlights.
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local pos = ARENA_CENTER + Vector3.new(math.cos(angle) * 66, 11, math.sin(angle) * 66)
		part({ Class = "Part", Name = "Pillar", Size = Vector3.new(3, 22, 3), CFrame = CFrame.new(pos), Material = Enum.Material.Metal, Color = Color3.fromRGB(30, 34, 44) }, parent)
		local cap = part({ Class = "Part", Name = "Floodlight", Size = Vector3.new(4, 2, 4), CFrame = CFrame.new(pos + Vector3.new(0, 11, 0)), Material = Enum.Material.Neon, Color = ACCENTS[(i % #ACCENTS) + 1], CanCollide = false }, parent)
		if i % 2 == 0 then
			local light = Instance.new("PointLight")
			light.Color = cap.Color
			light.Range = 30
			light.Brightness = 2
			light.Shadows = false
			light.Parent = cap
		end
	end
end

-- ===== Skyscrapers ====================================================
local function buildBuilding(parent: Instance, cf: CFrame, w: number, d: number, h: number)
	local accent = randomAccent()
	-- Body.
	local body = part({
		Class = "Part", Name = "Tower", Size = Vector3.new(w, h, d), CFrame = cf * CFrame.new(0, h / 2, 0),
		Material = Enum.Material.Glass, Color = Color3.fromRGB(22 + rng:NextInteger(0, 16), 26 + rng:NextInteger(0, 16), 40 + rng:NextInteger(0, 20)),
		Reflectance = 0.08,
	}, parent)
	-- Premium facade texture (only if uploaded; applied to the visible faces).
	local facade = Assets.texture("CityFacade")
	if facade then
		for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
			local tex = Instance.new("Texture")
			tex.Texture = facade
			tex.Face = face
			tex.StudsPerTileU = 18
			tex.StudsPerTileV = 18
			tex.Parent = body
		end
	end
	-- Window bands (front + right side) — emissive rows.
	local rows = math.clamp(math.floor(h / 16), 2, 6)
	for r = 1, rows do
		local y = -h / 2 + (r / (rows + 1)) * h
		part({ Class = "Part", Name = "WinF", Size = Vector3.new(w * 0.82, 1.4, 0.4), CFrame = cf * CFrame.new(0, h / 2 + y, d / 2), Material = Enum.Material.Neon, Color = accent, Transparency = 0.15, CanCollide = false }, parent)
		part({ Class = "Part", Name = "WinS", Size = Vector3.new(0.4, 1.4, d * 0.82), CFrame = cf * CFrame.new(w / 2, h / 2 + y, 0), Material = Enum.Material.Neon, Color = accent, Transparency = 0.15, CanCollide = false }, parent)
	end
	-- Rooftop glow + occasional antenna. Only some towers get an actual light
	-- (shadows off) to keep the dynamic-light count reasonable.
	local cap = part({ Class = "Part", Name = "Roof", Size = Vector3.new(w * 1.04, 1.4, d * 1.04), CFrame = cf * CFrame.new(0, h, 0), Material = Enum.Material.Neon, Color = accent, CanCollide = false }, parent)
	if rng:NextNumber() < 0.3 then
		local rl = Instance.new("PointLight")
		rl.Color = accent
		rl.Range = 26
		rl.Brightness = 1.2
		rl.Shadows = false
		rl.Parent = cap
	end
	if rng:NextNumber() < 0.5 then
		part({ Class = "Part", Name = "Antenna", Size = Vector3.new(0.6, h * 0.25, 0.6), CFrame = cf * CFrame.new(0, h + h * 0.12, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 64, 78), CanCollide = false }, parent)
		part({ Class = "Part", Name = "Beacon", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = cf * CFrame.new(0, h + h * 0.25, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 64, 64), CanCollide = false }, parent)
	end
end

local function buildCity(parent: Instance)
	-- Inner ring (mid-rise) and outer ring (skyline).
	local rings = {
		{ count = 28, radius = 170, hMin = 45, hMax = 95, spread = 24 },
		{ count = 30, radius = 270, hMin = 90, hMax = 180, spread = 30 },
		{ count = 26, radius = 360, hMin = 130, hMax = 240, spread = 36 },
	}
	for _, ring in rings do
		for i = 1, ring.count do
			local angle = (i / ring.count) * math.pi * 2 + rng:NextNumber(-0.05, 0.05)
			local r = ring.radius + rng:NextNumber(-ring.spread, ring.spread)
			local pos = Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
			local cf = CFrame.new(pos) * CFrame.Angles(0, -angle + math.rad(90), 0)
			local w = rng:NextNumber(20, 36)
			local d = rng:NextNumber(20, 36)
			local h = rng:NextNumber(ring.hMin, ring.hMax)
			buildBuilding(parent, cf, w, d, h)
		end
	end
end

-- ===== Street lamps + holographic billboards ==========================
local function buildLamps(parent: Instance)
	for i = 1, 24 do
		local angle = (i / 24) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 96, 0, math.sin(angle) * 96)
		part({ Class = "Part", Name = "LampPost", Size = Vector3.new(1, 16, 1), CFrame = CFrame.new(pos + Vector3.new(0, 8, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 44, 56), CanCollide = false }, parent)
		local bulb = part({ Class = "Part", Name = "LampBulb", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = CFrame.new(pos + Vector3.new(0, 16, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(120, 220, 255), CanCollide = false }, parent)
		if i % 2 == 0 then
			local l = Instance.new("PointLight")
			l.Color = bulb.Color
			l.Range = 24
			l.Brightness = 1.5
			l.Shadows = false
			l.Parent = bulb
		end
	end
end

local function buildBillboards(parent: Instance)
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local r = 130
		local pos = Vector3.new(math.cos(angle) * r, 28, math.sin(angle) * r)
		local cf = CFrame.new(pos) * CFrame.Angles(0, -angle + math.rad(90), 0)
		-- Frame + glowing screen with a gradient.
		part({ Class = "Part", Name = "BoardFrame", Size = Vector3.new(44, 26, 2), CFrame = cf, Material = Enum.Material.Metal, Color = Color3.fromRGB(20, 22, 30), CanCollide = false }, parent)
		local screen = part({ Class = "Part", Name = "BoardScreen", Size = Vector3.new(40, 22, 0.6), CFrame = cf * CFrame.new(0, 0, 1.2), Material = Enum.Material.Neon, Color = randomAccent(), CanCollide = false }, parent)
		-- Support legs.
		part({ Class = "Part", Name = "BoardLeg", Size = Vector3.new(2, 30, 2), CFrame = cf * CFrame.new(-16, -28, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(28, 30, 40) }, parent)
		part({ Class = "Part", Name = "BoardLeg", Size = Vector3.new(2, 30, 2), CFrame = cf * CFrame.new(16, -28, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(28, 30, 40) }, parent)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = screen
		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, 0, 1, 0)
		txt.BackgroundTransparency = 1
		txt.Font = Enum.Font.GothamBold
		txt.TextScaled = true
		txt.TextColor3 = Color3.fromRGB(20, 20, 30)
		txt.Text = (i % 2 == 0) and "BEYBLADE\nARENA" or "¡LET IT RIP!"
		txt.Parent = gui
	end
end

-- ===== Giant beyblade monuments =======================================
local function buildMonuments(parent: Instance)
	local picks = { "celestial_prime", "void_reaper", "eternal_halo", "magma_core" }
	for i, bladeId in picks do
		local angle = (i / #picks) * math.pi * 2 + math.rad(45)
		local pos = Vector3.new(math.cos(angle) * 120, 0, math.sin(angle) * 120)
		-- Pedestal.
		part({ Class = "Part", Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(14, 22, 22), CFrame = CFrame.new(pos + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = Color3.fromRGB(40, 44, 58) }, parent)
		part({ Class = "Part", Name = "PedestalGlow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 24, 24), CFrame = CFrame.new(pos + Vector3.new(0, 14.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = randomAccent(), CanCollide = false }, parent)
		-- Giant blade statue.
		local statue = ModelBuilder.build({ BladeId = bladeId, Rarity = "Legendary", Scale = 6, Anchored = true, WithAura = true })
		statue.Name = "Monument_" .. bladeId
		statue:PivotTo(CFrame.new(pos + Vector3.new(0, 24, 0)))
		statue.Parent = parent
	end
end

-- ===== Collection garden ==============================================
local function tree(parent: Instance, pos: Vector3)
	part({ Class = "Part", Name = "Trunk", Size = Vector3.new(2.4, 12, 2.4), CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(92, 64, 40), CanCollide = false }, parent)
	for _ = 1, 3 do
		local off = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(10, 15), rng:NextNumber(-3, 3))
		part({ Class = "Part", Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(rng:NextNumber(8, 12), rng:NextNumber(8, 12), rng:NextNumber(8, 12)), CFrame = CFrame.new(pos + off), Material = Enum.Material.Grass, Color = Color3.fromRGB(56, 132, 72), CanCollide = false }, parent)
	end
end

local function buildGarden(parent: Instance)
	-- Floating island.
	part({
		Class = "Part", Name = "GardenBase", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 230, 230), CFrame = CFrame.new(GARDEN_CENTER - Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Grass, Color = Color3.fromRGB(58, 110, 70),
	}, parent)
	part({
		Class = "Part", Name = "GardenRim", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 240, 240), CFrame = CFrame.new(GARDEN_CENTER - Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Neon, Color = Color3.fromRGB(120, 220, 255), Transparency = 0.2, CanCollide = false,
	}, parent)
	-- Bridge from arena to garden.
	part({
		Class = "Part", Name = "Bridge", Size = Vector3.new(16, 1, 150),
		CFrame = CFrame.new(0, 2.6, -150), Material = Enum.Material.Metal, Color = Color3.fromRGB(44, 48, 60),
	}, parent)
	for z = -90, -220, -26 do
		part({ Class = "Part", Name = "BridgeLight", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(8, 4, z), Material = Enum.Material.Neon, Color = Color3.fromRGB(0, 224, 255), CanCollide = false }, parent)
		part({ Class = "Part", Name = "BridgeLight", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(-8, 4, z), Material = Enum.Material.Neon, Color = Color3.fromRGB(0, 224, 255), CanCollide = false }, parent)
	end
	-- Trees + central trophy.
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		tree(parent, GARDEN_CENTER + Vector3.new(math.cos(angle) * 85, -4, math.sin(angle) * 85))
	end
	part({ Class = "Part", Name = "TrophyBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 16, 16), CFrame = CFrame.new(GARDEN_CENTER + Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = Color3.fromRGB(60, 64, 80) }, parent)
	part({ Class = "Part", Name = "Trophy", Shape = Enum.PartType.Ball, Size = Vector3.new(12, 12, 12), CFrame = CFrame.new(GARDEN_CENTER + Vector3.new(0, 18, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 196, 32), CanCollide = false }, parent)
end

-- ===== Shop district (market stalls) ==================================
local function buildShopDistrict(parent: Instance)
	-- A market street along +X with colourful awning stalls on both sides.
	local STALL = ACCENTS
	for i = 0, 5 do
		local x = 116 + i * 18
		for _, side in { -1, 1 } do
			local z = side * 16
			local color = STALL[((i + (side == 1 and 1 or 0)) % #STALL) + 1]
			part({ Class = "Part", Name = "Stall", Size = Vector3.new(12, 8, 12), CFrame = CFrame.new(x, 4, z), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(46, 50, 64) }, parent)
			-- Striped awning.
			part({ Class = "Part", Name = "Awning", Size = Vector3.new(15, 1, 15), CFrame = CFrame.new(x, 8.6, z) * CFrame.Angles(math.rad(side * -8), 0, 0), Material = Enum.Material.Fabric, Color = color, CanCollide = false }, parent)
			-- Counter glow.
			part({ Class = "Part", Name = "Counter", Size = Vector3.new(12.4, 0.6, 3), CFrame = CFrame.new(x, 5.4, z + side * 6.5), Material = Enum.Material.Neon, Color = color, CanCollide = false }, parent)
		end
	end
	-- Big floating "TIENDA" hologram over the entrance.
	local sign = part({ Class = "Part", Name = "ShopSign", Size = Vector3.new(40, 12, 1), CFrame = CFrame.new(150, 22, 0) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(0, 224, 255), Transparency = 0.2, CanCollide = false }, parent)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.Parent = sign
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(10, 20, 30)
	t.Text = "🛒 MERCADO"
	t.Parent = g
end

-- ===== Spectator crowd (static dummies) ===============================
local SKIN_TONES = { Color3.fromRGB(255, 220, 178), Color3.fromRGB(234, 192, 134), Color3.fromRGB(198, 134, 88), Color3.fromRGB(141, 85, 53), Color3.fromRGB(90, 56, 37) }

local function npc(parent: Instance, pos: Vector3, faceAngle: number)
	local shirt = randomAccent()
	local pants = Color3.fromRGB(rng:NextInteger(30, 70), rng:NextInteger(30, 70), rng:NextInteger(40, 90))
	local skin = SKIN_TONES[rng:NextInteger(1, #SKIN_TONES)]
	local cf = CFrame.new(pos) * CFrame.Angles(0, faceAngle, 0)
	part({ Class = "Part", Name = "Torso", Size = Vector3.new(2, 2.2, 1), CFrame = cf * CFrame.new(0, 3.2, 0), Material = Enum.Material.SmoothPlastic, Color = shirt, CanCollide = false }, parent)
	part({ Class = "Part", Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = cf * CFrame.new(0, 4.9, 0), Material = Enum.Material.SmoothPlastic, Color = skin, CanCollide = false }, parent)
	part({ Class = "Part", Name = "Legs", Size = Vector3.new(1.8, 2, 0.9), CFrame = cf * CFrame.new(0, 1.2, 0), Material = Enum.Material.SmoothPlastic, Color = pants, CanCollide = false }, parent)
end

local function buildCrowd(parent: Instance)
	-- Ring of spectators around the arena, facing the centre.
	for i = 1, 56 do
		local angle = (i / 56) * math.pi * 2 + rng:NextNumber(-0.03, 0.03)
		local r = 80 + rng:NextNumber(-2, 4)
		local pos = Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		npc(parent, pos, -angle + math.rad(90))
	end
	-- A few clusters wandering the plaza.
	for _ = 1, 24 do
		local pos = Vector3.new(rng:NextNumber(-150, 150), 0, rng:NextNumber(-150, 150))
		if pos.Magnitude > 74 then -- keep off the arena dish
			npc(parent, pos, rng:NextNumber(0, math.pi * 2))
		end
	end
end

-- ===== Ring road + distant skyline backdrop ===========================
local function buildRingRoad(parent: Instance)
	for i = 1, 72 do
		local angle = (i / 72) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 150, 0.25, math.sin(angle) * 150)
		part({ Class = "Part", Name = "RoadDash", Size = Vector3.new(5, 0.3, 1.6), CFrame = CFrame.new(pos) * CFrame.Angles(0, -angle, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 200, 60), Transparency = 0.25, CanCollide = false }, parent)
	end
end

local function buildSkylineBackdrop(parent: Instance)
	-- Far, low-detail towers for skyline depth (no windows/lights).
	for i = 1, 40 do
		local angle = (i / 40) * math.pi * 2 + rng:NextNumber(-0.04, 0.04)
		local r = 470 + rng:NextNumber(-30, 60)
		local h = rng:NextNumber(180, 340)
		local pos = Vector3.new(math.cos(angle) * r, h / 2, math.sin(angle) * r)
		part({ Class = "Part", Name = "FarTower", Size = Vector3.new(rng:NextNumber(28, 50), h, rng:NextNumber(28, 50)), CFrame = CFrame.new(pos), Material = Enum.Material.Glass, Color = Color3.fromRGB(24, 28, 44), Reflectance = 0.1 }, parent)
		part({ Class = "Part", Name = "FarTop", Size = Vector3.new(8, 2, 8), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)), Material = Enum.Material.Neon, Color = randomAccent(), CanCollide = false }, parent)
	end
end

function Hub.build(): Vector3
	local existing = Workspace:FindFirstChild("Baseplate")
	if existing then
		existing:Destroy()
	end

	applyLighting()

	local world = Instance.new("Model")
	world.Name = "World"
	world.Parent = Workspace

	buildPlaza(world)
	buildArena(world)
	buildCity(world)
	buildSkylineBackdrop(world)
	buildRingRoad(world)
	buildLamps(world)
	buildBillboards(world)
	buildMonuments(world)
	buildShopDistrict(world)
	buildCrowd(world)
	buildGarden(world)

	-- Spawn pad near the arena.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 1, 86)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(0, 224, 255)
	spawn.Transparency = 0.25
	spawn.Parent = world

	return GARDEN_CENTER
end

Hub.ArenaCenter = ARENA_CENTER
Hub.GardenCenter = GARDEN_CENTER

return Hub
