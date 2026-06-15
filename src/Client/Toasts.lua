--!strict
-- Toasts.lua — transient notifications + a flashy "blade collected" popup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)
local UITheme = require(script.Parent.UITheme)
local Sound = require(script.Parent.Sound)

local Toasts = {}

local player = Players.LocalPlayer
local gui: ScreenGui

local KIND_COLOR = {
	info = UITheme.Color.Accent,
	success = UITheme.Color.Good,
	error = UITheme.Color.Bad,
	currency = UITheme.Color.Bolts,
}

local function pushToast(text: string, kind: string)
	local holder = gui:FindFirstChild("ToastHolder") :: Frame
	local toast = UITheme.frame({
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = UITheme.Color.Panel,
		BackgroundTransparency = 0,
		Position = UDim2.new(1, 0, 0, 0),
	}, holder)
	UITheme.corner(10, toast)
	UITheme.stroke(KIND_COLOR[kind] or UITheme.Color.Accent, 2, toast)
	local bar = UITheme.frame({
		Size = UDim2.new(0, 5, 1, -10), Position = UDim2.new(0, 5, 0, 5),
		BackgroundColor3 = KIND_COLOR[kind] or UITheme.Color.Accent,
	}, toast)
	UITheme.corner(3, bar)
	UITheme.label({
		Size = UDim2.new(1, -24, 1, 0), Position = UDim2.new(0, 18, 0, 0),
		Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 15,
	}, toast)

	toast:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.35, true)
	task.delay(3.5, function()
		toast:TweenPosition(UDim2.new(1, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quint, 0.3, true)
		task.wait(0.35)
		toast:Destroy()
	end)
end

local function collectPopup(bladeId: string, rarity: string)
	local def = BeybladeData.get(bladeId)
	local tier = RarityData.Tiers[rarity]
	if not def or not tier then
		return
	end
	Sound.play("Collect", 0.7)
	local card = UITheme.frame({
		Size = UDim2.new(0, 320, 0, 96),
		Position = UDim2.new(0.5, -160, 0, -120),
		AnchorPoint = Vector2.new(0, 0),
		BackgroundColor3 = UITheme.Color.Panel,
	}, gui)
	UITheme.corner(14, card)
	UITheme.stroke(tier.Color, 3, card)
	UITheme.label({
		Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 14, 0, 12),
		Text = "✦ ¡BEYBLADE OBTENIDO!", TextColor3 = tier.Color,
		TextXAlignment = Enum.TextXAlignment.Left, TextSize = 16,
	}, card)
	UITheme.label({
		Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 14, 0, 40),
		Text = def.Name, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 22,
	}, card)
	UITheme.label({
		Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 14, 0, 66),
		Text = ("%s · %s · %s"):format(tier.Name, def.Element, def.Category),
		TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular,
		TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14,
	}, card)

	card:TweenPosition(UDim2.new(0.5, -160, 0, 70), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
	task.delay(2.6, function()
		card:TweenPosition(UDim2.new(0.5, -160, 0, -120), Enum.EasingDirection.In, Enum.EasingStyle.Quint, 0.35, true)
		task.wait(0.4)
		card:Destroy()
	end)
end

function Toasts.start(parentGui: ScreenGui)
	gui = parentGui
	local holder = UITheme.frame({
		Name = "ToastHolder", BackgroundTransparency = 1,
		Size = UDim2.new(0, 320, 0, 300), Position = UDim2.new(1, -334, 0, 90),
	}, gui)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	;(Net.get("Notify") :: RemoteEvent).OnClientEvent:Connect(pushToast)
	;(Net.get("SpawnCollected") :: RemoteEvent).OnClientEvent:Connect(collectPopup)
end

return Toasts
