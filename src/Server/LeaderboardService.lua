--!strict
-- LeaderboardService.lua — global ranking via OrderedDataStore. Tracks Trophies
-- and Wins; exposes a cached top-N list to clients. Updates are throttled and
-- best-effort (skipped entirely in Studio to avoid noisy errors).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)

local LeaderboardService = {}

local isStudio = RunService:IsStudio()

-- Lazy ordered-store handles (GetOrderedDataStore throws in an unpublished
-- place; we never call these in Studio, so fetch them only on real use).
local BOARD_NAMES = { Trophies = "LB_Trophies_v1", Wins = "LB_Wins_v1" }
local boardCache: { [string]: OrderedDataStore } = {}
local function getBoard(name: string): OrderedDataStore
	if not boardCache[name] then
		boardCache[name] = DataStoreService:GetOrderedDataStore(BOARD_NAMES[name])
	end
	return boardCache[name]
end

-- Cached top lists: board -> { {Name, Value, UserId} }
local cache: { [string]: { any } } = { Trophies = {}, Wins = {} }

local function refresh(board: string)
	if isStudio then
		return
	end
	local store = getBoard(board)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 50)
	end)
	if not ok then
		warn("[Leaderboard] refresh failed for " .. board .. ": " .. tostring(pages))
		return
	end
	local list = {}
	local ok2, top = pcall(function()
		return pages:GetCurrentPage()
	end)
	if ok2 then
		for _, entry in top do
			local userId = tonumber(entry.key)
			local name = "Jugador"
			local okName, fetched = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if okName then
				name = fetched
			end
			table.insert(list, { Name = name, Value = entry.value, UserId = userId })
		end
	end
	cache[board] = list
end

-- Push a player's current values to the ordered stores.
function LeaderboardService.update(player: Player)
	if isStudio then
		return
	end
	local p = DataService.get(player)
	if not p then
		return
	end
	local key = tostring(player.UserId)
	pcall(function()
		getBoard("Trophies"):SetAsync(key, math.max(0, math.floor(p.Trophies)))
	end)
	pcall(function()
		getBoard("Wins"):SetAsync(key, math.max(0, math.floor(p.Stats.Wins)))
	end)
end

function LeaderboardService.getTop(board: string): { any }
	return cache[board] or {}
end

function LeaderboardService.init()
	-- Periodic refresh of the cached boards.
	task.spawn(function()
		while true do
			refresh("Trophies")
			refresh("Wins")
			task.wait(60)
		end
	end)
	-- Flush each player's standings on leave.
	Players.PlayerRemoving:Connect(LeaderboardService.update)
	-- Periodic flush so the board reflects active players too.
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in Players:GetPlayers() do
				LeaderboardService.update(player)
			end
		end
	end)
end

return LeaderboardService
