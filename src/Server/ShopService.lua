--!strict
-- ShopService.lua — buy developed skins with the premium "Cores" currency.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local SkinData = require(Shared.SkinData)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local QuestService = require(script.Parent.QuestService)

local ShopService = {}

local function notify(player: Player, text: string, kind: string?)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, kind or "info")
end

function ShopService.buySkin(player: Player, skinId: string): any
	local p = DataService.get(player)
	local skin = SkinData.get(skinId)
	if not p or not skin then
		return { ok = false, reason = "invalid" }
	end
	if p.Skins[skinId] then
		return { ok = false, reason = "owned" }
	end
	if not EconomyService.spend(player, "Cores", skin.Price) then
		notify(player, "Núcleos insuficientes", "error")
		return { ok = false, reason = "insufficient" }
	end
	p.Skins[skinId] = true
	DataService.push(player)
	QuestService.report(player, "spend_cores", skin.Price)
	notify(player, ("¡Skin desbloqueada: %s!"):format(skin.Name), "success")
	return { ok = true }
end

return ShopService
