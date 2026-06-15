--!strict
-- Sound.lua — central SFX playback. Each sound is backed by an asset ID in
-- Assets.Sounds; until you upload + paste real IDs, every call is a safe no-op.

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = require(ReplicatedStorage.Shared.Assets)

local Sound = {}

local cache: { [string]: Sound } = {}
local enabled = true

-- Respect the player's SFX setting.
function Sound.setEnabled(state: boolean)
	enabled = state
	if not state then
		for _, s in cache do
			if s.IsPlaying then
				s:Stop()
			end
		end
	end
end

local function build(key: string, looped: boolean, volume: number): Sound?
	local id = Assets.sound(key)
	if not id then
		return nil
	end
	local s = cache[key]
	if not s then
		s = Instance.new("Sound")
		s.Name = "SFX_" .. key
		s.SoundId = id
		s.Looped = looped
		s.Volume = volume
		s.Parent = SoundService
		cache[key] = s
	end
	return s
end

-- Fire-and-forget one-shot. Clones so overlapping plays don't cut each other.
function Sound.play(key: string, volume: number?)
	if not enabled then
		return
	end
	local base = build(key, false, volume or 0.6)
	if not base then
		return
	end
	local clone = base:Clone()
	clone.Parent = SoundService
	clone:Play()
	clone.Ended:Once(function()
		clone:Destroy()
	end)
	task.delay(8, function()
		if clone.Parent then
			clone:Destroy()
		end
	end)
end

-- Looping sound control (e.g. the spin whir during a battle).
function Sound.startLoop(key: string, volume: number?)
	if not enabled then
		return
	end
	local s = build(key, true, volume or 0.4)
	if s and not s.IsPlaying then
		s:Play()
	end
end

function Sound.stopLoop(key: string)
	local s = cache[key]
	if s and s.IsPlaying then
		s:Stop()
	end
end

return Sound
