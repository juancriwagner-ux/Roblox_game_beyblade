--!strict
-- BattleView.lua
-- Cinematic playback of an authoritative battle result. The server decides the
-- outcome (winner + per-round log); this module *visualises* it in the real 3D
-- arena with a dynamic camera director, a "Let it rip" countdown, shockwaves,
-- sparks, screen flashes, slow-motion finishers, letterbox bars and a winner
-- celebration. Unified for 1v1, 2v2 and spectating. Purely cosmetic.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)
local ModelBuilder = require(Shared.ModelBuilder)
local UITheme = require(script.Parent.UITheme)
local ClientState = require(script.Parent.ClientState)
local Sound = require(script.Parent.Sound)
local MusicController = require(script.Parent.MusicController)

local BattleView = {}

local camera = Workspace.CurrentCamera
local ARENA = Vector3.new(0, 6, 0)
local playing = false

function BattleView.isPlaying(): boolean
	return playing
end

-- ===== Low-level helpers ==============================================
local function skinFor(bladeId: string): string?
	local profile = ClientState.get()
	if profile and profile.SkinByBlade and profile.SkinByBlade[bladeId] then
		return profile.SkinByBlade[bladeId]
	end
	return nil
end

local function zOffsets(n: number): { number }
	if n <= 1 then
		return { 0 }
	end
	return { -4.5, 4.5 }
end

local function sumList(t: { number }): number
	local s = 0
	for _, v in t do
		s += v
	end
	return s
end

local function teamMax(blades: { any }): number
	local m = 0
	for _, b in blades do
		local st = BeybladeData.effectiveStats(b.BladeId, b.Rarity)
		m += st and st.Stamina or 1
	end
	return math.max(1, m)
end

-- Continuous spin driver for anchored blade models.
local function makeSpinner()
	local entries: { { model: Model, speed: number, lean: number } } = {}
	local conn
	conn = RunService.RenderStepped:Connect(function()
		for _, e in entries do
			if e.model.Parent then
				local pos = e.model:GetPivot().Position
				e.model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, os.clock() * e.speed, math.rad(90)) * CFrame.Angles(math.rad(e.lean), 0, 0))
			end
		end
	end)
	return {
		add = function(model: Model, speed: number)
			table.insert(entries, { model = model, speed = speed, lean = 0 })
		end,
		setSpeed = function(model: Model, speed: number)
			for _, e in entries do
				if e.model == model then e.speed = speed end
			end
		end,
		setLean = function(model: Model, lean: number)
			for _, e in entries do
				if e.model == model then e.lean = lean end
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
		local a = TweenService:GetValue((os.clock() - t0) / time, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local p = start:Lerp(pos, a)
		local piv = model:GetPivot()
		model:PivotTo(CFrame.new(p) * (piv - piv.Position))
		RunService.RenderStepped:Wait()
	end
end

-- ===== Camera director ================================================
local function makeCameraDirector()
	local cur = camera.CFrame
	local target = cur
	local mode = "free"
	local oc, orr, oh, oa, ospeed = ARENA, 34, 20, 0, 0.25
	local smoothing = 6
	local shakeMag, shakeUntil = 0, 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		if mode == "orbit" then
			oa += ospeed * dt
			target = CFrame.new(oc + Vector3.new(math.cos(oa) * orr, oh, math.sin(oa) * orr), oc)
		end
		cur = cur:Lerp(target, math.clamp(dt * smoothing, 0, 1))
		local off = Vector3.zero
		if os.clock() < shakeUntil then
			local m = shakeMag * math.clamp((shakeUntil - os.clock()) / 0.3, 0, 1)
			off = Vector3.new((math.random() - 0.5) * m, (math.random() - 0.5) * m, (math.random() - 0.5) * m)
		end
		camera.CFrame = cur + off
	end)
	return {
		set = function(cf: CFrame, snap: boolean?, smooth: number?)
			mode = "free"; target = cf; smoothing = smooth or 6
			if snap then cur = cf end
		end,
		orbit = function(center: Vector3, r: number, h: number, speed: number)
			oc, orr, oh, ospeed = center, r, h, speed
			oa = math.atan2((cur.Position - center).Z, (cur.Position - center).X)
			mode = "orbit"; smoothing = 4
		end,
		shake = function(mag: number)
			shakeMag = mag; shakeUntil = os.clock() + 0.3
		end,
		stop = function()
			conn:Disconnect()
		end,
	}
end

-- ===== VFX ============================================================
local function shockwave(pos: Vector3, color: Color3, scale: number)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.1
	ring.Size = Vector3.new(0.5, 3, 3)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace
	TweenService:Create(ring, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, 46 * scale, 46 * scale), Transparency = 1,
	}):Play()
	task.delay(0.6, function() ring:Destroy() end)
