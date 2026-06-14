--!strict
-- Util.lua — small shared helpers.

local Util = {}

function Util.deepCopy<T>(t: T): T
	if typeof(t) ~= "table" then
		return t
	end
	local out: any = {}
	for k, v in (t :: any) do
		out[k] = Util.deepCopy(v)
	end
	return out
end

-- Abbreviate large numbers: 1500 -> "1.5K", 2_400_000 -> "2.4M".
function Util.abbreviate(n: number): string
	local abs = math.abs(n)
	if abs >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif abs >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif abs >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

function Util.weightedPick<T>(entries: { { value: T, weight: number } }, rng: Random?): T
	local r = rng or Random.new()
	local total = 0
	for _, e in entries do
		total += e.weight
	end
	local pick = r:NextNumber(0, total)
	local acc = 0
	for _, e in entries do
		acc += e.weight
		if pick <= acc then
			return e.value
		end
	end
	return entries[#entries].value
end

function Util.round(n: number, places: number?): number
	local m = 10 ^ (places or 0)
	return math.floor(n * m + 0.5) / m
end

-- Format a seconds duration as "2h 5m" / "45m" / "30s".
function Util.duration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm %ds", m, s)
	end
	return string.format("%ds", s)
end

return Util
