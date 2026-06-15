--!strict
-- AchievementService.lua — unlocks achievements automatically whenever a
-- profile changes, grants their rewards once, and (if configured) awards a real
-- Roblox Badge. Registered as a DataService push listener so any stat change is
-- re-evaluated without explicit calls from gameplay code.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local AchievementData = require(Shared.AchievementData)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local AchievementService = {}

-- Guard against re-entrancy: granting a reward pushes the profile, which would
-- re-trigger the listener. We skip checks for a player already inside check().
local checking: { [Player]: boolean } = {}

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

local function awardBadge(player: Player, badgeId: number)
	if badgeId <= 0 then
		return
	end
	task.spawn(function()
		local ok, owns = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)
		if ok and not owns then
			pcall(function()
				BadgeService:AwardBadge(player.UserId, badgeId)
			end)
		end
	end)
end

function AchievementService.check(player: Player)
	if checking[player] then
		return
	end
	local p = DataService.get(player)
	if not p then
		return
	end
	checking[player] = true

	local unlockedAny = false
	for _, id in AchievementData.Order do
		local ach = AchievementData.get(id)
		if ach and not p.Achievements[id] then
			if AchievementData.metricValue(p, ach.Metric) >= ach.Threshold then
				p.Achievements[id] = true
				unlockedAny = true
				if ach.Bolts > 0 then
					EconomyService.add(player, "Bolts", ach.Bolts, true)
				end
				if ach.Cores > 0 then
					EconomyService.add(player, "Cores", ach.Cores, true)
				end
				awardBadge(player, ach.Badge)
				notify(player, ("🏅 ¡Logro: %s!"):format(ach.Name), "success")
			end
		end
	end

	checking[player] = false
	if unlockedAny then
		DataService.push(player)
	end
end

function AchievementService.init()
	DataService.onPush(AchievementService.check)
end

return AchievementService
