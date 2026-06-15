--!strict
-- AchievementData.lua — achievement catalog + a shared metric reader so client
-- and server compute progress identically. Each achievement maps to a lifetime
-- metric and a threshold; unlocking grants currency and (optionally) a real
-- Roblox Badge.

export type Achievement = {
	Id: string,
	Name: string,
	Desc: string,
	Metric: string,
	Threshold: number,
	Bolts: number,
	Cores: number,
	Badge: number, -- Roblox BadgeId (0 = none; paste your IDs to award badges)
	Icon: string,
}

local AchievementData = {}

AchievementData.Order = {
	"first_win", "wins_10", "wins_50", "wins_200",
	"streak_5", "streak_10",
	"collect_25", "collect_100", "collector_10",
	"gold_league", "diamond_league",
	"level_10", "battles_100", "fashionista",
}

AchievementData.List = {
	first_win = { Id = "first_win", Name = "Primera Sangre", Desc = "Gana tu primera batalla", Metric = "wins", Threshold = 1, Bolts = 200, Cores = 0, Badge = 0, Icon = "⚔️" },
	wins_10 = { Id = "wins_10", Name = "Retador", Desc = "Gana 10 batallas", Metric = "wins", Threshold = 10, Bolts = 400, Cores = 2, Badge = 0, Icon = "⚔️" },
	wins_50 = { Id = "wins_50", Name = "Veterano", Desc = "Gana 50 batallas", Metric = "wins", Threshold = 50, Bolts = 1000, Cores = 5, Badge = 0, Icon = "🗡️" },
	wins_200 = { Id = "wins_200", Name = "Imparable", Desc = "Gana 200 batallas", Metric = "wins", Threshold = 200, Bolts = 3000, Cores = 15, Badge = 0, Icon = "🔥" },
	streak_5 = { Id = "streak_5", Name = "En Racha", Desc = "Logra una racha de 5 victorias", Metric = "best_streak", Threshold = 5, Bolts = 500, Cores = 3, Badge = 0, Icon = "✨" },
	streak_10 = { Id = "streak_10", Name = "Invencible", Desc = "Logra una racha de 10 victorias", Metric = "best_streak", Threshold = 10, Bolts = 1500, Cores = 8, Badge = 0, Icon = "💫" },
	collect_25 = { Id = "collect_25", Name = "Coleccionista", Desc = "Recolecta 25 Beyblades", Metric = "collected", Threshold = 25, Bolts = 300, Cores = 0, Badge = 0, Icon = "🌀" },
	collect_100 = { Id = "collect_100", Name = "Acaparador", Desc = "Recolecta 100 Beyblades", Metric = "collected", Threshold = 100, Bolts = 1200, Cores = 5, Badge = 0, Icon = "🌀" },
	collector_10 = { Id = "collector_10", Name = "Arsenal", Desc = "Posee 10 Beyblades distintos", Metric = "blades_owned", Threshold = 10, Bolts = 1000, Cores = 5, Badge = 0, Icon = "📚" },
	gold_league = { Id = "gold_league", Name = "Liga de Oro", Desc = "Alcanza 700 trofeos", Metric = "peak_trophies", Threshold = 700, Bolts = 800, Cores = 4, Badge = 0, Icon = "🥇" },
	diamond_league = { Id = "diamond_league", Name = "Diamante", Desc = "Alcanza 1900 trofeos", Metric = "peak_trophies", Threshold = 1900, Bolts = 2500, Cores = 12, Badge = 0, Icon = "💠" },
	level_10 = { Id = "level_10", Name = "Experimentado", Desc = "Llega al nivel 10", Metric = "level", Threshold = 10, Bolts = 600, Cores = 3, Badge = 0, Icon = "⭐" },
	battles_100 = { Id = "battles_100", Name = "Gladiador", Desc = "Juega 100 batallas", Metric = "battles", Threshold = 100, Bolts = 1500, Cores = 6, Badge = 0, Icon = "🏟️" },
	fashionista = { Id = "fashionista", Name = "Fashionista", Desc = "Posee 3 skins", Metric = "skins_owned", Threshold = 3, Bolts = 800, Cores = 0, Badge = 0, Icon = "🎨" },
} :: { [string]: Achievement }

function AchievementData.get(id: string): Achievement?
	return AchievementData.List[id]
end

-- Compute a metric value from a profile snapshot (used by client + server).
function AchievementData.metricValue(profile: any, metric: string): number
	if not profile then
		return 0
	end
	if metric == "wins" then
		return profile.Stats.Wins
	elseif metric == "battles" then
		return profile.Stats.Battles
	elseif metric == "best_streak" then
		return profile.Stats.BestStreak
	elseif metric == "collected" then
		return profile.Stats.Collected
	elseif metric == "peak_trophies" then
		return profile.PeakTrophies or 0
	elseif metric == "level" then
		return profile.Level or 1
	elseif metric == "skins_owned" then
		local n = 0
		for id in profile.Skins do
			if id ~= "default" then
				n += 1
			end
		end
		return n
	elseif metric == "blades_owned" then
		local n = 0
		for _ in profile.Inventory do
			n += 1
		end
		return n
	end
	return 0
end

return AchievementData
