--!strict
-- ProgressService.lua — player XP/level + in-game `leaderstats` (the values
-- Roblox shows in the player list). Keeps leaderstats in sync on every push.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local BeybladeData = require(Shared.BeybladeData)
local DataService = require(script.Parent.DataService)
local SeasonService = require(script.Parent.SeasonService)

local ProgressService = {}

-- Level curve: level 1 starts at 0 XP; each level needs level^2 * 100 total.
function ProgressService.levelForXP(xp: number): number
	return math.floor(math.sqrt(xp / 100)) + 1
end

function ProgressService.xpForLevel(level: number): number
	return (level - 1) ^ 2 * 100
end

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

function ProgressService.addXP(player: Player, amount: number)
	local p = DataService.get(player)
	if not p or amount <= 0 then
		return
	end
	p.XP += amount
	local newLevel = ProgressService.levelForXP(p.XP)
	if newLevel > p.Level then
		p.Level = newLevel
		notify(player, ("⭐ ¡Subiste a nivel %d!"):format(newLevel), "success")
	end
	DataService.push(player)
	-- Every XP gain also feeds the Battle Pass.
	SeasonService.addXP(player, amount)
end

-- Create the leaderstats folder shown in Roblox's player list.
function ProgressService.setupLeaderstats(player: Player)
	local existing = player:FindFirstChild("leaderstats")
	if existing then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local trophies = Instance.new("IntValue")
	trophies.Name = "🏆 Trofeos"
	trophies.Parent = folder

	local wins = Instance.new("IntValue")
	wins.Name = "Victorias"
	wins.Parent = folder

	local level = Instance.new("IntValue")
	level.Name = "Nivel"
	level.Parent = folder

	folder.Parent = player
end

-- Mirror profile values into leaderstats. Registered as a push listener.
function ProgressService.sync(player: Player)
	local p = DataService.get(player)
	local stats = player:FindFirstChild("leaderstats")
	if not p or not stats then
		return
	end
	local t = stats:FindFirstChild("🏆 Trofeos") :: IntValue?
	local w = stats:FindFirstChild("Victorias") :: IntValue?
	local l = stats:FindFirstChild("Nivel") :: IntValue?
	if t then t.Value = p.Trophies end
	if w then w.Value = p.Stats.Wins end
	if l then l.Value = p.Level end
end

function ProgressService.init()
	DataService.onPush(ProgressService.sync)
end

return ProgressService
