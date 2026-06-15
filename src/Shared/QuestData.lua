--!strict
-- QuestData.lua — daily quest templates. The server rolls a random subset each
-- day and tracks progress via gameplay events.

export type QuestTemplate = {
	Id: string,
	Type: string, -- event key reported by gameplay: "collect" | "win" | "battle" | "prestige" | "spend_cores"
	Desc: string, -- %d is replaced with the target
	Targets: { number }, -- possible target values (one chosen at roll time)
	Bolts: number, -- reward per unit-ish (scaled by target tier)
	Cores: number,
}

local QuestData = {}

QuestData.Templates = {
	{ Id = "collect_blades", Type = "collect", Desc = "Recolecta %d Beyblades", Targets = { 5, 10, 15 }, Bolts = 300, Cores = 2 },
	{ Id = "win_battles", Type = "win", Desc = "Gana %d batallas", Targets = { 3, 5, 8 }, Bolts = 400, Cores = 3 },
	{ Id = "play_battles", Type = "battle", Desc = "Juega %d batallas", Targets = { 5, 8, 12 }, Bolts = 250, Cores = 2 },
	{ Id = "prestige_blade", Type = "prestige", Desc = "Asciende %d Beyblade(s)", Targets = { 1, 2 }, Bolts = 500, Cores = 4 },
	{ Id = "spend_cores", Type = "spend_cores", Desc = "Gasta %d Núcleos en la tienda", Targets = { 40, 90 }, Bolts = 600, Cores = 0 },
} :: { QuestTemplate }

QuestData.DailyCount = 3 -- quests generated per day

return QuestData
