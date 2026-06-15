--!strict
-- BossService.lua — server-wide cooperative World Boss event.
--
-- On a schedule a giant boss beyblade appears in the arena. Every player can
-- attack it (probabilistic damage from their equipped blade) against a shared
-- HP pool. When it dies, all contributors are rewarded by damage share; the top
-- damager gets a bonus + a guaranteed exclusive event blade. FOMO + co-op.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local BossData = require(Shared.BossData)
local BeybladeData = require(Shared.BeybladeData)
local ModelBuilder = require(Shared.ModelBuilder)

local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local BeybladeService = require(script.Parent.BeybladeService)

local BossService = {}

local BOSS_POS = Vector3.new(0, 16, 0)
local rng = Random.new()

local state = {
	Active = false,
	Name = BossData.Names[1],
	HP = 0,
	MaxHP = BossData.MaxHP,
	EndsAt = 0,
	NextAt = 0,
}
local contributions: { [Player]: number } = {}
local lastAttack: { [Player]: number } = {}
local model: Model? = nil
local spinConn: RBXScriptConnection? = nil
local sessionId = 0

local function broadcast()
	(Net.get("BossUpdate") :: RemoteEvent):FireAllClients({
		Active = state.Active,
		Name = state.Name,
		HP = math.floor(state.HP),
		MaxHP = state.MaxHP,
		EndsAt = state.EndsAt,
		NextAt = state.NextAt,
	})
end

local function buildModel()
	local m = ModelBuilder.build({ BladeId = BossData.BladeId, Rarity = "Mythic", Scale = 7, Anchored = true, WithAura = true })
	m.Name = "WorldBoss"
	m:PivotTo(CFrame.new(BOSS_POS))
	-- Floating name plate.
	local head = m.PrimaryPart
	if head then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 240, 0, 50)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
		bb.AlwaysOnTop = true
		bb.Parent = head
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextColor3 = Color3.fromRGB(255, 120, 64)
		lbl.TextStrokeTransparency = 0.3
		lbl.TextScaled = true
		lbl.Text = "👹 " .. state.Name
		lbl.Parent = bb
	end
	m.Parent = Workspace
	model = m

	-- Slow menacing spin while alive.
	local t0 = os.clock()
	spinConn = RunService.Heartbeat:Connect(function()
		if model and model.Parent then
			model:PivotTo(CFrame.new(BOSS_POS) * CFrame.Angles(0, (os.clock() - t0) * 1.2, math.rad(90)))
		end
	end)
end

local function clearModel()
	if spinConn then
		spinConn:Disconnect()
		spinConn = nil
	end
	if model then
		model:Destroy()
		model = nil
	end
end

local function rewardContributors()
	local total = 0
	local top: Player? = nil
	local topDmg = 0
	for player, dmg in contributions do
		total += dmg
		if dmg > topDmg then
			topDmg = dmg
			top = player
		end
	end
	if total <= 0 then
		return
	end
	for player, dmg in contributions do
		if not player.Parent then
			continue
		end
		local p = DataService.get(player)
		if not p then
			continue
		end
		local share = dmg / total
		local bolts = BossData.Rewards.BaseBolts + math.floor(share * BossData.Rewards.PoolBolts)
		local cores = BossData.Rewards.BaseCores + math.floor(share * BossData.Rewards.PoolCores)
		local isTop = (player == top)
		if isTop then
			bolts += BossData.Rewards.TopBonusBolts
			cores += BossData.Rewards.TopBonusCores
		end
		p.Stats.BossKills += 1
		EconomyService.add(player, "Bolts", bolts, true)
		EconomyService.add(player, "Cores", cores, true)

		-- Exclusive event blade drop.
		local gotBlade = false
		if isTop then
			BeybladeService.grant(player, BossData.BladeId, BossData.Rewards.TopDropRarity)
			gotBlade = true
		elseif rng:NextNumber() < BossData.Rewards.DropChance then
			BeybladeService.grant(player, BossData.BladeId, BossData.Rewards.DropRarity)
			gotBlade = true
		end
		DataService.push(player)

		local msg = ("🐲 ¡Jefe derrotado! +%d Tuercas, +%d Núcleos"):format(bolts, cores)
		if gotBlade then
			msg ..= " + ¡Inferno Titan!"
		end
		;(Net.get("Notify") :: RemoteEvent):FireClient(player, msg, "success")
	end
end

local function endBoss(defeated: boolean, mySession: number)
	if mySession ~= sessionId or not state.Active then
		return
	end
	state.Active = false
	clearModel()
	if defeated then
		rewardContributors()
		for _, player in Players:GetPlayers() do
			(Net.get("Notify") :: RemoteEvent):FireClient(player, ("⚔️ ¡%s ha sido derrotado por el servidor!"):format(state.Name), "success")
		end
	else
		for _, player in Players:GetPlayers() do
			(Net.get("Notify") :: RemoteEvent):FireClient(player, ("⏳ %s escapó... volverá pronto."):format(state.Name), "info")
		end
	end
	contributions = {}
	state.NextAt = os.time() + BossData.IdleBetween
	broadcast()
end

local function spawnBoss()
	sessionId += 1
	local mySession = sessionId
	state.Active = true
	state.Name = BossData.Names[rng:NextInteger(1, #BossData.Names)]
	state.HP = state.MaxHP
	state.EndsAt = os.time() + BossData.Duration
	contributions = {}
	buildModel()
	broadcast()
	for _, player in Players:GetPlayers() do
		(Net.get("Notify") :: RemoteEvent):FireClient(player, ("👹 ¡%s ha aparecido! ¡Atáquenlo juntos!"):format(state.Name), "error")
	end
	-- Flee timer if the server can't kill it in time.
	task.delay(BossData.Duration, function()
		endBoss(false, mySession)
	end)
end

-- Called from the AttackBoss RemoteFunction.
function BossService.attack(player: Player): any
	if not state.Active then
		return { ok = false, reason = "inactive" }
	end
	local now = os.clock()
	if lastAttack[player] and now - lastAttack[player] < BossData.AttackCooldown then
		return { ok = false, reason = "cooldown" }
	end
	lastAttack[player] = now

	local p = DataService.get(player)
	if not p then
		return { ok = false, reason = "no_profile" }
	end
	local eq = p.Equipped
	local power = BeybladeData.power(eq.BladeId, eq.Rarity)
	if power <= 0 then
		power = 100
	end
	local dmg = math.floor(power * rng:NextNumber(0.8, 1.4))
	state.HP = math.max(0, state.HP - dmg)
	contributions[player] = (contributions[player] or 0) + dmg

	if state.HP <= 0 then
		endBoss(true, sessionId)
	else
		broadcast()
	end
	return { ok = true, damage = dmg, hp = math.floor(state.HP), maxHp = state.MaxHP }
end

function BossService.cleanup(player: Player)
	contributions[player] = nil
	lastAttack[player] = nil
end

function BossService.init()
	-- First event comes quickly so a fresh server isn't empty; later events use
	-- the full idle interval.
	state.NextAt = os.time() + 90
	task.spawn(function()
		while true do
			-- Idle countdown to the next event.
			broadcast()
			local wait = math.max(1, state.NextAt - os.time())
			task.wait(wait)
			spawnBoss()
			-- Wait until the boss session ends (killed or fled).
			repeat
				task.wait(1)
			until not state.Active
		end
	end)
end

return BossService
