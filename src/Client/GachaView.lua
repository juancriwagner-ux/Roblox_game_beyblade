--!strict
-- GachaView.lua — cinematic crate-opening reveal. The server already granted
-- the blade; this only visualises the result: a suspense build-up, a flash,
-- then a reward card with the blade's 3D preview glowing in its rarity colour.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)

local UITheme = require(script.Parent.UITheme)
local ViewportPreview = require(script.Parent.ViewportPreview)
local Sound = require(script.Parent.Sound)

local GachaView = {}

local busy = false

function GachaView.isBusy(): boolean
	return busy
end

function GachaView.play(crate: any, result: any, gui: ScreenGui)
	if busy then
		return
	end
	busy = true

	local def = BeybladeData.get(result.bladeId)
	local tier = RarityData.Tiers[result.rarity]
	if not def or not tier then
		busy = false
		return
	end

	-- Dim backdrop (blocks input).
	local dim = UITheme.frame({
		Name = "GachaDim", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, ZIndex = 50,
	}, gui)
	TweenService:Create(dim, TweenInfo.new(0.3), { BackgroundTransparency = 0.45 }):Play()

	-- Suspense orb: a pulsing, spinning crate-coloured disc.
	local orb = UITheme.frame({
		Size = UDim2.new(0, 140, 0, 140), Position = UDim2.new(0.5, -70, 0.5, -70),
		BackgroundColor3 = crate.Color, ZIndex = 51,
	}, gui)
	UITheme.corner(70, orb)
	UITheme.stroke(Color3.new(1, 1, 1), 3, orb)

	local spinConn
	local t0 = os.clock()
	spinConn = RunService.RenderStepped:Connect(function()
		local age = os.clock() - t0
		local pulse = 1 + math.sin(age * (8 + age * 6)) * 0.12 * math.min(age, 1.5)
		orb.Rotation = age * (120 + age * 120)
		orb.Size = UDim2.new(0, 140 * pulse, 0, 140 * pulse)
		orb.Position = UDim2.new(0.5, -70 * pulse, 0.5, -70 * pulse)
	end)

	task.wait(1.6)
	spinConn:Disconnect()

	-- Flash.
	local flash = UITheme.frame({ Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = tier.Color, BackgroundTransparency = 0.1, ZIndex = 52 }, gui)
	orb:Destroy()
	Sound.play("Collect", 0.8)
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	task.delay(0.55, function()
		flash:Destroy()
	end)

	-- Reward card.
	local card = UITheme.frame({
		Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = UITheme.Color.Panel, ZIndex = 53,
	}, gui)
	UITheme.corner(18, card)
	UITheme.stroke(tier.Color, 3.5, card)
	TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 320, 0, 380), Position = UDim2.new(0.5, -160, 0.5, -190),
	}):Play()

	UITheme.label({ Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 12), Text = ("✦ %s"):format(tier.Name), TextColor3 = tier.Color, TextSize = 18, ZIndex = 54 }, card)

	local vp = UITheme.viewport({ Size = UDim2.new(1, -40, 0, 200), Position = UDim2.new(0, 20, 0, 44), ZIndex = 54 }, card)
	UITheme.corner(12, vp)
	ViewportPreview.render(vp, result.bladeId, result.rarity, nil)

	UITheme.label({ Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 10, 0, 252), Text = def.Name, TextSize = 24, ZIndex = 54 }, card)
	UITheme.label({
		Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 284),
		Text = ("%s · %s · ⚡%d"):format(def.Element, def.Category, BeybladeData.power(result.bladeId, result.rarity)),
		TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 14, ZIndex = 54,
	}, card)

	local close = UITheme.button({ Size = UDim2.new(1, -40, 0, 44), Position = UDim2.new(0, 20, 1, -56), Text = "¡Genial!", TextSize = 18, ZIndex = 54 }, card)
	UITheme.corner(10, close)

	local done = Instance.new("BindableEvent")
	close.MouseButton1Click:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		task.wait(0.28)
		card:Destroy()
		dim:Destroy()
		busy = false
		done:Fire()
	end)
	done.Event:Wait()
end

return GachaView
