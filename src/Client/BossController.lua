--!strict
-- BossController.lua — World Boss HUD: a live banner with the boss name, shared
-- HP bar, countdown timer and an ATTACK button, plus floating damage numbers.
-- When no boss is active it shows a countdown to the next event.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Util = require(Shared.Util)
local UITheme = require(script.Parent.UITheme)
local Sound = require(script.Parent.Sound)

local BossController = {}

local gui: ScreenGui
local state: any = { Active = false, NextAt = 0, EndsAt = 0, HP = 0, MaxHP = 1, Name = "" }
local frame: Frame
local idleLabel: TextLabel
local hpFill: Frame
local nameLabel: TextLabel
local timerLabel: TextLabel
local attackBtn: TextButton
local lastAttack = 0

local function damagePopup(amount: number)
	local lbl = UITheme.label({
		Size = UDim2.new(0, 160, 0, 40), Position = UDim2.new(0.5, math.random(-80, 80), 0, 96),
		Text = "-" .. Util.abbreviate(amount), TextColor3 = UITheme.Color.Bolts, TextSize = 28, ZIndex = 40,
	}, gui)
	lbl:TweenPosition(UDim2.new(0.5, lbl.Position.X.Offset, 0, 50), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.7, true)
	TweenService:Create(lbl, TweenInfo.new(0.7), { TextTransparency = 1 }):Play()
	task.delay(0.75, function()
		lbl:Destroy()
	end)
end

local function doAttack()
	if not state.Active then
		return
	end
	if os.clock() - lastAttack < 1.0 then
		return
	end
	lastAttack = os.clock()
	local res = (Net.get("AttackBoss") :: RemoteFunction):InvokeServer()
	if res and res.ok then
		damagePopup(res.damage)
		Sound.play("Clash", 0.5)
		state.HP = res.hp
		state.MaxHP = res.maxHp
	end
end

local function build()
	-- Active boss banner.
	frame = UITheme.frame({ Name = "BossBanner", Visible = false, Size = UDim2.new(0, 470, 0, 78), Position = UDim2.new(0.5, -235, 0, 10), BackgroundColor3 = UITheme.Color.Panel, ZIndex = 30 }, gui)
	UITheme.corner(14, frame)
	UITheme.stroke(Color3.fromRGB(255, 96, 48), 2.5, frame)
	nameLabel = UITheme.label({ Size = UDim2.new(1, -130, 0, 22), Position = UDim2.new(0, 14, 0, 8), Text = "👹 Jefe", TextColor3 = Color3.fromRGB(255, 120, 64), TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31 }, frame)
	timerLabel = UITheme.label({ Size = UDim2.new(0, 120, 0, 22), Position = UDim2.new(0, 220, 0, 8), Text = "", TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31 }, frame)
	local track = UITheme.frame({ Size = UDim2.new(1, -130, 0, 18), Position = UDim2.new(0, 14, 0, 44), BackgroundColor3 = UITheme.Color.BG, ZIndex = 31 }, frame)
	UITheme.corner(9, track)
	hpFill = UITheme.frame({ Name = "Fill", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 80, 64), ZIndex = 32 }, track)
	UITheme.corner(9, hpFill)
	local hpText = UITheme.label({ Name = "HPText", Size = UDim2.new(1, -130, 0, 18), Position = UDim2.new(0, 14, 0, 44), Text = "", TextSize = 12, ZIndex = 33 }, frame)

	attackBtn = UITheme.button({ Size = UDim2.new(0, 104, 0, 60), Position = UDim2.new(1, -114, 0.5, -30), Text = "⚔️\nATACAR", TextSize = 17, BackgroundColor3 = UITheme.Color.Bad, TextColor3 = UITheme.Color.Text, ZIndex = 32 }, frame)
	UITheme.corner(10, attackBtn)
	attackBtn.MouseButton1Click:Connect(doAttack)

	-- Idle countdown label.
	idleLabel = UITheme.label({ Name = "BossIdle", Visible = false, Size = UDim2.new(0, 360, 0, 26), Position = UDim2.new(0.5, -180, 0, 14), Text = "", TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 15, ZIndex = 30 }, gui)
end

local function refresh()
	if state.Active then
		frame.Visible = true
		idleLabel.Visible = false
		nameLabel.Text = "👹 " .. (state.Name or "Jefe Mundial")
		local ratio = math.clamp(state.HP / math.max(1, state.MaxHP), 0, 1)
		hpFill.Size = UDim2.new(ratio, 0, 1, 0)
		local hpText = frame:FindFirstChild("HPText") :: TextLabel?
		if hpText then
			hpText.Text = ("%s / %s"):format(Util.abbreviate(state.HP), Util.abbreviate(state.MaxHP))
		end
		local left = math.max(0, (state.EndsAt or 0) - os.time())
		timerLabel.Text = "⏱ " .. Util.duration(left)
	else
		frame.Visible = false
		idleLabel.Visible = true
		local left = math.max(0, (state.NextAt or 0) - os.time())
		idleLabel.Text = "👹 Próximo Jefe Mundial en " .. Util.duration(left)
	end
end

function BossController.start(screenGui: ScreenGui)
	gui = screenGui
	build()

	;(Net.get("BossUpdate") :: RemoteEvent).OnClientEvent:Connect(function(s)
		local wasActive = state.Active
		state = s
		refresh()
		if s.Active and not wasActive then
			Sound.play("Launch", 0.6)
		end
	end)

	-- Tick the countdown labels once per second.
	task.spawn(function()
		while true do
			refresh()
			task.wait(1)
		end
	end)
end

return BossController