end

local function sparkBurst(pos: Vector3, color: Color3, count: number, speed: number)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Size = Vector3.one; p.Position = pos; p.CastShadow = false
	p.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.Lifetime = NumberRange.new(0.3, 0.7)
	e.Speed = NumberRange.new(speed * 0.6, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.9, 0)
	e.LightEmission = 1
	e.Rate = 0
	e.Parent = p
	e:Emit(count)
	task.delay(1, function() p:Destroy() end)
end

local function impact(pos: Vector3, color: Color3, big: boolean)
	shockwave(pos, color, big and 1.6 or 1)
	sparkBurst(pos, color, big and 70 or 36, big and 40 or 26)
	if big then
		shockwave(pos, Color3.fromRGB(255, 255, 255), 0.7)
	end
end

local function makeFlash(gui: ScreenGui)
	local f = UITheme.frame({ Name = "Flash", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 45 }, gui)
	return function(color: Color3, strength: number)
		f.BackgroundColor3 = color
		f.BackgroundTransparency = 1 - strength
		TweenService:Create(f, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	end, f
end

local function makeLetterbox(gui: ScreenGui)
	local top = UITheme.frame({ Name = "BarTop", Size = UDim2.new(1, 0, 0, 70), Position = UDim2.new(0, 0, 0, -70), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 44 }, gui)
	local bot = UITheme.frame({ Name = "BarBot", Size = UDim2.new(1, 0, 0, 70), Position = UDim2.new(0, 0, 1, 70), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 44 }, gui)
	top:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
	bot:TweenPosition(UDim2.new(0, 0, 1, -70), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.5, true)
	return function()
		top:TweenPosition(UDim2.new(0, 0, 0, -70), Enum.EasingDirection.In, Enum.EasingStyle.Quint, 0.4, true)
		bot:TweenPosition(UDim2.new(0, 0, 1, 70), Enum.EasingDirection.In, Enum.EasingStyle.Quint, 0.4, true)
		task.delay(0.5, function() top:Destroy(); bot:Destroy() end)
	end
end

local function bigText(gui: ScreenGui, text: string, color: Color3, life: number)
	local lbl = UITheme.label({ Size = UDim2.new(0, 600, 0, 120), Position = UDim2.new(0.5, -300, 0.5, -120), Text = text, TextColor3 = color, TextSize = 80, ZIndex = 46 }, gui)
	lbl.TextStrokeTransparency = 0.2
	lbl.TextTransparency = 1
	lbl.Rotation = -4
	TweenService:Create(lbl, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextTransparency = 0, TextSize = 96 }):Play()
	task.delay(life, function()
		TweenService:Create(lbl, TweenInfo.new(0.25), { TextTransparency = 1, TextSize = 70 }):Play()
		task.wait(0.28); lbl:Destroy()
	end)
	return lbl
end

local function victoryBeam(pos: Vector3, color: Color3)
	local beam = Instance.new("Part")
	beam.Anchored = true; beam.CanCollide = false; beam.CastShadow = false
	beam.Shape = Enum.PartType.Cylinder
	beam.Material = Enum.Material.Neon; beam.Color = color; beam.Transparency = 0.5
	beam.Size = Vector3.new(160, 10, 10)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 78, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Parent = Workspace
	local conf = Instance.new("Part")
	conf.Anchored = true; conf.CanCollide = false; conf.Transparency = 1; conf.Size = Vector3.one; conf.Position = pos + Vector3.new(0, 10, 0); conf.CastShadow = false
	conf.Parent = Workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 220, 255)) })
	e.Lifetime = NumberRange.new(1.2, 2.2); e.Speed = NumberRange.new(14, 26); e.SpreadAngle = Vector2.new(60, 60)
	e.Size = NumberSequence.new(1.1, 0); e.LightEmission = 1; e.Rate = 0; e.Acceleration = Vector3.new(0, -18, 0)
	e.Parent = conf
	e:Emit(120)
	task.delay(3.5, function() beam:Destroy(); conf:Destroy() end)
end

local function smokeOut(model: Model)
	local core = model.PrimaryPart
	if not core then return end
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(60, 60, 70))
	e.Lifetime = NumberRange.new(0.6, 1.1); e.Speed = NumberRange.new(2, 6); e.Size = NumberSequence.new(3, 7)
	e.Rate = 40; e.Transparency = NumberSequence.new(0.3, 1)
	e.Parent = core
	task.delay(1.5, function() e.Enabled = false end)
