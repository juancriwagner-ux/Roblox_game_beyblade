--!strict
-- ModelBuilder.lua
-- Procedurally constructs a 3D beyblade Model from a catalog recipe + optional
-- skin override. No external mesh assets required: everything is built from
-- primitives, neon, lights and particles so it works out-of-the-box and still
-- looks premium. Used for world-spawn pickups, collection previews and the
-- battle arena.

local BeybladeData = require(script.Parent.BeybladeData)
local CategoryData = require(script.Parent.CategoryData)
local RarityData = require(script.Parent.RarityData)
local SkinData = require(script.Parent.SkinData)

local ModelBuilder = {}

export type BuildOptions = {
	BladeId: string,
	Rarity: string?,
	SkinId: string?,
	Scale: number?,
	Anchored: boolean?,
	WithAura: boolean?, -- particles + light (skip for distant/low-end)
}

type Palette = {
	Primary: Color3,
	Secondary: Color3,
	Material: Enum.Material,
	Emissive: number,
	Trail: Color3,
	Aura: string,
}

-- Resolve the colour/material palette from skin (if any) else the element.
local function resolvePalette(bladeId: string, skinId: string?): Palette
	local def = BeybladeData.get(bladeId)
	local element = def and CategoryData.Elements[def.Element]
	local skin = skinId and SkinData.get(skinId)
	if skin and skin.Id ~= "default" then
		return {
			Primary = skin.Primary,
			Secondary = skin.Secondary,
			Material = skin.Material,
			Emissive = skin.Emissive,
			Trail = skin.Trail,
			Aura = skin.Aura,
		}
	end
	return {
		Primary = element and element.Primary or Color3.fromRGB(200, 200, 210),
		Secondary = element and element.Secondary or Color3.fromRGB(110, 110, 120),
		Material = element and element.Material or Enum.Material.Metal,
		Emissive = 0.2,
		Trail = element and element.Primary or Color3.fromRGB(255, 255, 255),
		Aura = element and element.Particle or "none",
	}
end

local function makePart(props: { [string]: any }): BasePart
	local part = Instance.new(props.Class or "Part") :: BasePart
	props.Class = nil
	for k, v in props do
		(part :: any)[k] = v
	end
	return part
end

-- Build a single contact blade/tip on the outer ring.
local function buildTip(profile: string, radius: number, height: number, palette: Palette): BasePart
	if profile == "spike" then
		return makePart({
			Class = "WedgePart", Material = palette.Material, Color = palette.Secondary,
			Size = Vector3.new(0.18, height * 0.9, radius * 0.5), Anchored = false, CanCollide = false,
		})
	elseif profile == "blade" then
		return makePart({
			Class = "WedgePart", Material = palette.Material, Color = palette.Primary,
			Size = Vector3.new(0.12, height * 0.7, radius * 0.7), Anchored = false, CanCollide = false,
		})
	elseif profile == "star" then
		return makePart({
			Class = "Part", Material = palette.Material, Color = palette.Primary,
			Size = Vector3.new(0.22, height * 0.6, radius * 0.55), Anchored = false, CanCollide = false,
		})
	elseif profile == "orb" then
		return makePart({
			Class = "Part", Shape = Enum.PartType.Ball, Material = palette.Material, Color = palette.Secondary,
			Size = Vector3.new(radius * 0.32, radius * 0.32, radius * 0.32), Anchored = false, CanCollide = false,
		})
	else -- disc
		return makePart({
			Class = "Part", Material = palette.Material, Color = palette.Secondary,
			Size = Vector3.new(0.16, height * 0.5, radius * 0.4), Anchored = false, CanCollide = false,
		})
	end
end

local function addAura(core: BasePart, palette: Palette, rarity: string)
	if palette.Aura == "none" then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Aura"
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Rate = 28
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(1, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.4, 0)
	emitter.LightEmission = 1
	if palette.Aura == "rainbow" then
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 200, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 120, 255)),
		})
	else
		emitter.Color = ColorSequence.new(palette.Primary, palette.Secondary)
	end
	emitter.Parent = core

	local light = Instance.new("PointLight")
	light.Color = palette.Primary
	light.Range = 8 + (RarityData.Tiers[rarity] and RarityData.Tiers[rarity].Glow or 0) * 4
	light.Brightness = 1.5 + (palette.Emissive or 0)
	light.Shadows = false
	light.Parent = core
