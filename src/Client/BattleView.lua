--!strict
-- BattleView.lua
-- Cinematic playback of an authoritative battle result. The server already
-- decided everything (winner + per-round log); this module just *visualises*
-- it in the real 3D arena: two blades spin in, clash each round with camera
-- shake + sparks, their stamina bars drain to match the log, then a winner is
-- declared. Purely cosmetic — no gameplay trust here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)
local CategoryData = require(Shared.CategoryData)
local ModelBuilder = require(Shared.ModelBuilder)
local UITheme = require(script.Parent.UITheme)
local ClientState = require(script.Parent.ClientState)

local BattleView = {}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local ARENA = Vector3.new(0, 6, 0)
local playing = false

function BattleView.isPlaying(): boolean
	return playing
end

-- Continuous spin driver for anchored blade models.
local function makeSpinner()
	local entries: { { model: Model, pos: Vector3, speed: number, lean: number } } = {}
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		for _, e in entries do
			if e.model.Parent then
				e.pos = e.model:GetPivot().Position
				e.model:PivotTo(
					CFrame.new(e.pos)
						* CFrame.Angles(0, os.clock() * e.speed, math.rad(90))
						* CFrame.Angles(math.rad(e.lean), 0, 0)
				)
			end
		end
	end)
	return {
		add = function(model: Model, speed: number)
			table.insert(entries, { model = model, pos = model:GetPivot().Position, speed = speed, lean = 0 })
		end,
		setLean = function(model: Model, lean: number)
			for _, e in entries do
				if e.model == model then
					e.lean = lean
				end
			end
		end,
		setSpeed = function(model: Model, speed: number)
			for _, e in entries do
				if e.model == model then
					e.speed = speed
				end
			end
		end,
		stop = function()
			conn:Disconnect()
		end,
	}
end

local function moveTo(model: Model, pos: Vector3, time: number)
	local start = model:GetPivot().Position
	local t0 = os.clock()
	while os.clock() - t0 < time do
		local a = (os.clock() - t0) / time
		local p = start:Lerp(pos, TweenService:GetValue(a, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut))
		-- preserve current spin orientation by only setting position component
		local piv = model:GetPivot()
		model:PivotTo(CFrame.new(p) * (piv - piv.Position))
		RunService.RenderStepped:Wait()
	end
end

local function clashBurst(pos: Vector3, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = pos
	p.Parent = Workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Speed = NumberRange.new(18, 32)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.8, 0)
	emitter.LightEmission = 1
	emitter.Rate = 0
	emitter.Parent = p
	emitter:Emit(40)
	task.delay(0.8, function()
		p:Destroy()
	end)
end

local function cameraShake(intensity: number)
	local base = camera.CFrame
	local t0 = os.clock()
	task.spawn(function()
		while os.clock() - t0 < 0.25 do
			local off = Vector3.new(
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity
			)
			camera.CFrame = base + off
			RunService.RenderStepped:Wait()
		end
		camera.CFrame = base
	end)
end

-- Build the on-screen battle HUD (names + stamina bars + round counter).
local function buildOverlay(gui: ScreenGui, nameA: string, nameB: string)
	local holder = UITheme.frame({
		Name = "BattleOverlay", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, gui)

	local function bar(side: number, name: string, color: Color3)
		local x = side < 0 and UDim2.new(0, 24, 0, 24) or UDim2.new(1, -344, 0, 24)
		local frame = UITheme.frame({ Size = UDim2.new(0, 320, 0, 56), Position = x }, holder)
		UITheme.corner(10, frame)
		UITheme.stroke(color, 2, frame)
		UITheme.label({
			Size = UDim2.new(1, -16, 0, 22), Position = UDim2.new(0, 10, 0, 6),
			Text = name, TextColor3 = color, TextSize = 16,
			TextXAlignment = side < 0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
		}, frame)
		local track = UITheme.frame({
			Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 10, 0, 34),
			BackgroundColor3 = UITheme.Color.BG,
		}, frame)
		UITheme.corner(7, track)
		local fill = UITheme.frame({
			Name = "Fill", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = color,
		}, track)
		UITheme.corner(7, fill)
		return fill
	end

	local center = UITheme.label({
		Name = "Round", Size = UDim2.new(0, 240, 0, 40),
		Position = UDim2.new(0.5, -120, 0, 30), Text = "¡LISTOS!",
		TextSize = 30, TextColor3 = UITheme.Color.Accent,
	}, holder)

	return holder, bar(-1, nameA, UITheme.Color.Accent), bar(1, nameB, UITheme.Color.Accent2), center
end

local function setBar(fill: Frame, ratio: number)
	TweenService:Create(fill, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0),
	}):Play()
end

