--!strict
-- CrowdController.lua — brings the stadium crowd to life. Each tagged "Fan"
-- model gently sways while idle and jumps (in a stagger wave) on battle impacts.
-- Purely client-side: it animates the already-replicated anchored dummies, so
-- it costs the server nothing.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local CrowdController = {}

type Fan = { model: Model, base: CFrame, phase: number, jumpStart: number }

local fans: { Fan } = {}
local hyped = false
local started = false

local function register(model: Instance)
	if not model:IsA("Model") or not model.PrimaryPart then
		return
	end
	table.insert(fans, {
		model = model,
		base = model:GetPivot(),
		phase = math.random() * 100,
		jumpStart = -1,
	})
end

local function animate()
	local now = os.clock()
	for _, fan in fans do
		if fan.model.Parent and fan.model.PrimaryPart then
			local sway = math.sin(now * 2 + fan.phase) * (hyped and 0.5 or 0.15)
			local jump = 0
			if now >= fan.jumpStart and now < fan.jumpStart + 0.45 then
				jump = math.sin(((now - fan.jumpStart) / 0.45) * math.pi) * (hyped and 3.2 or 2)
			end
			local lean = hyped and math.sin(now * 6 + fan.phase) * 0.06 or 0
			fan.model:PivotTo(fan.base * CFrame.new(0, sway + jump, 0) * CFrame.Angles(0, lean, 0))
		end
	end
end

-- Trigger a celebratory jump wave (called on battle impacts).
function CrowdController.pop()
	local now = os.clock()
	for _, fan in fans do
		fan.jumpStart = now + (fan.phase % 1) * 0.28 -- stagger for a "wave"
	end
end

function CrowdController.setHype(state: boolean)
	hyped = state
end

function CrowdController.start()
	if started then
		return
	end
	started = true
	for _, m in CollectionService:GetTagged("Fan") do
		register(m)
	end
	CollectionService:GetInstanceAddedSignal("Fan"):Connect(register)
	RunService.RenderStepped:Connect(animate)
end

return CrowdController
