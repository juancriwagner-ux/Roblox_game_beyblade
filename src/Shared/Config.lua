--!strict
-- Config.lua
-- Global tunables for Beyblade Arena. Designers can balance the whole game
-- from this single module without touching gameplay code.

local Config = {}

-- ===== Currencies =====================================================
Config.Currencies = {
	Bolts = {
		Id = "Bolts",
		Name = "Tuercas",
		Abbrev = "BLT",
		Color = Color3.fromRGB(255, 196, 0),
		Premium = false,
	},
	Cores = {
		Id = "Cores",
		Name = "Núcleos",
		Abbrev = "CORE",
		Color = Color3.fromRGB(0, 224, 255),
		Premium = true, -- exclusive currency used for developed skins
	},
}

-- ===== World spawning ==================================================
-- Collectible beyblades drop in the arena hub on staggered timers. Shorter
-- timers spit out common loot; long timers occasionally drop high rarity.
Config.Spawning = {
	MaxActiveSpawns = 14,
	Waves = {
		-- name, every (seconds), rarity weight bias, amount per wave
		{ Name = "Goteo", Every = 75, Bias = 0, Amount = 2 },
		{ Name = "Lluvia", Every = 360, Bias = 1, Amount = 3 },
		{ Name = "Tormenta", Every = 1800, Bias = 2, Amount = 2 }, -- every 30 min
		{ Name = "Eclipse", Every = 7200, Bias = 4, Amount = 1 }, -- every 2 h: chance at Mythic
	},
	-- How long an uncollected spawn stays in the world before despawning.
	DespawnAfter = 150,
	-- Radius (studs) around the hub center where loot can appear.
	Radius = 70,
}

-- ===== Economy / rewards ==============================================
Config.Rewards = {
	CollectBolts = { Common = 25, Uncommon = 45, Rare = 90, Epic = 180, Legendary = 400, Mythic = 1000 },
	CollectCores = { Common = 0, Uncommon = 0, Rare = 1, Epic = 3, Legendary = 8, Mythic = 25 },
	BattleWinBolts = 120,
	BattleLoseBolts = 35,
	BattleWinCores = 2,
	WinStreakBonusBolts = 40, -- per consecutive win, capped
	WinStreakCap = 10,
	Daily = {
		-- day index -> reward
		{ Bolts = 250, Cores = 2 },
		{ Bolts = 400, Cores = 3 },
		{ Bolts = 600, Cores = 4 },
		{ Bolts = 800, Cores = 6 },
		{ Bolts = 1200, Cores = 8 },
		{ Bolts = 1800, Cores = 12 },
		{ Bolts = 3000, Cores = 25 }, -- day 7 jackpot
	},
}

-- ===== Battle =========================================================
Config.Battle = {
	Rounds = 3, -- best-of; first to majority wins the match
	-- How much randomness vs. raw stat dominance (0 = pure stats, 1 = coin flip).
	Variance = 0.32,
	RoundDuration = 3.2, -- seconds the clash animation plays per round
	QueueTimeout = 6, -- seconds to wait for a human before spawning a bot
}

-- ===== Misc ===========================================================
Config.StartingInventory = { "ember_striker", "tide_guardian" } -- new players' first blades
Config.MaxInventory = 250
Config.AutoSaveInterval = 90

return Config
