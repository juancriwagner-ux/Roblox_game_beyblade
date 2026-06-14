--!strict
-- ClientState.lua — local cache of the player's profile, kept in sync by the
-- server's ProfileUpdated event. UI controllers subscribe via onChanged().

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage.Shared.Net)

local ClientState = {}

local profile: any = nil
local listeners: { (any) -> () } = {}

function ClientState.get(): any
	return profile
end

function ClientState.set(newProfile: any)
	profile = newProfile
	for _, fn in listeners do
		task.spawn(fn, profile)
	end
end

function ClientState.onChanged(fn: (any) -> ()): () -> ()
	table.insert(listeners, fn)
	if profile then
		task.spawn(fn, profile)
	end
	return function()
		local i = table.find(listeners, fn)
		if i then
			table.remove(listeners, i)
		end
	end
end

function ClientState.start()
	(Net.get("ProfileUpdated") :: RemoteEvent).OnClientEvent:Connect(function(snap)
		ClientState.set(snap)
	end)
	-- Initial pull in case we missed the first push.
	task.spawn(function()
		local snap = (Net.get("RequestProfile") :: RemoteFunction):InvokeServer()
		if snap and not profile then
			ClientState.set(snap)
		end
	end)
end

return ClientState
