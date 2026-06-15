--!strict
-- App.lua — the main UI: HUD, navigation dock, and the Collection / Shop /
-- Daily panels. Everything reacts to ClientState changes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)
local CategoryData = require(Shared.CategoryData)
local SkinData = require(Shared.SkinData)
local RankData = require(Shared.RankData)
local CrateData = require(Shared.CrateData)
local SeasonData = require(Shared.SeasonData)

local Assets = require(Shared.Assets)

local UITheme = require(script.Parent.UITheme)
local ClientState = require(script.Parent.ClientState)
local ViewportPreview = require(script.Parent.ViewportPreview)
local GachaView = require(script.Parent.GachaView)

local App = {}

local gui: ScreenGui
local panels: { [string]: Frame } = {}
local boltsLabel, coresLabel, powerLabel
local battleButton: TextButton
local searching = false

-- ===== HUD ============================================================
local function currencyPill(iconKey: string, color: Color3, parent: Instance, order: number): TextLabel
	local pill = UITheme.frame({
		Size = UDim2.new(0, 150, 0, 40), BackgroundColor3 = UITheme.Color.Panel,
		LayoutOrder = order,
	}, parent)
	UITheme.corner(20, pill)
	UITheme.stroke(color, 2, pill)
	-- Use the uploaded icon if available, else a coloured dot.
	local iconImage = Assets.image(iconKey)
	if iconImage then
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Image = iconImage
		icon.Size = UDim2.new(0, 30, 0, 30)
		icon.Position = UDim2.new(0, 6, 0.5, -15)
		icon.Parent = pill
	else
		local dot = UITheme.frame({ Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(0, 7, 0.5, -13), BackgroundColor3 = color }, pill)
		UITheme.corner(13, dot)
	end
	local label = UITheme.label({
		Size = UDim2.new(1, -44, 1, 0), Position = UDim2.new(0, 40, 0, 0),
		Text = "0", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 18,
	}, pill)
	return label
end

local function buildHud()
	local top = UITheme.frame({ Name = "Top", BackgroundTransparency = 1, Size = UDim2.new(0, 480, 0, 48), Position = UDim2.new(0, 16, 0, 12) }, gui)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 10)
	layout.Parent = top
	boltsLabel = currencyPill("BoltsIcon", UITheme.Color.Bolts, top, 1)
	coresLabel = currencyPill("CoresIcon", UITheme.Color.Cores, top, 2)

	-- Logo wordmark (top-right) once uploaded.
	local logo = Assets.image("Logo")
	if logo then
		local img = Instance.new("ImageLabel")
		img.Name = "Logo"
		img.BackgroundTransparency = 1
		img.Image = logo
		img.ScaleType = Enum.ScaleType.Fit
		img.Size = UDim2.new(0, 280, 0, 90)
		img.Position = UDim2.new(0.5, -140, 0, 8)
		img.Parent = gui
	end

	powerLabel = UITheme.label({
		Size = UDim2.new(0, 320, 0, 24), Position = UDim2.new(0, 18, 0, 66),
		Text = "", TextColor3 = UITheme.Color.SubText, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left, Font = UITheme.FontRegular,
	}, gui)
end

-- ===== Navigation dock ================================================
local function dockButton(text: string, order: number, parent: Instance, onClick: () -> ()): TextButton
	local b = UITheme.button({
		Size = UDim2.new(0, 150, 0, 46), BackgroundColor3 = UITheme.Color.PanelLight,
		TextColor3 = UITheme.Color.Text, Text = text, TextSize = 17, LayoutOrder = order,
	}, parent)
	UITheme.corner(12, b)
	UITheme.stroke(UITheme.Color.Stroke, 1.5, b)
	b.MouseButton1Click:Connect(onClick)
	return b
end

-- ===== Panel skeleton =================================================
local function makePanel(name: string, title: string): (Frame, ScrollingFrame)
	local panel = UITheme.frame({
		Name = name, Visible = false,
		Size = UDim2.new(0, 720, 0, 460), Position = UDim2.new(0.5, -360, 0.5, -230),
		BackgroundColor3 = UITheme.Color.BG,
	}, gui)
	UITheme.corner(18, panel)
	UITheme.stroke(UITheme.Color.Accent, 2, panel)

	UITheme.label({ Size = UDim2.new(1, -120, 0, 40), Position = UDim2.new(0, 24, 0, 14), Text = title, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left }, panel)
	local close = UITheme.button({ Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -52, 0, 14), Text = "✕", BackgroundColor3 = UITheme.Color.Bad, TextColor3 = UITheme.Color.Text }, panel)
	UITheme.corner(10, close)
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Content"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.new(1, -32, 1, -76)
	scroll.Position = UDim2.new(0, 16, 0, 64)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = UITheme.Color.Accent
	scroll.Parent = panel

	panels[name] = panel
	return panel, scroll
