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
		Stats = { Wins = 0, Losses = 0, Streak = 0, BestStreak = 0, Collected = 0, Battles = 0 },
		-- Daily login reward tracking.
		Daily = { LastClaimUnix = 0, Day = 0 },
		FirstJoinUnix = 0,
		LastSeenUnix = 0,
	}
end

return template
