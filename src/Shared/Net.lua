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

	-- Server -> Client (Events)
	ProfileUpdated = "Event", -- (profile)
	BattleResult = "Event", -- (result, rewards, opponentName)
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