end

local function openPanel(name: string)
	for n, p in panels do
		p.Visible = (n == name)
	end
	local p = panels[name]
	if p then
		p.Size = UDim2.new(0, 0, 0, 0)
		p.Position = UDim2.new(0.5, 0, 0.5, 0)
		TweenService:Create(p, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 720, 0, 460), Position = UDim2.new(0.5, -360, 0.5, -230),
		}):Play()
	end
end

-- ===== Collection =====================================================
local function rarityBadge(parent: Instance, rarity: string)
	local tier = RarityData.Tiers[rarity]
	local badge = UITheme.label({
		Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 0, 6),
		Text = tier.Name, TextColor3 = tier.Color, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
	return badge
end

local function buildCollection(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		if c:IsA("Frame") or c:IsA("UIGridLayout") then
			c:Destroy()
		end
	end
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 158, 0, 196)
	grid.CellPadding = UDim2.new(0, 12, 0, 12)
	grid.Parent = scroll

	local profile = ClientState.get()
	if not profile then
		return
	end

	-- Sort inventory by power descending.
	local entries = {}
	for _, e in profile.Inventory do
		table.insert(entries, e)
	end
	table.sort(entries, function(a, b)
		return BeybladeData.power(a.BladeId, a.Rarity) > BeybladeData.power(b.BladeId, b.Rarity)
	end)

	for _, entry in entries do
		local def = BeybladeData.get(entry.BladeId)
		if not def then
			continue
		end
		local equipped = profile.Equipped.BladeId == entry.BladeId and profile.Equipped.Rarity == entry.Rarity
		local tier = RarityData.Tiers[entry.Rarity]

		local cell = UITheme.frame({ BackgroundColor3 = UITheme.Color.Panel }, scroll)
		UITheme.corner(12, cell)
		UITheme.stroke(equipped and UITheme.Color.Accent or tier.Color, equipped and 3 or 1.5, cell)

		local vp = UITheme.viewport({ Size = UDim2.new(1, -12, 0, 96), Position = UDim2.new(0, 6, 0, 26) }, cell)
		UITheme.corner(8, vp)
		ViewportPreview.render(vp, entry.BladeId, entry.Rarity, profile.SkinByBlade[entry.BladeId])

		rarityBadge(cell, entry.Rarity)
		UITheme.label({ Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 0, 124), Text = def.Name, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, cell)
		UITheme.label({
			Size = UDim2.new(1, -12, 0, 16), Position = UDim2.new(0, 6, 0, 142),
			Text = ("⚡%d  ×%d"):format(BeybladeData.power(entry.BladeId, entry.Rarity), entry.Count),
			TextSize = 13, TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, cell)

		local equipBtn = UITheme.button({
			Size = UDim2.new(entry.Count >= 3 and 0.58 or 1, -8, 0, 26), Position = UDim2.new(0, 6, 1, -32),
			Text = equipped and "EQUIPADO" or "Equipar", TextSize = 13,
			BackgroundColor3 = equipped and UITheme.Color.Good or UITheme.Color.Accent,
		}, cell)
		UITheme.corner(8, equipBtn)
		equipBtn.MouseButton1Click:Connect(function()
			(Net.get("EquipBlade") :: RemoteFunction):InvokeServer(entry.BladeId, entry.Rarity)
		end)

		if entry.Count >= 3 then
			local up = UITheme.button({
				Size = UDim2.new(0.42, -8, 0, 26), Position = UDim2.new(0.58, 6, 1, -32),
				Text = "⬆ x3", TextSize = 13, BackgroundColor3 = UITheme.Color.Accent2, TextColor3 = UITheme.Color.Text,
			}, cell)
			UITheme.corner(8, up)
			up.MouseButton1Click:Connect(function()
				(Net.get("PrestigeBlade") :: RemoteFunction):InvokeServer(entry.BladeId, entry.Rarity)
			end)
		end
	end
end

-- ===== Shop ===========================================================
local function buildShop(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		if c:IsA("Frame") or c:IsA("UIGridLayout") then
			c:Destroy()
		end
	end
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 158, 0, 210)
	grid.CellPadding = UDim2.new(0, 12, 0, 12)
	grid.Parent = scroll

	local profile = ClientState.get()
	if not profile then
		return
	end
	local previewBlade = profile.Equipped.BladeId
	local previewRarity = profile.Equipped.Rarity

	for _, skinId in SkinData.allIds() do
		local skin = SkinData.get(skinId)
		if not skin or skin.Id == "default" then
			continue
		end
		local owned = profile.Skins[skinId] == true
		local tier = RarityData.Tiers[skin.Rarity]
		local inUse = profile.SkinByBlade[previewBlade] == skinId

		local cell = UITheme.frame({ BackgroundColor3 = UITheme.Color.Panel }, scroll)
		UITheme.corner(12, cell)
		UITheme.stroke(tier.Color, owned and 2.5 or 1.5, cell)

		-- Prefer the uploaded premium skin render; fall back to the live 3D preview.
		local skinArt = Assets.image("Skin_" .. skinId)
		if skinArt then
			local img = Instance.new("ImageLabel")
			img.BackgroundColor3 = UITheme.Color.BG
			img.BorderSizePixel = 0
			img.Image = skinArt
			img.ScaleType = Enum.ScaleType.Crop
			img.Size = UDim2.new(1, -12, 0, 100)
			img.Position = UDim2.new(0, 6, 0, 26)
			img.Parent = cell
			UITheme.corner(8, img)
		else
			local vp = UITheme.viewport({ Size = UDim2.new(1, -12, 0, 100), Position = UDim2.new(0, 6, 0, 26) }, cell)
			UITheme.corner(8, vp)
			ViewportPreview.render(vp, previewBlade, previewRarity, skinId)
		end

		UITheme.label({ Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 0, 6), Text = skin.Limited and "★ LIMITADA" or tier.Name, TextColor3 = tier.Color, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, cell)
		UITheme.label({ Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 0, 128), Text = skin.Name, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, cell)
		UITheme.label({ Size = UDim2.new(1, -12, 0, 16), Position = UDim2.new(0, 6, 0, 148), Text = ("◆ %d Núcleos"):format(skin.Price), TextColor3 = UITheme.Color.Cores, TextSize = 13, Font = UITheme.FontRegular, TextXAlignment = Enum.TextXAlignment.Left }, cell)

		local btn = UITheme.button({ Size = UDim2.new(1, -12, 0, 30), Position = UDim2.new(0, 6, 1, -36), TextSize = 14 }, cell)
		UITheme.corner(8, btn)
		if not owned then
			btn.Text = "Comprar"
			btn.BackgroundColor3 = UITheme.Color.Cores
			btn.MouseButton1Click:Connect(function()
				(Net.get("BuySkin") :: RemoteFunction):InvokeServer(skinId)
			end)
		elseif inUse then
			btn.Text = "EN USO"
			btn.BackgroundColor3 = UITheme.Color.Good
		else
			btn.Text = "Equipar"
			btn.BackgroundColor3 = UITheme.Color.Accent
			btn.MouseButton1Click:Connect(function()
				(Net.get("EquipSkin") :: RemoteFunction):InvokeServer(previewBlade, skinId)
			end)
		end
	end
end

-- ===== Daily ==========================================================
local function buildDaily(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		if c:IsA("Frame") or c:IsA("UIGridLayout") or c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local profile = ClientState.get()
	if not profile then
		return
	end
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 88, 0, 110)
	grid.CellPadding = UDim2.new(0, 10, 0, 10)
	grid.Parent = scroll

	for i, reward in Config.Rewards.Daily do
		local claimedToday = (i <= profile.Daily.Day)
		local isNext = (i == (profile.Daily.Day % #Config.Rewards.Daily) + 1)
		local cell = UITheme.frame({ BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = i }, scroll)
		UITheme.corner(10, cell)
		UITheme.stroke(isNext and UITheme.Color.Accent or (claimedToday and UITheme.Color.Good or UITheme.Color.Stroke), isNext and 3 or 1.5, cell)
		UITheme.label({ Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 8), Text = ("Día %d"):format(i), TextSize = 14 }, cell)
		UITheme.label({ Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0, 4, 0, 44), Text = ("⚙ %d"):format(reward.Bolts), TextColor3 = UITheme.Color.Bolts, TextSize = 13, Font = UITheme.FontRegular }, cell)
		UITheme.label({ Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0, 4, 0, 64), Text = ("◆ %d"):format(reward.Cores), TextColor3 = UITheme.Color.Cores, TextSize = 13, Font = UITheme.FontRegular }, cell)
		if claimedToday then
			UITheme.label({ Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -24), Text = "✓", TextColor3 = UITheme.Color.Good, TextSize = 16 }, cell)
		end
	end

	local claim = UITheme.button({ Size = UDim2.new(0, 220, 0, 44), Position = UDim2.new(0, 0, 0, 130), Text = "Reclamar recompensa diaria", TextSize = 16, BackgroundColor3 = UITheme.Color.Accent }, scroll)
	UITheme.corner(10, claim)
	claim.MouseButton1Click:Connect(function()
		local res = (Net.get("ClaimDaily") :: RemoteFunction):InvokeServer()
		if res and not res.ok and res.remaining then
			claim.Text = "Disponible en " .. Util.duration(res.remaining)
			task.delay(2.5, function()
				claim.Text = "Reclamar recompensa diaria"
			end)
		end
	end)
