--!strict
-- Assets.lua
-- Central registry of uploaded Roblox image asset IDs.
--
-- These premium images were generated for the game (see /assets/README.md for
-- the gallery + prompts). Roblox can only display images that live on its CDN,
-- so each one must be uploaded once from YOUR account:
--
--   Studio → Asset Manager → Images → Import  (or create.roblox.com → Creations)
--
-- Roblox gives each upload a numeric ID. Paste it below as "rbxassetid://<ID>".
-- Anything left as 0 simply falls back to the procedural / text UI — the game
-- works fully either way.

local Assets = {}

Assets.Images = {
	-- Marketing (also used in-game where noted)
	Logo = "rbxassetid://0", -- logo_wordmark — shown in the top HUD
	Icon = "rbxassetid://0", -- game_icon — set as the game's icon on the site
	KeyArt = "rbxassetid://0", -- key_art — set as the game's thumbnail on the site

	-- Currency icons (top HUD pills)
	BoltsIcon = "rbxassetid://0", -- golden gear/bolt coin
	CoresIcon = "rbxassetid://0", -- cyan energy core crystal

	-- Hero blade renders (optional splash art in the collection detail / shop)
	Blade_celestial_prime = "rbxassetid://0",
	Blade_void_reaper = "rbxassetid://0",
	Blade_magma_core = "rbxassetid://0",
	Blade_eternal_halo = "rbxassetid://0",
}

-- True when a real ID has been pasted in (not the 0 placeholder).
function Assets.has(key: string): boolean
	local v = Assets.Images[key]
	return v ~= nil and v ~= "rbxassetid://0"
end

-- Returns the asset string, or nil if still a placeholder.
function Assets.image(key: string): string?
	if Assets.has(key) then
		return Assets.Images[key]
	end
	return nil
end

return Assets
