--!strict
-- ViewportPreview.lua — renders a rotating 3D beyblade into a ViewportFrame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local ModelBuilder = require(Shared.ModelBuilder)
local BeybladeData = require(Shared.BeybladeData)
local UITheme = require(script.Parent.UITheme)

local ViewportPreview = {}

-- Single shared spin loop over all live previews (cheap, capped by UI size).
local live: { { vp: ViewportFrame, model: Model, t: number } } = {}
RunService.RenderStepped:Connect(function(dt)
	for i = #live, 1, -1 do
		local entry = live[i]
		if not entry.vp.Parent or not entry.model.Parent then
			table.remove(live, i)
		else
			entry.t += dt
			entry.model:PivotTo(CFrame.Angles(0, entry.t * 1.4, 0) * CFrame.Angles(math.rad(20), 0, math.rad(90)))
		end
	end
end)

-- Build (or rebuild) a preview inside `vp` for a given blade + skin.
function ViewportPreview.render(vp: ViewportFrame, bladeId: string, rarity: string, skinId: string?)
	local existing = vp:FindFirstChildOfClass("WorldModel")
	if existing then
		existing:Destroy()
	end
	for i = #live, 1, -1 do
		if live[i].vp == vp then
			table.remove(live, i)
		end
	end

	local world = Instance.new("WorldModel")
	world.Parent = vp
	local model = ModelBuilder.build({ BladeId = bladeId, Rarity = rarity, SkinId = skinId, Scale = 1, Anchored = true, WithAura = false })
	model.Parent = world

	local cam = vp:FindFirstChildOfClass("Camera")
	if not cam then
		cam = Instance.new("Camera")
		cam.Parent = vp
		vp.CurrentCamera = cam
	end
	local def = BeybladeData.get(bladeId)
	local dist = (def and def.Model.Radius or 1.6) * 4.2
	cam.CFrame = CFrame.new(Vector3.new(0, 1.5, dist), Vector3.new(0, 0, 0))

	table.insert(live, { vp = vp, model = model, t = 0 })
end

return ViewportPreview