end

-- ===== Crates / Gacha =================================================
local function buildGacha(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		c:Destroy()
	end
	local profile = ClientState.get()
	if not profile then
		return
	end
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	for i, crateId in CrateData.Order do
		local crate = CrateData.get(crateId)
		if not crate then
			continue
		end
		local curColor = crate.Currency == "Cores" and UITheme.Color.Cores or UITheme.Color.Bolts
		local canAfford = (profile.Currencies[crate.Currency] or 0) >= crate.Price

		local card = UITheme.frame({ Size = UDim2.new(1, -6, 0, 110), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = i }, scroll)
		UITheme.corner(14, card)
		UITheme.stroke(crate.Color, 2.5, card)
		-- Glowing crate emblem.
		local emblem = UITheme.frame({ Size = UDim2.new(0, 78, 0, 78), Position = UDim2.new(0, 16, 0.5, -39), BackgroundColor3 = crate.Color }, card)
		UITheme.corner(14, emblem)
		UITheme.label({ Size = UDim2.new(1, 0, 1, 0), Text = "🎁", TextSize = 40 }, emblem)

		UITheme.label({ Size = UDim2.new(1, -260, 0, 26), Position = UDim2.new(0, 108, 0, 16), Text = crate.Name, TextColor3 = crate.Color, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left }, card)
		UITheme.label({
			Size = UDim2.new(1, -260, 0, 44), Position = UDim2.new(0, 108, 0, 44), Text = crate.Desc,
			TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		}, card)

		local btn = UITheme.button({
			Size = UDim2.new(0, 132, 0, 48), Position = UDim2.new(1, -148, 0.5, -24),
			Text = ("Abrir\n%s %d"):format(crate.Currency == "Cores" and "◆" or "⚙", crate.Price),
			TextSize = 15, BackgroundColor3 = canAfford and curColor or UITheme.Color.PanelLight,
			TextColor3 = canAfford and UITheme.Color.BG or UITheme.Color.SubText,
		}, card)
		btn.AutoButtonColor = canAfford
		UITheme.corner(10, btn)
		btn.MouseButton1Click:Connect(function()
			if GachaView.isBusy() then
				return
			end
			local res = (Net.get("OpenCrate") :: RemoteFunction):InvokeServer(crateId)
			if res and res.ok then
				GachaView.play(crate, res, gui)
			end
		end)
	end
end

-- ===== Battle Pass / Season ===========================================
local function rewardText(r: any): string
	local parts = {}
	if r.Bolts then table.insert(parts, ("⚙ %d"):format(r.Bolts)) end
	if r.Cores then table.insert(parts, ("◆ %d"):format(r.Cores)) end
	if r.Skin then table.insert(parts, ("🎨 %s"):format(SkinData.get(r.Skin) and SkinData.get(r.Skin).Name or r.Skin)) end
	if r.Blade then table.insert(parts, ("🌀 %s"):format(BeybladeData.get(r.Blade.Id) and BeybladeData.get(r.Blade.Id).Name or r.Blade.Id)) end
	return table.concat(parts, "  ")
end

local function claimChip(parent: Instance, x: number, w: number, label: string, color: Color3, enabled: boolean, onClick: (() -> ())?)
	local b = UITheme.button({ Size = UDim2.new(0, w, 0, 28), Position = UDim2.new(0, x, 1, -34), Text = label, TextSize = 13, BackgroundColor3 = color, TextColor3 = enabled and UITheme.Color.BG or UITheme.Color.SubText }, parent)
	UITheme.corner(7, b)
	b.AutoButtonColor = enabled
	if enabled and onClick then
		b.MouseButton1Click:Connect(onClick)
	end
	return b
end

local function buildSeason(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		c:Destroy()
	end
	local profile = ClientState.get()
	if not profile then
		return
	end
	local s = profile.Season
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	-- Header card: season name, tier, XP bar, premium status.
	local head = UITheme.frame({ Size = UDim2.new(1, -6, 0, 92), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = 0 }, scroll)
	UITheme.corner(14, head)
	UITheme.stroke(s.Premium and UITheme.Color.Bolts or UITheme.Color.Accent, 2.5, head)
	UITheme.label({ Size = UDim2.new(1, -200, 0, 26), Position = UDim2.new(0, 14, 0, 10), Text = SeasonData.name(s.Id ~= 0 and s.Id or SeasonData.currentId()), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left }, head)
	UITheme.label({ Size = UDim2.new(1, -200, 0, 20), Position = UDim2.new(0, 14, 0, 38), Text = ("Nivel %d / %d   %s"):format(s.Tier, SeasonData.MaxTier, s.Premium and "🌟 Premium" or "Gratis"), TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, head)
	-- XP progress within the current tier.
	local intoTier = s.XP % SeasonData.XpPerTier
	local track = UITheme.frame({ Size = UDim2.new(1, -28, 0, 12), Position = UDim2.new(0, 14, 0, 66), BackgroundColor3 = UITheme.Color.BG }, head)
	UITheme.corner(6, track)
	local fill = UITheme.frame({ Size = UDim2.new(s.Tier >= SeasonData.MaxTier and 1 or (intoTier / SeasonData.XpPerTier), 0, 1, 0), BackgroundColor3 = UITheme.Color.Accent }, track)
	UITheme.corner(6, fill)
	if not s.Premium then
		local buy = UITheme.button({ Size = UDim2.new(0, 170, 0, 40), Position = UDim2.new(1, -184, 0, 10), Text = ("🌟 Pase Premium\n◆ %d"):format(SeasonData.PremiumPriceCores), TextSize = 14, BackgroundColor3 = UITheme.Color.Bolts, TextColor3 = UITheme.Color.BG }, head)
		UITheme.corner(10, buy)
		buy.MouseButton1Click:Connect(function()
			(Net.get("BuyPremiumPass") :: RemoteFunction):InvokeServer()
		end)
	end

	-- Column headers.
	local hdr = UITheme.frame({ Size = UDim2.new(1, -6, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1 }, scroll)
	UITheme.label({ Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 6, 0, 0), Text = "Nivel", TextColor3 = UITheme.Color.SubText, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, hdr)
	UITheme.label({ Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0, 64, 0, 0), Text = "Gratis", TextColor3 = UITheme.Color.SubText, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, hdr)
	UITheme.label({ Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.55, 0, 0, 0), Text = "🌟 Premium", TextColor3 = UITheme.Color.Bolts, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, hdr)

	for tier = 1, SeasonData.MaxTier do
		local rewards = SeasonData.rewardFor(tier)
		local unlocked = tier <= s.Tier
		local row = UITheme.frame({ Size = UDim2.new(1, -6, 0, 66), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = tier + 1 }, scroll)
		UITheme.corner(10, row)
		UITheme.stroke(unlocked and UITheme.Color.Accent or UITheme.Color.Stroke, unlocked and 2 or 1, row)
		-- Tier badge.
		UITheme.label({ Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 6, 0, 0), Text = tostring(tier), TextSize = 22, TextColor3 = unlocked and UITheme.Color.Accent or UITheme.Color.SubText }, row)

		-- Free reward + chip.
		UITheme.label({ Size = UDim2.new(0.4, 0, 0, 22), Position = UDim2.new(0, 64, 0, 8), Text = rewardText(rewards.Free), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, row)
		do
			local key = tostring(tier)
			if s.ClaimedFree[key] then
				claimChip(row, 64, 100, "✓ Reclamado", UITheme.Color.Good, false)
			elseif unlocked then
				claimChip(row, 64, 100, "Reclamar", UITheme.Color.Accent, true, function()
					(Net.get("ClaimSeasonReward") :: RemoteFunction):InvokeServer(tier, "free")
				end)
			else
				claimChip(row, 64, 100, "🔒 Bloqueado", UITheme.Color.PanelLight, false)
			end
		end

		-- Premium reward + chip.
		UITheme.label({ Size = UDim2.new(0.4, 0, 0, 22), Position = UDim2.new(0.55, 0, 0, 8), Text = rewardText(rewards.Premium), TextColor3 = UITheme.Color.Bolts, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, row)
		do
			local key = tostring(tier)
			local px = 372
			if not s.Premium then
				claimChip(row, px, 120, "🌟 Premium", UITheme.Color.PanelLight, false)
			elseif s.ClaimedPremium[key] then
				claimChip(row, px, 120, "✓ Reclamado", UITheme.Color.Good, false)
			elseif unlocked then
				claimChip(row, px, 120, "Reclamar", UITheme.Color.Bolts, true, function()
					(Net.get("ClaimSeasonReward") :: RemoteFunction):InvokeServer(tier, "premium")
				end)
			else
				claimChip(row, px, 120, "🔒 Bloqueado", UITheme.Color.PanelLight, false)
			end
		end
	end
end

-- ===== Quests =========================================================
local function buildQuests(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		c:Destroy()
	end
	local profile = ClientState.get()
	if not profile then
		return
	end
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	for i, q in profile.Quests.List do
		local done = q.Progress >= q.Target
		local row = UITheme.frame({ Size = UDim2.new(1, -6, 0, 84), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = i }, scroll)
		UITheme.corner(12, row)
		UITheme.stroke(q.Claimed and UITheme.Color.Good or (done and UITheme.Color.Accent or UITheme.Color.Stroke), done and 2.5 or 1.5, row)
		UITheme.label({ Size = UDim2.new(1, -180, 0, 24), Position = UDim2.new(0, 14, 0, 10), Text = q.Desc, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left }, row)
		UITheme.label({
			Size = UDim2.new(1, -180, 0, 18), Position = UDim2.new(0, 14, 0, 56),
			Text = ("Recompensa: %d Tuercas%s"):format(q.Bolts, q.Cores > 0 and (" · " .. q.Cores .. " Núcleos") or ""),
			TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		-- Progress bar.
		local track = UITheme.frame({ Size = UDim2.new(1, -190, 0, 12), Position = UDim2.new(0, 14, 0, 36), BackgroundColor3 = UITheme.Color.BG }, row)
		UITheme.corner(6, track)
		local fill = UITheme.frame({ Size = UDim2.new(math.clamp(q.Progress / q.Target, 0, 1), 0, 1, 0), BackgroundColor3 = UITheme.Color.Accent }, track)
		UITheme.corner(6, fill)
		UITheme.label({ Size = UDim2.new(0, 60, 0, 12), Position = UDim2.new(1, -176, 0, 36), Text = ("%d/%d"):format(q.Progress, q.Target), TextSize = 12, TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular }, row)

		local btn = UITheme.button({ Size = UDim2.new(0, 130, 0, 40), Position = UDim2.new(1, -144, 0.5, -20), TextSize = 15 }, row)
		UITheme.corner(10, btn)
		if q.Claimed then
			btn.Text = "RECLAMADO"
			btn.BackgroundColor3 = UITheme.Color.Good
			btn.AutoButtonColor = false
		elseif done then
			btn.Text = "Reclamar"
			btn.BackgroundColor3 = UITheme.Color.Accent
			btn.MouseButton1Click:Connect(function()
				(Net.get("ClaimQuest") :: RemoteFunction):InvokeServer(q.Id)
			end)
		else
			btn.Text = "En progreso"
			btn.BackgroundColor3 = UITheme.Color.PanelLight
			btn.TextColor3 = UITheme.Color.SubText
			btn.AutoButtonColor = false
		end
	end
end

-- ===== Ranking ========================================================
local function buildRanking(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		c:Destroy()
	end
	local profile = ClientState.get()
	if not profile then
		return
	end
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	-- Your league card.
	local rank = RankData.forTrophies(profile.Trophies)
	local toNext, nextRank = RankData.toNext(profile.Trophies)
	local card = UITheme.frame({ Size = UDim2.new(1, -6, 0, 74), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = 0 }, scroll)
	UITheme.corner(12, card)
	UITheme.stroke(rank.Color, 2.5, card)
	UITheme.label({ Size = UDim2.new(1, -20, 0, 28), Position = UDim2.new(0, 14, 0, 10), Text = ("%s Liga %s"):format(rank.Icon, rank.Name), TextColor3 = rank.Color, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left }, card)
	local sub = toNext and ("🏆 %d  ·  faltan %d para %s"):format(profile.Trophies, toNext, nextRank.Name) or ("🏆 %d  ·  ¡liga máxima!"):format(profile.Trophies)
	UITheme.label({ Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 14, 0, 42), Text = sub, TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, card)

	local header = UITheme.label({ Size = UDim2.new(1, -6, 0, 24), Text = "🌍 Top mundial — Trofeos", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, scroll)

	-- Async fetch of the global board.
	task.spawn(function()
		local top = (Net.get("GetLeaderboard") :: RemoteFunction):InvokeServer("Trophies")
		if typeof(top) ~= "table" then
			return
		end
		if #top == 0 then
			UITheme.label({ Size = UDim2.new(1, -6, 0, 30), Text = "Aún sin datos (se llena al jugar y publicar).", TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 13, LayoutOrder = 2 }, scroll)
			return
		end
		for i, entry in top do
			local medal = (i == 1 and "🥇") or (i == 2 and "🥈") or (i == 3 and "🥉") or ("#" .. i)
			local row = UITheme.frame({ Size = UDim2.new(1, -6, 0, 38), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = i + 1 }, scroll)
			UITheme.corner(8, row)
			UITheme.label({ Size = UDim2.new(0, 44, 1, 0), Position = UDim2.new(0, 8, 0, 0), Text = medal, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left }, row)
			UITheme.label({ Size = UDim2.new(1, -160, 1, 0), Position = UDim2.new(0, 56, 0, 0), Text = entry.Name, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left }, row)
			UITheme.label({ Size = UDim2.new(0, 96, 1, 0), Position = UDim2.new(1, -104, 0, 0), Text = ("🏆 %s"):format(Util.abbreviate(entry.Value)), TextColor3 = UITheme.Color.Bolts, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right }, row)
		end
	end)
end

-- ===== Extras: codes + settings =======================================
local function buildExtras(scroll: ScrollingFrame)
	for _, c in scroll:GetChildren() do
		c:Destroy()
	end
	local profile = ClientState.get()
	if not profile then
		return
	end
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.Parent = scroll

	-- Codes.
	local codeCard = UITheme.frame({ Size = UDim2.new(1, -6, 0, 110), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = 1 }, scroll)
	UITheme.corner(12, codeCard)
	UITheme.stroke(UITheme.Color.Accent, 1.5, codeCard)
	UITheme.label({ Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 14, 0, 10), Text = "🎟️ Canjear código", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left }, codeCard)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -160, 0, 40)
	box.Position = UDim2.new(0, 14, 0, 50)
	box.BackgroundColor3 = UITheme.Color.BG
	box.BorderSizePixel = 0
	box.Font = UITheme.Font
	box.TextColor3 = UITheme.Color.Text
	box.PlaceholderText = "Escribe un código..."
	box.Text = ""
	box.TextSize = 16
	box.ClearTextOnFocus = false
	box.Parent = codeCard
	UITheme.corner(8, box)
	local redeem = UITheme.button({ Size = UDim2.new(0, 130, 0, 40), Position = UDim2.new(1, -144, 0, 50), Text = "Canjear", TextSize = 16 }, codeCard)
	UITheme.corner(8, redeem)
	redeem.MouseButton1Click:Connect(function()
		if box.Text == "" then
			return
		end
		local res = (Net.get("RedeemCode") :: RemoteFunction):InvokeServer(box.Text)
		box.Text = ""
		if res and not res.ok then
			redeem.Text = res.reason == "used" and "Ya usado" or "Inválido"
			task.delay(1.8, function()
				redeem.Text = "Canjear"
			end)
		end
	end)
	UITheme.label({ Size = UDim2.new(1, -20, 0, 16), Position = UDim2.new(0, 14, 0, 92), Text = "Prueba: LAUNCH · BEYBLADE · SPINSTORM", TextColor3 = UITheme.Color.SubText, Font = UITheme.FontRegular, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, codeCard)

	-- Settings toggles.
	local setCard = UITheme.frame({ Size = UDim2.new(1, -6, 0, 70), BackgroundColor3 = UITheme.Color.Panel, LayoutOrder = 2 }, scroll)
	UITheme.corner(12, setCard)
	UITheme.stroke(UITheme.Color.Stroke, 1.5, setCard)
	UITheme.label({ Size = UDim2.new(1, -20, 0, 22), Position = UDim2.new(0, 14, 0, 8), Text = "⚙️ Ajustes", TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left }, setCard)

	local function toggle(label: string, key: string, x: number)
		local on = profile.Settings[key] == true
		local b = UITheme.button({ Size = UDim2.new(0, 150, 0, 30), Position = UDim2.new(0, x, 0, 34), Text = ("%s: %s"):format(label, on and "ON" or "OFF"), TextSize = 14, BackgroundColor3 = on and UITheme.Color.Good or UITheme.Color.PanelLight, TextColor3 = on and UITheme.Color.BG or UITheme.Color.SubText }, setCard)
		UITheme.corner(8, b)
		b.MouseButton1Click:Connect(function()
			profile.Settings[key] = not profile.Settings[key]
			(Net.get("SaveSettings") :: RemoteFunction):InvokeServer({ Music = profile.Settings.Music, Sfx = profile.Settings.Sfx })
			local nowOn = profile.Settings[key]
			b.Text = ("%s: %s"):format(label, nowOn and "ON" or "OFF")
			b.BackgroundColor3 = nowOn and UITheme.Color.Good or UITheme.Color.PanelLight
			b.TextColor3 = nowOn and UITheme.Color.BG or UITheme.Color.SubText
		end)
	end
	toggle("Música", "Music", 14)
	toggle("Sonido", "Sfx", 176)
end

-- ===== Refresh on profile change ======================================
local function refreshHud(profile)
	if not profile then
		return
	end
	boltsLabel.Text = Util.abbreviate(profile.Currencies.Bolts)
	coresLabel.Text = Util.abbreviate(profile.Currencies.Cores)
	local eq = profile.Equipped
	local def = BeybladeData.get(eq.BladeId)
	local rank = RankData.forTrophies(profile.Trophies or 0)
	if def then
		powerLabel.Text = ("%s <b>%s</b> · Nv.%d · Equipado: <b>%s</b> · ⚡%d"):format(
			rank.Icon, rank.Name, profile.Level or 1, def.Name, BeybladeData.power(eq.BladeId, eq.Rarity)
		)
	end
end

function App.setBattleSearching(state: boolean)
	searching = state
	if battleButton then
		battleButton.Text = state and "Buscando rival..." or "⚔️  BATALLAR"
		battleButton.BackgroundColor3 = state and UITheme.Color.PanelLight or UITheme.Color.Bad
	end
end

function App.start(screenGui: ScreenGui)
	gui = screenGui
	buildHud()

	-- Navigation dock (left side, below the HUD, grows downward).
	local dock = UITheme.frame({ Name = "Dock", BackgroundTransparency = 1, Size = UDim2.new(0, 160, 0, 540), Position = UDim2.new(0, 16, 0, 104) }, gui)
	local dl = Instance.new("UIListLayout")
	dl.Padding = UDim.new(0, 9)
	dl.Parent = dock

	-- Panels.
	local _, colScroll = makePanel("Collection", "🎒  Colección")
	local _, shopScroll = makePanel("Shop", "🛒  Tienda de Skins")
	local _, crateScroll = makePanel("Crates", "📦  Cofres")
	local _, dailyScroll = makePanel("Daily", "🎁  Recompensa Diaria")
	local _, questScroll = makePanel("Quests", "🎯  Misiones Diarias")
	local _, rankScroll = makePanel("Ranking", "🏆  Ranking")
	local _, seasonScroll = makePanel("Season", "🏅  Pase de Temporada")
	local _, extrasScroll = makePanel("Extras", "🎟️  Códigos y Ajustes")

	dockButton("🎒  Colección", 2, dock, function()
		buildCollection(colScroll)
		openPanel("Collection")
	end)
	dockButton("🏅  Pase", 3, dock, function()
		buildSeason(seasonScroll)
		openPanel("Season")
	end)
	dockButton("📦  Cofres", 4, dock, function()
		buildGacha(crateScroll)
		openPanel("Crates")
	end)
	dockButton("🎯  Misiones", 5, dock, function()
		buildQuests(questScroll)
		openPanel("Quests")
	end)
	dockButton("🏆  Ranking", 6, dock, function()
		buildRanking(rankScroll)
		openPanel("Ranking")
	end)
	dockButton("🛒  Tienda", 7, dock, function()
		buildShop(shopScroll)
		openPanel("Shop")
	end)
	dockButton("🎁  Diario", 8, dock, function()
		buildDaily(dailyScroll)
		openPanel("Daily")
	end)
	dockButton("🎟️  Extras", 9, dock, function()
		buildExtras(extrasScroll)
		openPanel("Extras")
	end)

	-- Big battle button (bottom centre).
	battleButton = UITheme.button({
		Size = UDim2.new(0, 280, 0, 64), Position = UDim2.new(0.5, -140, 1, -84),
		Text = "⚔️  BATALLAR", TextSize = 24, BackgroundColor3 = UITheme.Color.Bad, TextColor3 = UITheme.Color.Text,
	}, gui)
	UITheme.corner(16, battleButton)
	UITheme.stroke(UITheme.Color.Accent, 2.5, battleButton)
	battleButton.MouseButton1Click:Connect(function()
		if searching then
			return
		end
		App.setBattleSearching(true)
		local res = (Net.get("StartBattle") :: RemoteFunction):InvokeServer()
		if not res or not res.ok then
			App.setBattleSearching(false)
		end
	end)

	-- React to data.
	ClientState.onChanged(function(profile)
		refreshHud(profile)
		-- Live-refresh any open panel.
		if panels.Collection.Visible then
			buildCollection(colScroll)
		end
		if panels.Shop.Visible then
			buildShop(shopScroll)
		end
		if panels.Daily.Visible then
			buildDaily(dailyScroll)
		end
		if panels.Quests.Visible then
			buildQuests(questScroll)
		end
		if panels.Extras.Visible then
			buildExtras(extrasScroll)
		end
		if panels.Crates.Visible then
			buildGacha(crateScroll)
		end
		if panels.Season.Visible then
			buildSeason(seasonScroll)
		end
	end)
end

return App
