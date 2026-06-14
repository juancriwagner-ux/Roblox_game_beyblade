--!strict
-- MonetizationService.lua
-- Robux monetization for the premium "Cores" currency via Developer Products.
--
-- >>> WHAT YOU (the owner) MUST DO <<<
-- 1. In the Creator Dashboard / Studio, create Developer Products for each
--    Cores bundle and a Game Pass for any perks.
-- 2. Paste the numeric product IDs into the PRODUCTS table below.
-- Until real IDs are added, the entries use 0 and simply won't fire — the rest
-- of the game is fully playable without them.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local MonetizationService = {}

-- productId -> amount of Cores to grant. Replace the keys with your real IDs.
local PRODUCTS: { [number]: number } = {
	-- [0000001] = 50,   -- "Puñado de Núcleos"
	-- [0000002] = 150,  -- "Bolsa de Núcleos"
	-- [0000003] = 500,  -- "Cofre de Núcleos"
	-- [0000004] = 1500, -- "Bóveda de Núcleos"
}

local function notify(player: Player, text: string)
	(Net.get("Notify") :: RemoteEvent):FireClient(player, text, "success")
end

function MonetizationService.init()
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = game:GetService("Players"):GetPlayerByUserId(receipt.PlayerId)
		if not player then
			-- Player left before processing; ask Roblox to retry later.
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not DataService.isLoaded(player) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local cores = PRODUCTS[receipt.ProductId]
		if not cores then
			-- Unknown product: grant nothing but mark processed to avoid a loop.
			warn("[Monetization] unknown product id " .. tostring(receipt.ProductId))
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		EconomyService.add(player, "Cores", cores, true)
		notify(player, ("¡Compra exitosa! +%d Núcleos"):format(cores))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return MonetizationService