end

-- ===== Overlay (names + team stamina bars + round label) ==============
local function buildOverlay(gui: ScreenGui, nameA: string, nameB: string)
	local holder = UITheme.frame({ Name = "BattleOverlay", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 42 }, gui)
	local function bar(side: number, name: string, color: Color3): Frame
		local x = side < 0 and UDim2.new(0, 24, 0, 84) or UDim2.new(1, -344, 0, 84)
		local frame = UITheme.frame({ Size = UDim2.new(0, 320, 0, 54), Position = x, ZIndex = 42 }, holder)
		UITheme.corner(10, frame)
		UITheme.stroke(color, 2, frame)
		UITheme.label({ Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 10, 0, 6), Text = name, TextColor3 = color, TextSize = 15, TextXAlignment = side < 0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right, ZIndex = 43 }, frame)
		local track = UITheme.frame({ Size = UDim2.new(1, -20, 0, 14), Position = UDim2.new(0, 10, 0, 32), BackgroundColor3 = UITheme.Color.BG, ZIndex = 42 }, frame)
		UITheme.corner(7, track)
		local fill = UITheme.frame({ Name = "Fill", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = color, ZIndex = 43 }, track)
		UITheme.corner(7, fill)
		return fill
	end
	local center = UITheme.label({ Name = "Round", Size = UDim2.new(0, 400, 0, 36), Position = UDim2.new(0.5, -200, 0, 88), Text = "", TextSize = 26, TextColor3 = UITheme.Color.Accent, ZIndex = 43 }, holder)
	return holder, bar(-1, nameA, UITheme.Color.Accent), bar(1, nameB, UITheme.Color.Accent2), center
end

local function setBar(fill: Frame, ratio: number)
	TweenService:Create(fill, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0) }):Play()
end

