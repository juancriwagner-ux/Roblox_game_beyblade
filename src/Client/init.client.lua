--!strict
-- Client bootstrap for Beyblade Arena. Builds the UI, wires the data stream
-- and routes authoritative battle results into the cinematic playback.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)

local ClientState = require(script.ClientState)
local App = require(script.App)
local Toasts = require(script.Toasts)
local BattleView = require(script.BattleView)
local Sound = require(script.Sound)
local Responsive = require(script.Responsive)
local TutorialController = require(script.TutorialController)
local BossController = require(script.BossController)
local MusicController = require(script.MusicController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Root ScreenGui.
local gui = Instance.new("ScreenGui")
gui.Name = "BeybladeArena"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = playerGui

Responsive.start(gui)
ClientState.start()
Toasts.start(gui)
App.start(gui)
TutorialController.start(gui)
BossController.start(gui)
MusicController.start()

-- Honor the player's audio settings.
ClientState.onChanged(function(profile)
	if profile and profile.Settings then
		Sound.setEnabled(profile.Settings.Sfx ~= false)
		MusicController.setEnabled(profile.Settings.Music ~= false)
	end
end)

-- Authoritative battle result -> play the clash, then reset the battle button.
;(Net.get("BattleResult") :: RemoteEvent).OnClientEvent:Connect(function(result, youAre, opponentName, rewards)
	App.setBattleSearching(false)
	BattleView.play(result, youAre, opponentName, rewards, gui)
end)

-- Authoritative 2v2 result -> play the team clash.
;(Net.get("TeamBattleResult") :: RemoteEvent).OnClientEvent:Connect(function(payload, youTeam, rewards)
	App.setBattleSearching(false)
	BattleView.playTeam(payload, youTeam, rewards, gui, false)
end)

print("[BeybladeArena] Client ready.")
