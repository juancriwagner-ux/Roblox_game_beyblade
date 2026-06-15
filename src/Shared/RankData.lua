--!strict
-- RankData.lua — competitive trophy ladder (leagues). Shared so the client can
-- render the player's current league without a round-trip.

export type Rank = {
	Id: string,
	Name: string,
	Min: number, -- trophies required to enter this league
	Color: Color3,
	Icon: string,
}

local RankData = {}

-- Ordered from lowest to highest. `Min` is the entry threshold.
RankData.Ranks = {
	{ Id = "Bronze", Name = "Bronce", Min = 0, Color = Color3.fromRGB(176, 116, 72), Icon = "🥉" },
	{ Id = "Silver", Name = "Plata", Min = 300, Color = Color3.fromRGB(190, 198, 210), Icon = "🥈" },
	{ Id = "Gold", Name = "Oro", Min = 700, Color = Color3.fromRGB(255, 196, 64), Icon = "🥇" },
	{ Id = "Platinum", Name = "Platino", Min = 1200, Color = Color3.fromRGB(120, 230, 220), Icon = "💎" },
	{ Id = "Diamond", Name = "Diamante", Min = 1900, Color = Color3.fromRGB(120, 196, 255), Icon = "💠" },
	{ Id = "Master", Name = "Maestro", Min = 2800, Color = Color3.fromRGB(200, 120, 255), Icon = "👑" },
	{ Id = "Legend", Name = "Leyenda", Min = 4000, Color = Color3.fromRGB(255, 92, 132), Icon = "🔥" },
} :: { Rank }

-- League for a given trophy count.
function RankData.forTrophies(trophies: number): Rank
	local current = RankData.Ranks[1]
	for _, rank in RankData.Ranks do
		if trophies >= rank.Min then
			current = rank
		else
			break
		end
	end
	return current
end

-- Trophies remaining until the next league (nil if already top).
function RankData.toNext(trophies: number): (number?, Rank?)
	for _, rank in RankData.Ranks do
		if trophies < rank.Min then
			return rank.Min - trophies, rank
		end
	end
	return nil, nil
end

return RankData
