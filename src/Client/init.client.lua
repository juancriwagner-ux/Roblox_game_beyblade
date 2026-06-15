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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Root ScreenGui.
local gui = Instance.new("ScreenGui")
gui.Name = "BeybladeArena"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.Parent = playerGui

ClientState.start()
Toasts.start(gui)
App.start(gui)

-- Honor the player's SFX setting.
ClientState.onChanged(function(profile)
	if profile and profile.Settings then
		Sound.setEnabled(profile.Settings.Sfx ~= false)
	end
end)

-- Authoritative battle result -> play the clash, then reset the battle button.
;(Net.get("BattleResult") :: RemoteEvent).OnClientEvent:Connect(function(result, youAre, opponentName, rewards)
	App.setBattleSearching(false)
	BattleView.play(result, youAre, opponentName, rewards, gui)
end)

print("[BeybladeArena] Client ready.")
