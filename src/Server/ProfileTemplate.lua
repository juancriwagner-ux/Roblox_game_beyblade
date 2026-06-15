--!strict
-- ProfileTemplate.lua
-- Default shape of a player's saved profile. New keys added here are merged
-- into existing saves on load (forward-compatible).

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local function template()
	return {
		Version = 1,
		Currencies = {
			Bolts = 500,
			Cores = 5,
		},
		-- Inventory keyed by "bladeId|rarity" -> { BladeId, Rarity, Count }
		Inventory = {} :: { [string]: { BladeId: string, Rarity: string, Count: number } },
		-- Owned skins: skinId -> true
		Skins = { default = true } :: { [string]: boolean },
		-- Skin chosen per blade: bladeId -> skinId
		SkinByBlade = {} :: { [string]: string },
		-- Currently equipped loadout for battle.
		Equipped = { BladeId = Config.StartingInventory[1], Rarity = "Common" },
		-- Lifetime stats.
		Stats = { Wins = 0, Losses = 0, Streak = 0, BestStreak = 0, Collected = 0, Battles = 0, BossKills = 0 },
		-- Daily login reward tracking.
		Daily = { LastClaimUnix = 0, Day = 0 },
		-- Competitive ladder.
		Trophies = 0,
		PeakTrophies = 0,
		-- Progression.
		XP = 0,
		Level = 1,
		-- Daily quests: { Day = <unix day>, List = { {Id, Type, Target, Progress, Bolts, Cores, Claimed} } }
		Quests = { Day = 0, List = {} },
		-- Redeemed promo codes (codeId -> true).
		Codes = {} :: { [string]: boolean },
		-- Client settings.
		Settings = { Music = true, Sfx = true },
		-- First-time user experience flag.
		TutorialDone = false,
		-- Unlocked achievements (id -> true).
		Achievements = {} :: { [string]: boolean },
		-- Recent battle history (newest first, capped).
		History = {} :: { any },
		-- Battle Pass / season state.
		Season = {
			Id = 0,
			XP = 0,
			Tier = 0,
			Premium = false,
			ClaimedFree = {} :: { [string]: boolean }, -- tier (as string) -> true
			ClaimedPremium = {} :: { [string]: boolean },
		},
		FirstJoinUnix = 0,
		LastSeenUnix = 0,
	}
end

return template
