--!strict
-- Net.lua
-- Centralised remote definitions. The server calls Net.init() once to create
-- the RemoteEvents / RemoteFunctions under ReplicatedStorage. Clients call
-- Net.get(name) to fetch them (waiting until they exist).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

-- name -> "Event" | "Function"
Net.Definitions = {
	-- Client -> Server (Functions return data)
	RequestProfile = "Function", -- () -> profile snapshot
	StartBattle = "Function", -- (bladeId) -> { queued=true } | result
	BuySkin = "Function", -- (skinId) -> { ok, reason? }
	EquipBlade = "Function", -- (bladeId) -> ok
	EquipSkin = "Function", -- (bladeId, skinId) -> ok
	ClaimDaily = "Function", -- () -> { ok, reward? }
	PrestigeBlade = "Function", -- (bladeId) -> ok  (fuse duplicates to upgrade rarity)
	GetLeaderboard = "Function", -- (board) -> sorted top list
	RedeemCode = "Function", -- (code) -> { ok, reason?, reward? }
	ClaimQuest = "Function", -- (questId) -> { ok, reward? }
	SaveSettings = "Function", -- (settings) -> ok
	OpenCrate = "Function", -- (crateId) -> { ok, bladeId?, rarity?, reason? }
	CompleteTutorial = "Function", -- () -> { ok, reward? }
	ClaimSeasonReward = "Function", -- (tier, track) -> { ok, reward? }
	BuyPremiumPass = "Function", -- () -> { ok, reason? }
	StartTeamBattle = "Function", -- () -> { ok, matched? }  (2v2)
	SpectateBattle = "Function", -- () -> live battle payload | { ok=false }
	AttackBoss = "Function", -- () -> { ok, damage?, hp?, maxHp?, reason? }

	-- Server -> Client (Events)
	ProfileUpdated = "Event", -- (profile)
	BattleResult = "Event", -- (result, youAre, opponentName, rewards)
	TeamBattleResult = "Event", -- (payload, youTeam, rewards)  (2v2)
	BossUpdate = "Event", -- (state) world boss broadcast
	Notify = "Event", -- (text, kind)
	SpawnCollected = "Event", -- (bladeId, rarity)  feedback popup
}

local FOLDER_NAME = "BeybladeRemotes"

function Net.init()
	assert(RunService:IsServer(), "Net.init must run on the server")
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for name, kind in Net.Definitions do
		if not folder:FindFirstChild(name) then
			local inst = Instance.new(kind == "Function" and "RemoteFunction" or "RemoteEvent")
			inst.Name = name
			inst.Parent = folder
		end
	end
	return folder
end

local cache: { [string]: Instance } = {}

function Net.get(name: string): Instance
	if cache[name] then
		return cache[name]
	end
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME, 30)
	assert(folder, "BeybladeRemotes folder never appeared")
	local inst = folder:WaitForChild(name, 30)
	assert(inst, "remote not found: " .. name)
	cache[name] = inst
	return inst
end

return Net