local function resultBanner(gui: ScreenGui, won: boolean, rewards: any)
	local banner = UITheme.frame({ Size = UDim2.new(0, 440, 0, 150), Position = UDim2.new(0.5, -220, 0.5, -180), BackgroundColor3 = UITheme.Color.Panel, ZIndex = 47 }, gui)
	UITheme.corner(16, banner)
	UITheme.stroke(won and UITheme.Color.Good or UITheme.Color.Bad, 3, banner)
	UITheme.label({ Size = UDim2.new(1, 0, 0, 60), Position = UDim2.new(0, 0, 0, 16), Text = won and "🏆 ¡VICTORIA!" or "💥 DERROTA", TextSize = 42, TextColor3 = won and UITheme.Color.Good or UITheme.Color.Bad, ZIndex = 48 }, banner)
	local rt = won and ("+%d Tuercas   +%d Núcleos"):format(rewards.Bolts, rewards.Cores) or ("+%d Tuercas"):format(rewards.Bolts)
	UITheme.label({ Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 84), Text = rt, TextSize = 20, TextColor3 = UITheme.Color.Bolts, ZIndex = 48 }, banner)
	banner.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 440, 0, 150), Position = UDim2.new(0.5, -220, 0.5, -180) }):Play()
	task.delay(3.4, function()
		TweenService:Create(banner, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		task.wait(0.35); banner:Destroy()
	end)
end

-- ===== Core cinematic =================================================
-- sides = { mine = {Name, Blades}, foe = {Name, Blades} }
-- rounds = { {Index, Winner(1 mine/2 foe/0), StaminaMine={}, StaminaFoe={}, Crit, Dodge} }
local function runCinematic(sides: any, rounds: any, mineWon: boolean, gui: ScreenGui, opts: any)
	playing = true
	MusicController.setBattle(true)
	local prevType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	local closeLetterbox = makeLetterbox(gui)
	local flash = makeFlash(gui)
	local mineMax = teamMax(sides.mine.Blades)
	local foeMax = teamMax(sides.foe.Blades)

	-- Build models.
	local function build(blades: { any }, baseX: number, useSkin: boolean): { Model }
		local models = {}
		local offs = zOffsets(#blades)
		for i, b in blades do
			local m = ModelBuilder.build({ BladeId = b.BladeId, Rarity = b.Rarity, SkinId = useSkin and skinFor(b.BladeId) or nil, Scale = 2.1, Anchored = true, WithAura = true })
			ModelBuilder.addSpinTrail(m, RarityData.Tiers[b.Rarity].Color)
			m.Parent = Workspace
			m:PivotTo(CFrame.new(ARENA + Vector3.new(baseX, 22, offs[i])))
			table.insert(models, m)
		end
		return models
	end
	local mineModels = build(sides.mine.Blades, -7, true)
	local foeModels = build(sides.foe.Blades, 7, false)

	local spinner = makeSpinner()
	for _, m in mineModels do spinner.add(m, 30) end
	for _, m in foeModels do spinner.add(m, -30) end

	local cam = makeCameraDirector()
	local overlay, fillMine, fillFoe, roundLabel = buildOverlay(gui, sides.mine.Name, sides.foe.Name)
	setBar(fillMine, 1); setBar(fillFoe, 1)

	local function moveGroup(models: { Model }, x: number, time: number)
		for _, m in models do
			local z = m:GetPivot().Position.Z
			task.spawn(function() moveTo(m, ARENA + Vector3.new(x, 0, z), time) end)
		end
		task.wait(time)
	end

	-- Phase 1: countdown (low dramatic angle on hovering blades).
	cam.set(CFrame.new(ARENA + Vector3.new(0, -2, 30), ARENA + Vector3.new(0, 16, 0)), true)
	cam.set(CFrame.new(ARENA + Vector3.new(0, 0, 26), ARENA + Vector3.new(0, 14, 0)), false, 2)
	for _, n in { "3", "2", "1" } do
		bigText(gui, n, UITheme.Color.Accent, 0.55)
		Sound.play("Clash", 0.3)
		task.wait(0.62)
	end
	bigText(gui, "¡LET IT RIP!", UITheme.Color.Bolts, 1.1)
	Sound.play("Launch", 0.8)

	-- Phase 2: launch drop with flash.
	flash(UITheme.Color.Accent, 0.5)
	Sound.startLoop("Spin", 0.35)
	cam.set(CFrame.new(ARENA + Vector3.new(0, 16, 40), ARENA), false, 8)
	task.spawn(function() moveGroup(mineModels, -7, 0.55) end)
	moveGroup(foeModels, 7, 0.55)
	impact(ARENA, UITheme.Color.Accent, false)
	task.wait(0.25)

	-- Phase 3: rounds.
	cam.orbit(ARENA, 30, 18, 0.5)
	local total = #rounds
	for idx, round in rounds do
		local isFinal = idx == total
		roundLabel.Text = ("RONDA %d"):format(round.Index)
		local dur = Config.Battle.RoundDuration * (isFinal and 1.7 or 1)

		-- Dash to centre.
		if isFinal then
			-- Slow-motion finisher: close push-in.
			cam.set(CFrame.new(ARENA + Vector3.new(round.Winner == 1 and -10 or 10, 3, 14), ARENA), false, 1.6)
		else
			cam.set(CFrame.new(ARENA + Vector3.new((idx % 2 == 0) and 13 or -13, 7, 17), ARENA), false, 9)
		end
		task.spawn(function() moveGroup(mineModels, -1.6, dur * 0.4) end)
		moveGroup(foeModels, 1.6, dur * 0.4)

		-- Clash!
		local crit = round.Crit
		impact(ARENA, crit and UITheme.Color.Bolts or UITheme.Color.Accent, crit or isFinal)
		cam.shake(crit and 3.2 or (isFinal and 2.6 or 1.8))
		flash(crit and UITheme.Color.Bolts or UITheme.Color.Accent, crit and 0.55 or 0.3)
		Sound.play("Clash", crit and 1 or 0.6)
		if round.Dodge then
			roundLabel.Text = "¡ESQUIVA!"
		elseif round.Winner ~= 0 then
			roundLabel.Text = round.Winner == 1 and "¡PUNTO AZUL!" or "¡PUNTO ROJO!"
		end

		-- Drain bars to match the log.
		setBar(fillMine, sumList(round.StaminaMine) / mineMax)
		setBar(fillFoe, sumList(round.StaminaFoe) / foeMax)

		-- Recoil out (unless final).
		if not isFinal then
			task.spawn(function() moveGroup(mineModels, -7, dur * 0.4) end)
			moveGroup(foeModels, 7, dur * 0.4)
			cam.orbit(ARENA, 30, 18, 0.5)
		end
		task.wait(dur * (isFinal and 0.5 or 0.2))
	end

	-- Phase 4: result.
	roundLabel.Text = ""
	Sound.stopLoop("Spin")
	local winnerModels = mineWon and mineModels or foeModels
	local loserModels = mineWon and foeModels or mineModels
	local winnerColor = RarityData.Tiers[(mineWon and sides.mine.Blades or sides.foe.Blades)[1].Rarity].Color

	-- Loser flies out + smoke.
	for _, m in loserModels do
		spinner.setSpeed(m, 5)
		spinner.setLean(m, 24)
		smokeOut(m)
		local p = m:GetPivot().Position
		task.spawn(function() moveTo(m, p + Vector3.new((p.X >= 0 and 1 or -1) * 26, -5, 0), 1.0) end)
	end
	-- Winner celebration.
	for _, m in winnerModels do
		spinner.setSpeed(m, 55)
	end
	victoryBeam(ARENA, winnerColor)
	cam.set(CFrame.new(ARENA + Vector3.new(0, 14, 38), ARENA + Vector3.new(0, 4, 0)), false, 3)
	flash(Color3.new(1, 1, 1), 0.5)

	if opts.spectator then
		local winName = mineWon and sides.mine.Name or sides.foe.Name
		local banner = UITheme.frame({ Size = UDim2.new(0, 460, 0, 110), Position = UDim2.new(0.5, -230, 0.5, -180), BackgroundColor3 = UITheme.Color.Panel, ZIndex = 47 }, gui)
		UITheme.corner(16, banner)
		UITheme.stroke(UITheme.Color.Accent, 3, banner)
		UITheme.label({ Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 18), Text = "👁️ ESPECTANDO", TextColor3 = UITheme.Color.Accent, TextSize = 26, ZIndex = 48 }, banner)
		UITheme.label({ Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 60), Text = ("Ganador: %s 🏆"):format(winName), TextSize = 20, TextColor3 = UITheme.Color.Good, ZIndex = 48 }, banner)
		task.delay(3.2, function() banner:Destroy() end)
	else
		Sound.play(mineWon and "Victory" or "Defeat", 0.85)
		resultBanner(gui, mineWon, opts.rewards)
	end
	task.wait(3.2)

	-- Cleanup.
	closeLetterbox()
	cam.stop()
	spinner.stop()
	for _, m in mineModels do m:Destroy() end
	for _, m in foeModels do m:Destroy() end
	overlay:Destroy()
	for _, child in gui:GetChildren() do
		if child.Name == "Flash" then child:Destroy() end
	end
	camera.CameraType = prevType
	MusicController.setBattle(false)
	playing = false
