--!strict
-- SpawnService.lua
-- Drops collectible beyblades into the hub on staggered "wave" timers. Each
-- spawn is a fully built 3D model the player walks up to and collects via a
-- ProximityPrompt. Rarer waves bias the rarity roll upward.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local BeybladeData = require(Shared.BeybladeData)
local RarityData = require(Shared.RarityData)
local ModelBuilder = require(Shared.ModelBuilder)

local DataService = require(script.Parent.DataService)
local BeybladeService = require(script.Parent.BeybladeService)
local EconomyService = require(script.Parent.EconomyService)

local SpawnService = {}

local rng = Random.new()
local container: Folder
local hubCenter = Vector3.new(0, 4, -120) -- collection garden, set by Hub
local active: { [Model]: { born: number } } = {}
local activeCount = 0

local function randomPosition(): Vector3
	local r = Config.Spawning.Radius * math.sqrt(rng:NextNumber())
	local theta = rng:NextNumber(0, math.pi * 2)
	return hubCenter + Vector3.new(math.cos(theta) * r, 0, math.sin(theta) * r)
end

local function collect(model: Model, player: Player)
	if not active[model] then
		return
	end
	active[model] = nil
	activeCount -= 1

	local bladeId = model:GetAttribute("BladeId") :: string
	local rarity = model:GetAttribute("Rarity") :: string
	BeybladeService.grant(player, bladeId, rarity)

	local bolts = Config.Rewards.CollectBolts[rarity] or 0
	local cores = Config.Rewards.CollectCores[rarity] or 0
	if bolts > 0 then
		EconomyService.add(player, "Bolts", bolts, true)
	end
	if cores > 0 then
		EconomyService.add(player, "Cores", cores, true)
	end

	(Net.get("SpawnCollected") :: RemoteEvent):FireClient(player, bladeId, rarity)

	-- Quick collect burst, then remove.
	model:Destroy()
end

local function createSpawn(bias: number)
	if activeCount >= Config.Spawning.MaxActiveSpawns then
		return
	end
	local rarity = RarityData.roll(bias, rng)
	local ids = BeybladeData.allIds()
	local bladeId = ids[rng:NextInteger(1, #ids)]

	local model = ModelBuilder.build({
		BladeId = bladeId,
		Rarity = rarity,
		Scale = 1.4,
		Anchored = true,
		WithAura = true,
	})
	model:PivotTo(CFrame.new(randomPosition()))
	model.Parent = container

	-- Floating pedestal light + collect prompt.
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Recolectar"
	prompt.ObjectText = ("%s · %s"):format(BeybladeData.get(bladeId).Name, RarityData.Tiers[rarity].Name)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(player)
		if DataService.isLoaded(player) then
			collect(model, player)
		end
	end)

	active[model] = { born = os.clock() }
	activeCount += 1
end

-- Animate floating + spinning for all active spawns.
local function animate(dt: number)
	local now = os.clock()
	for model, info in active do
		if model.Parent and model.PrimaryPart then
			local age = now - info.born
			local bob = math.sin(age * 2) * 0.4
			local base = model.PrimaryPart.Position
			model:PivotTo(
				CFrame.new(base.X, hubCenter.Y + 2 + bob, base.Z)
					* CFrame.Angles(0, now * 3, math.rad(90))
			)
		end
		-- Despawn timer.
		if now - info.born > Config.Spawning.DespawnAfter then
			active[model] = nil
			activeCount -= 1
			model:Destroy()
		end
	end
end

function SpawnService.setCenter(center: Vector3)
	hubCenter = center
end

function SpawnService.init()
	container = Instance.new("Folder")
	container.Name = "WorldSpawns"
	container.Parent = Workspace

	-- One scheduler loop per configured wave.
	for _, wave in Config.Spawning.Waves do
		task.spawn(function()
			-- Stagger initial drops so the hub isn't empty on launch.
			task.wait(rng:NextNumber(2, math.min(wave.Every, 15)))
			while true do
				for _ = 1, wave.Amount do
					createSpawn(wave.Bias)
				end
				task.wait(wave.Every)
			end
		end)
	end

	RunService.Heartbeat:Connect(animate)
end

return SpawnService
