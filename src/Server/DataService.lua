--!strict
-- DataService.lua
-- Authoritative player profile store with SESSION LOCKING — the core safety
-- mechanism behind ProfileService/ProfileStore, implemented directly on top of
-- DataStoreService so there are no external dependencies.
--
-- Why locking matters: when a player hops between servers (or rejoins fast),
-- two servers can briefly hold the same profile. Without a lock, the older
-- server's save can overwrite the newer one and DUPLICATE or ERASE items. Here,
-- each load stamps a unique session lock + heartbeat; another server only takes
-- over once the lock goes stale, and a server that loses its lock stops saving.
--
-- Stored shape per key: { data = <profile>, lock = { session, jobId, beat } }

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local template = require(script.Parent.ProfileTemplate)

local DataService = {}

local STORE_NAME = "BeybladeProfiles_v2"
local useStudioMock = RunService:IsStudio() -- avoid DataStore errors in solo test

-- Lazy DataStore handle: GetDataStore throws in an unpublished place, and we
-- never touch the store in Studio (mock), so only fetch it on real use.
local store: DataStore? = nil
local function getStore(): DataStore
	if not store then
		store = DataStoreService:GetDataStore(STORE_NAME)
	end
	return store :: DataStore
end

-- A lock older than this (seconds) is considered dead and may be stolen.
local LOCK_TIMEOUT = 60
-- How often we refresh our lock heartbeat + autosave.
local HEARTBEAT = math.min(Config.AutoSaveInterval, 30)
-- Attempts to acquire before force-stealing a (presumably crashed) lock.
local ACQUIRE_ATTEMPTS = 6

local profiles: { [Player]: any } = {}
local sessions: { [Player]: string } = {}
local loadedFlag: { [Player]: boolean } = {}
local releasing: { [Player]: boolean } = {}

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

-- ===== Locked DataStore primitives ====================================

-- Try to acquire the session lock and read the profile. Returns (data, ok).
local function acquire(player: Player, sessionId: string): (any?, boolean)
	if useStudioMock then
		return template(), true
	end
	local key = keyFor(player)
	for attempt = 1, ACQUIRE_ATTEMPTS do
		local steal = attempt == ACQUIRE_ATTEMPTS -- last resort: take a stale/stuck lock
		local got = false
		local loaded: any = nil
		local ok, err = pcall(function()
			getStore():UpdateAsync(key, function(stored)
				stored = stored or { data = nil, lock = nil }
				local lock = stored.lock
				local now = os.time()
				local free = (not lock)
					or (now - (lock.beat or 0) > LOCK_TIMEOUT)
					or (lock.session == sessionId)
				if free or steal then
					stored.lock = { session = sessionId, jobId = game.JobId, beat = now }
					got = true
					loaded = stored.data
					return stored
				end
				-- Locked by a live session: cancel, keep their data untouched.
				got = false
				return nil
			end)
		end)
		if ok and got then
			local data = loaded or template()
			reconcile(data, template())
			return data, true
		elseif not ok then
			warn(("[DataService] acquire attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(err)))
		end
		task.wait(3)
	end
	return nil, false
end

-- Write current data and refresh our heartbeat, but only if we still own the
-- lock. Returns false if the lock was lost (another server took over).
local function commit(player: Player, finalize: boolean): boolean
	local data = profiles[player]
	local sessionId = sessions[player]
	if not data or not sessionId or useStudioMock then
		return true
	end
	data.LastSeenUnix = os.time()
	local owned = true
	local ok, err = pcall(function()
		getStore():UpdateAsync(keyFor(player), function(stored)
			stored = stored or { data = nil, lock = nil }
			local lock = stored.lock
			-- Only write if we own the lock (or it's gone stale and ours).
			if lock and lock.session ~= sessionId and (os.time() - (lock.beat or 0) <= LOCK_TIMEOUT) then
				owned = false
				return nil -- someone else owns a live lock; don't clobber it
			end
			stored.data = data
			if finalize then
				stored.lock = nil -- release on leave
			else
				stored.lock = { session = sessionId, jobId = game.JobId, beat = os.time() }
			end
			return stored
		end)
	end)
	if not ok then
		warn(("[DataService] commit failed for %s: %s"):format(player.Name, tostring(err)))
		return true -- transient error; keep the session, retry next beat
	end
	return owned
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

-- Push the latest profile to the owning client. Pushes are COALESCED: gameplay
-- code often mutates the profile several times in one moment (battle rewards =
-- currency + XP + quests + history), so we batch them into a single snapshot,
-- FireClient and listener pass per frame instead of ~8.
local pendingPush: { [Player]: boolean } = {}

local function flushPush(player: Player)
	pendingPush[player] = nil
	local snap = DataService.snapshot(player)
	if snap then
		(Net.get("ProfileUpdated") :: RemoteEvent):FireClient(player, snap)
	end
	for _, fn in pushListeners do
		task.spawn(fn, player)
	end
end

function DataService.push(player: Player)
	if pendingPush[player] then
		return
	end
	pendingPush[player] = true
	task.defer(flushPush, player)
end

-- Acquire the lock and load the profile. Returns the profile, or nil if the
-- lock could not be obtained (caller should kick the player).
function DataService.load(player: Player): any?
	local sessionId = HttpService:GenerateGUID(false)
	local data, ok = acquire(player, sessionId)
	if not ok or not data then
		return nil
	end
	if data.FirstJoinUnix == 0 then
		data.FirstJoinUnix = os.time()
	end
	profiles[player] = data
	sessions[player] = sessionId
	loadedFlag[player] = true
	return data
end

function DataService.save(player: Player)
	commit(player, false)
end

function DataService.release(player: Player)
	if releasing[player] then
		return
	end
	releasing[player] = true
	commit(player, true) -- final save + clear lock
	profiles[player] = nil
	sessions[player] = nil
	loadedFlag[player] = nil
	releasing[player] = nil
end

function DataService.init()
	-- Heartbeat: refresh locks + autosave. If a lock is lost, kick to protect
	-- data integrity (another server now owns the profile).
	task.spawn(function()
		while true do
			task.wait(HEARTBEAT)
			for player in profiles do
				task.spawn(function()
					local stillOwned = commit(player, false)
					if not stillOwned and player.Parent then
						warn(("[DataService] lost lock for %s — kicking to protect data"):format(player.Name))
						profiles[player] = nil
						sessions[player] = nil
						loadedFlag[player] = nil
						player:Kick("Tu sesión se abrió en otro servidor. Vuelve a entrar.")
					end
				end)
			end
		end
	end)

	game:BindToClose(function()
		if useStudioMock then
			return
		end
		local pending = {}
		for player in profiles do
			table.insert(pending, player)
		end
		for _, player in pending do
			task.spawn(DataService.release, player)
		end
		task.wait(5) -- give the writes time to flush before the server dies
	end)
end

return DataService
