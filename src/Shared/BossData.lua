--!strict
-- BossData.lua — World Boss event tuning. Shared so the client can label and
-- format the boss banner without extra round-trips.

local BossData = {}

BossData.IdleBetween = 480 -- seconds between events (countdown shown to players)
BossData.Duration = 240 -- seconds the boss stays up before it flees
BossData.MaxHP = 45000 -- shared HP pool for the whole server
BossData.AttackCooldown = 1.0 -- seconds between a player's attacks
BossData.BladeId = "inferno_titan" -- boss visual model + rare drop

BossData.Names = { "Inferno Titan", "Coloso Abisal", "Devorador de Mundos", "Goliat Tormenta" }

BossData.Rewards = {
	BaseBolts = 300, -- everyone who participated
	BaseCores = 2,
	PoolBolts = 10000, -- split by damage share
	PoolCores = 80,
	TopBonusBolts = 3000, -- #1 damage dealer
	TopBonusCores = 20,
	-- Chance to drop the event blade for non-top participants (top always gets it).
	DropChance = 0.12,
	DropRarity = "Epic", -- participants' drop rarity
	TopDropRarity = "Legendary", -- #1 damage dealer drop rarity
}

return BossData
