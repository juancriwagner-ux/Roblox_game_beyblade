--!strict
-- MusicController.lua — background music with crossfade between the menu/hub
-- theme and the battle theme. Respects the player's "Music" setting. Safe no-op
-- until track IDs are pasted into Assets.Music.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = require(ReplicatedStorage.Shared.Assets)

local MusicController = {}

local MENU_VOLUME = 0.35
local BATTLE_VOLUME = 0.45

local tracks: { [string]: Sound } = {}
local enabled = true
local inBattle = false
local current: string? = nil

local function getTrack(key: string): Sound?
	local id = Assets.music(key)
	if not id then
		return nil
	end
	local s = tracks[key]
	if not s then
		s = Instance.new("Sound")
		s.Name = "Music_" .. key
		s.SoundId = id
		s.Looped = true
		s.Volume = 0
		s.Parent = SoundService
		tracks[key] = s
	end
	return s
end

local function targetKey(): string
	return inBattle and "Battle" or "Menu"
end

-- Crossfade to the track that should be playing right now.
local function refresh()
	local wantKey = enabled and targetKey() or nil

	for key, s in tracks do
		if key ~= wantKey and s.IsPlaying then
			local tween = TweenService:Create(s, TweenInfo.new(0.8), { Volume = 0 })
			tween:Play()
			tween.Completed:Once(function()
				if s.Volume <= 0.001 then
					s:Stop()
				end
			end)
		end
	end

	if not wantKey then
		current = nil
		return
	end

	local s = getTrack(wantKey)
	if not s then
		return
	end
	if not s.IsPlaying then
		s:Play()
	end
	local vol = wantKey == "Battle" and BATTLE_VOLUME or MENU_VOLUME
	TweenService:Create(s, TweenInfo.new(0.8), { Volume = vol }):Play()
	current = wantKey
end

function MusicController.setEnabled(state: boolean)
	if enabled == state then
		return
	end
	enabled = state
	refresh()
end

function MusicController.setBattle(state: boolean)
	if inBattle == state then
		return
	end
	inBattle = state
	refresh()
end

function MusicController.start()
	refresh()
end

return MusicController
