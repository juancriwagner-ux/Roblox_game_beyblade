--!strict
-- RewardService.lua — daily login streak rewards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local RewardService = {}

local DAY_SECONDS = 20 * 3600 -- a "day" unlocks after 20h, resets if >48h gap

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

-- How long until the player can claim again (0 = ready now).
function RewardService.cooldown(player: Player): number
	local p = DataService.get(player)
	if not p then
		return math.huge
	end
	local elapsed = os.time() - p.Daily.LastClaimUnix
	return math.max(0, DAY_SECONDS - elapsed)
end

function RewardService.claim(player: Player): any
	local p = DataService.get(player)
	if not p then
		return { ok = false }
	end
	local now = os.time()
	local elapsed = now - p.Daily.LastClaimUnix
	if elapsed < DAY_SECONDS then
		return { ok = false, reason = "cooldown", remaining = DAY_SECONDS - elapsed }
	end
	-- Continue streak if within 48h, else reset.
	if elapsed > DAY_SECONDS * 2.4 then
		p.Daily.Day = 0
	end
	p.Daily.Day = (p.Daily.Day % #Config.Rewards.Daily) + 1
	p.Daily.LastClaimUnix = now

	local reward = Config.Rewards.Daily[p.Daily.Day]
	EconomyService.add(player, "Bolts", reward.Bolts, true)
	EconomyService.add(player, "Cores", reward.Cores, true)
	DataService.push(player)
	notify(player, ("Día %d: +%d Tuercas, +%d Núcleos"):format(p.Daily.Day, reward.Bolts, reward.Cores), "success")
	return { ok = true, day = p.Daily.Day, reward = reward }
end

return RewardService