local function resultBanner(gui: ScreenGui, won: boolean, rewards: any)
	local banner = UITheme.frame({
		Size = UDim2.new(0, 420, 0, 150), Position = UDim2.new(0.5, -210, 0.5, -180),
		BackgroundColor3 = UITheme.Color.Panel,
	}, gui)
	UITheme.corner(16, banner)
	UITheme.stroke(won and UITheme.Color.Good or UITheme.Color.Bad, 3, banner)
	UITheme.label({
		Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 16),
		Text = won and "🏆 ¡VICTORIA!" or "💥 DERROTA",
		TextSize = 40, TextColor3 = won and UITheme.Color.Good or UITheme.Color.Bad,
	}, banner)
	local rewardText = won
		and ("+%d Tuercas   +%d Núcleos"):format(rewards.Bolts, rewards.Cores)
		or ("+%d Tuercas"):format(rewards.Bolts)
	UITheme.label({
		Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 80),
		Text = rewardText, TextSize = 20, TextColor3 = UITheme.Color.Bolts,
	}, banner)
	banner.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 150),
	}):Play()
	task.delay(3.5, function()
		TweenService:Create(banner, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		task.wait(0.35)
		banner:Destroy()
	end)
end

-- Pull the local player's chosen skin for a blade.
local function skinFor(bladeId: string): string
	local profile = ClientState.get()
	if profile and profile.SkinByBlade and profile.SkinByBlade[bladeId] then
		return profile.SkinByBlade[bladeId]
	end
	return "default"
end

function BattleView.play(result: any, youAre: number, opponentName: string, rewards: any, gui: ScreenGui)
	if playing then
		return
	end
	playing = true

	local mine = (youAre == 1) and result.A or result.B
	local theirs = (youAre == 1) and result.B or result.A
	local myName = "TÚ"

	-- Stamina maxima for bar normalisation.
	local myMax = BeybladeData.effectiveStats(mine.BladeId, mine.Rarity).Stamina
	local theirMax = BeybladeData.effectiveStats(theirs.BladeId, theirs.Rarity).Stamina

	-- Build the two blades in the arena.
	local modelMine = ModelBuilder.build({ BladeId = mine.BladeId, Rarity = mine.Rarity, SkinId = skinFor(mine.BladeId), Scale = 2.2, Anchored = true, WithAura = true })
	local modelTheirs = ModelBuilder.build({ BladeId = theirs.BladeId, Rarity = theirs.Rarity, Scale = 2.2, Anchored = true, WithAura = true })
	ModelBuilder.addSpinTrail(modelMine, RarityData.Tiers[mine.Rarity].Color)
	ModelBuilder.addSpinTrail(modelTheirs, RarityData.Tiers[theirs.Rarity].Color)
	modelMine.Parent = Workspace
	modelTheirs.Parent = Workspace
	local leftStart = ARENA + Vector3.new(-26, 8, 0)
	local rightStart = ARENA + Vector3.new(26, 8, 0)
	modelMine:PivotTo(CFrame.new(leftStart))
	modelTheirs:PivotTo(CFrame.new(rightStart))

	local spinner = makeSpinner()
	spinner.add(modelMine, 40)
	spinner.add(modelTheirs, -40)

	-- Cinematic camera.
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(ARENA + Vector3.new(0, 22, 42), ARENA)

	local overlay, fillMine, fillTheirs, roundLabel = buildOverlay(gui, myName, opponentName)
	setBar(fillMine, 1)
	setBar(fillTheirs, 1)

	-- Launch in.
	task.spawn(function() moveTo(modelMine, ARENA + Vector3.new(-7, 6, 0), 0.6) end)
	moveTo(modelTheirs, ARENA + Vector3.new(7, 6, 0), 0.6)
	task.wait(0.3)

	-- Replay each round.
	for _, round in result.Rounds do
		roundLabel.Text = ("RONDA %d"):format(round.Index)
		-- Dash toward the centre and clash.
		task.spawn(function() moveTo(modelMine, ARENA + Vector3.new(-1.5, 6, 0), Config.Battle.RoundDuration * 0.4) end)
		moveTo(modelTheirs, ARENA + Vector3.new(1.5, 6, 0), Config.Battle.RoundDuration * 0.4)

		local clashColor = round.Crit and UITheme.Color.Bolts or UITheme.Color.Accent
		clashBurst(ARENA + Vector3.new(0, 6, 0), clashColor)
		cameraShake(round.Crit and 2.4 or 1.4)

		if round.Dodge then
			roundLabel.Text = "¡ESQUIVA!"
		elseif round.Winner == youAre then
			roundLabel.Text = "¡GOLPE!"
		elseif round.Winner ~= 0 then
			roundLabel.Text = "¡RECIBES!"
		end

		-- Update stamina bars to the logged values.
		local sMine = (youAre == 1) and round.StaminaA or round.StaminaB
		local sTheirs = (youAre == 1) and round.StaminaB or round.StaminaA
		setBar(fillMine, sMine / myMax)
		setBar(fillTheirs, sTheirs / theirMax)

		-- Recoil back out.
		task.spawn(function() moveTo(modelMine, ARENA + Vector3.new(-7, 6, 0), Config.Battle.RoundDuration * 0.4) end)
		moveTo(modelTheirs, ARENA + Vector3.new(7, 6, 0), Config.Battle.RoundDuration * 0.4)
		task.wait(Config.Battle.RoundDuration * 0.2)
	end

	-- Decide visual winner.
	local won = result.Winner == youAre
	local loserModel = won and modelTheirs or modelMine
	roundLabel.Text = ""

	-- Loser wobbles and topples.
	spinner.setSpeed(loserModel, 6)
	task.spawn(function()
		for _ = 1, 20 do
			spinner.setLean(loserModel, 18)
			RunService.RenderStepped:Wait()
		end
	end)
	moveTo(loserModel, loserModel:GetPivot().Position - Vector3.new(0, 4, 0), 1.2)

	resultBanner(gui, won, rewards)
	task.wait(2.5)

	-- Cleanup.
	spinner.stop()
	modelMine:Destroy()
	modelTheirs:Destroy()
	overlay:Destroy()
	camera.CameraType = prevType
	playing = false
end

return BattleView