end

-- Main entry. Returns an un-parented Model with PrimaryPart = Core.
function ModelBuilder.build(opts: BuildOptions): Model
	local def = BeybladeData.get(opts.BladeId)
	assert(def, "ModelBuilder: unknown blade " .. tostring(opts.BladeId))
	local rarity = opts.Rarity or def.Rarity
	local palette = resolvePalette(opts.BladeId, opts.SkinId)
	local scale = opts.Scale or 1
	local recipe = def.Model
	local radius = recipe.Radius * scale
	local height = recipe.Height * scale
	local anchored = opts.Anchored == true

	local model = Instance.new("Model")
	model.Name = def.Name

	-- ===== Core (PrimaryPart) =====
	local core = makePart({
		Class = "Part", Name = "Core", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height * 0.7, radius * 0.7, radius * 0.7),
		Material = Enum.Material.Neon, Color = palette.Primary,
		Anchored = anchored, CanCollide = false,
	})
	core.CFrame = CFrame.Angles(0, 0, math.rad(90)) -- lay the cylinder flat
	model.PrimaryPart = core
	core.Parent = model

	-- ===== Energy ring =====
	local ring = makePart({
		Class = "Part", Name = "Ring", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height * 0.45, radius * 1.8, radius * 1.8),
		Material = palette.Material, Color = palette.Secondary,
		Anchored = anchored, CanCollide = false,
	})
	local weldOrAnchor = function(part: BasePart, cf: CFrame)
		part.CFrame = core.CFrame * cf
		if not anchored then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = core
			weld.Part1 = part
			weld.Parent = part
		end
		part.Parent = model
	end
	weldOrAnchor(ring, CFrame.new(0, 0, 0))

	-- ===== Contact tips around the ring =====
	local tips = math.max(2, recipe.Tips)
	for i = 1, tips do
		local angle = (i / tips) * math.pi * 2
		local tip = buildTip(recipe.Profile, radius, height, palette)
		-- Place around the ring; the cylinder's flat face lies on the YZ plane,
		-- so we distribute tips in that plane (local Y/Z).
		local offset = CFrame.Angles(angle, 0, 0) * CFrame.new(0, 0, radius * 0.95)
		weldOrAnchor(tip, offset)
	end

	-- ===== Bottom spin tip =====
	local spin = makePart({
		Class = "Part", Name = "SpinTip", Shape = Enum.PartType.Ball,
		Size = Vector3.new(radius * 0.28, radius * 0.28, radius * 0.28),
		Material = Enum.Material.Metal, Color = palette.Secondary,
		Anchored = anchored, CanCollide = false,
	})
	weldOrAnchor(spin, CFrame.new(-height * 0.5, 0, 0))

	-- ===== Crown glow disc on top =====
	local crown = makePart({
		Class = "Part", Name = "Crown", Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height * 0.18, radius * 0.9, radius * 0.9),
		Material = Enum.Material.Neon, Color = palette.Primary,
		Anchored = anchored, CanCollide = false,
		Transparency = 0.15,
	})
	weldOrAnchor(crown, CFrame.new(height * 0.42, 0, 0))

	if opts.WithAura ~= false then
		addAura(core, palette, rarity)
	end

	-- Tag for runtime lookups.
	model:SetAttribute("BladeId", opts.BladeId)
	model:SetAttribute("Rarity", rarity)
	model:SetAttribute("SkinId", opts.SkinId or "default")

	return model
end

-- Attach a spin trail to a built model's tips (used in the arena).
function ModelBuilder.addSpinTrail(model: Model, color: Color3)
	local core = model.PrimaryPart
	if not core then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, core.Size.Z * 0.5)
	a0.Parent = core
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, -core.Size.Z * 0.5)
	a1.Parent = core
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.25
	trail.Color = ColorSequence.new(color)
	trail.LightEmission = 1
	trail.Transparency = NumberSequence.new(0.2, 1)
	trail.Parent = core
end

return ModelBuilder