end

-- ===== Public: 1v1 ====================================================
function BattleView.play(result: any, youAre: number, _opponentName: string, rewards: any, gui: ScreenGui)
	if playing then return end
	local mine = (youAre == 1) and result.A or result.B
	local foe = (youAre == 1) and result.B or result.A
	local rounds = {}
	for _, r in result.Rounds do
		local wMine = (r.Winner == youAre) and 1 or (r.Winner == 0 and 0 or 2)
		table.insert(rounds, {
			Index = r.Index, Winner = wMine, Crit = r.Crit, Dodge = r.Dodge,
			StaminaMine = { (youAre == 1) and r.StaminaA or r.StaminaB },
			StaminaFoe = { (youAre == 1) and r.StaminaB or r.StaminaA },
		})
	end
	local sides = {
		mine = { Name = "TÚ", Blades = { mine } },
		foe = { Name = _opponentName or "Rival", Blades = { foe } },
	}
	runCinematic(sides, rounds, result.Winner == youAre, gui, { rewards = rewards, spectator = false })
end

-- ===== Public: 2v2 / spectator ========================================
function BattleView.playTeam(payload: any, youTeam: number, rewards: any?, gui: ScreenGui, spectator: boolean?)
	if playing then return end
	local mineSide = (youTeam == 1) and payload.SideA or payload.SideB
	local foeSide = (youTeam == 1) and payload.SideB or payload.SideA
	local rounds = {}
	for _, r in payload.Rounds do
		local wMine = (r.Winner == youTeam) and 1 or (r.Winner == 0 and 0 or 2)
		table.insert(rounds, {
			Index = r.Index, Winner = wMine, Crit = r.Crit, Dodge = r.Dodge,
			StaminaMine = (youTeam == 1) and r.StaminaA or r.StaminaB,
			StaminaFoe = (youTeam == 1) and r.StaminaB or r.StaminaA,
		})
	end
	local sides = {
		mine = { Name = spectator and (mineSide.Name or "Equipo A") or "TU EQUIPO", Blades = mineSide.Blades },
		foe = { Name = foeSide.Name or "Rivales", Blades = foeSide.Blades },
	}
	runCinematic(sides, rounds, payload.Winner == youTeam, gui, { rewards = rewards or { Bolts = 0, Cores = 0 }, spectator = spectator == true })
end

return BattleView
