--!strict
-- DataService.lua
-- Authoritative player profile store. Loads on join (with retries + template
-- merge), autosaves on an interval, saves on leave and on shutdown.
--
-- NOTE: For a production launch consider swapping the raw DataStore calls for
-- ProfileService/ProfileStore (session locking prevents item duplication on
-- server hops). The API below is intentionally small so that swap is easy.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local template = require(script.Parent.ProfileTemplate)

local DataService = {}

local STORE_NAME = "BeybladeProfiles_v1"
local store = DataStoreService:GetDataStore(STORE_NAME)
local useStudioMock = RunService:IsStudio() -- avoid DataStore errors in solo test

local profiles: { [Player]: any } = {}
local loadedFlag: { [Player]: boolean } = {}

-- Recursively fill missing keys from the template (never overwrite existing).
local function reconcile(data: any, tmpl: any)
	for k, v in tmpl do
		if data[k] == nil then
			data[k] = Util.deepCopy(v)
		elseif typeof(v) == "table" and typeof(data[k]) == "table" then
			reconcile(data[k], v)
		end
	end
end

local function keyFor(player: Player): string
	return "player_" .. tostring(player.UserId)
end

local function loadFromStore(player: Player): any
	if useStudioMock then
		return template()
	end
	local data
	for attempt = 1, 4 do
		local ok, result = pcall(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			data = result
			break
		else
			warn(("[DataService] load attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(result)))
			task.wait(2 ^ attempt)
		end
	end
	if data == nil then
		data = template()
	else
		reconcile(data, template())
	end
	return data
end

local function saveToStore(player: Player)
	local data = profiles[player]
	if not data or useStudioMock then
		return
	end
	data.LastSeenUnix = os.time()
	for attempt = 1, 4 do
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function()
				return data
			end)
		end)
		if ok then
			return
		end
		warn(("[DataService] save attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(err)))
		task.wait(2 ^ attempt)
	end
end

-- ===== Public API =====================================================

function DataService.get(player: Player): any?
	return profiles[player]
end

function DataService.isLoaded(player: Player): boolean
	return loadedFlag[player] == true
end

-- Build a client-safe snapshot (currently the whole profile is safe).
function DataService.snapshot(player: Player): any?
	local p = profiles[player]
	if not p then
		return nil
	end
	return Util.deepCopy(p)
end

-- Other services can react whenever a profile is pushed (e.g. to refresh
-- leaderstats) without DataService depending on them.
local pushListeners: { (Player) -> () } = {}
function DataService.onPush(fn: (Player) -> ())
	table.insert(pushListeners, fn)
end

-- Push the latest profile to the owning client.
function DataService.push(player: Player)
	local snap = DataService.snapshot(player)
	if snap then
		(Net.get("ProfileUpdated") :: RemoteEvent):FireClient(player, snap)
	end
	for _, fn in pushListeners do
		task.spawn(fn, player)
	end
end

function DataService.load(player: Player)
	local data = loadFromStore(player)
	if data.FirstJoinUnix == 0 then
		data.FirstJoinUnix = os.time()
	end
	profiles[player] = data
	loadedFlag[player] = true
	return data
end

function DataService.save(player: Player)
	saveToStore(player)
end

function DataService.release(player: Player)
	saveToStore(player)
	profiles[player] = nil
	loadedFlag[player] = nil
end

function DataService.init()
	-- Autosave loop.
	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)
			for player in profiles do
				task.spawn(saveToStore, player)
			end
		end
	end)

	game:BindToClose(function()
		if useStudioMock then
			return
		end
		for player in profiles do
			task.spawn(saveToStore, player)
		end
		task.wait(3)
	end)
end

return DataService
