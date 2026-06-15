--!strict
-- QuestService.lua — daily quests. Rolls a fresh set each calendar day and
-- advances progress from gameplay events reported by the other services.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local QuestData = require(Shared.QuestData)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local QuestService = {}

local rng = Random.new()

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

local function today(): number
	return math.floor(os.time() / 86400)
end

-- Roll DailyCount distinct quests for today.
local function roll()
	local pool = table.clone(QuestData.Templates)
	-- shuffle
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local list = {}
	for i = 1, math.min(QuestData.DailyCount, #pool) do
		local tmpl = pool[i]
		local tierIndex = rng:NextInteger(1, #tmpl.Targets)
		local target = tmpl.Targets[tierIndex]
		local scale = 1 + (tierIndex - 1) * 0.5
		table.insert(list, {
			Id = tmpl.Id,
			Type = tmpl.Type,
			Desc = string.format(tmpl.Desc, target),
			Target = target,
			Progress = 0,
			Bolts = math.floor(tmpl.Bolts * scale),
			Cores = math.floor(tmpl.Cores * scale),
			Claimed = false,
		})
	end
	return list
end

-- Make sure the player has today's quests (regenerates on a new day).
function QuestService.ensureDaily(player: Player)
	local p = DataService.get(player)
	if not p then
		return
	end
	if p.Quests.Day ~= today() or #p.Quests.List == 0 then
		p.Quests.Day = today()
		p.Quests.List = roll()
		DataService.push(player)
	end
end

-- Advance any matching, unclaimed, incomplete quests.
function QuestService.report(player: Player, eventType: string, amount: number?)
	local p = DataService.get(player)
	if not p then
		return
	end
	local changed = false
	for _, q in p.Quests.List do
		if q.Type == eventType and not q.Claimed and q.Progress < q.Target then
			q.Progress = math.min(q.Target, q.Progress + (amount or 1))
			changed = true
			if q.Progress >= q.Target then
				notify(player, ("✅ Misión completada: %s"):format(q.Desc), "success")
			end
		end
	end
	if changed then
		DataService.push(player)
	end
end

function QuestService.claim(player: Player, questId: string): any
	local p = DataService.get(player)
	if not p then
		return { ok = false }
	end
	for _, q in p.Quests.List do
		if q.Id == questId then
			if q.Claimed then
				return { ok = false, reason = "claimed" }
			end
			if q.Progress < q.Target then
				return { ok = false, reason = "incomplete" }
			end
			q.Claimed = true
			EconomyService.add(player, "Bolts", q.Bolts, true)
			if q.Cores > 0 then
				EconomyService.add(player, "Cores", q.Cores, true)
			end
			DataService.push(player)
			notify(player, ("🎁 +%d Tuercas, +%d Núcleos"):format(q.Bolts, q.Cores), "currency")
			return { ok = true, reward = { Bolts = q.Bolts, Cores = q.Cores } }
		end
	end
	return { ok = false, reason = "not_found" }
end

return QuestService
