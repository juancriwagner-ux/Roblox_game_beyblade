--!strict
-- Responsive.lua — uniform UI scaling for phones/tablets/PC. Adds a single
-- UIScale under the root ScreenGui and recomputes it from the viewport size, so
-- the whole HUD shrinks gracefully on small screens instead of overflowing.

local Workspace = game:GetService("Workspace")

local Responsive = {}

local BASE = Vector2.new(1280, 720)

function Responsive.start(gui: ScreenGui)
	local scale = Instance.new("UIScale")
	scale.Name = "GlobalScale"
	scale.Parent = gui

	local function update()
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		-- Fit to the more constrained axis; clamp so it never gets unusable.
		local s = math.min(vp.X / BASE.X, vp.Y / BASE.Y)
		scale.Scale = math.clamp(s, 0.6, 1.15)
	end

	update()
	local cam = Workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local c = Workspace.CurrentCamera
		if c then
			c:GetPropertyChangedSignal("ViewportSize"):Connect(update)
			update()
		end
	end)
end

return Responsive
