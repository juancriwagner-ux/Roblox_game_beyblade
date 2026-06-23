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

	-- Skin renders (shown in the shop cell when uploaded; key = "Skin_" .. skinId)
	Skin_molten = "rbxassetid://0",
	Skin_glacier = "rbxassetid://0",
	Skin_voltage = "rbxassetid://0",
	Skin_obsidian = "rbxassetid://0",
	Skin_celestial = "rbxassetid://0",
	Skin_prism = "rbxassetid://0",
	Skin_venom = "rbxassetid://0",
}

-- Sound effect asset IDs. Same deal: upload each generated SFX to Roblox
-- (Asset Manager → Audio → Import) and paste the resulting ID here.
Assets.Sounds = {
	Launch = "rbxassetid://0", -- ripcord launch
	Clash = "rbxassetid://0", -- blades colliding (per battle round)
	Spin = "rbxassetid://0", -- looping spin whir during battle
	Victory = "rbxassetid://0", -- win fanfare
	Defeat = "rbxassetid://0", -- loss stinger
	Collect = "rbxassetid://0", -- world-spawn pickup chime
}

function Assets.sound(key: string): string?
	local v = Assets.Sounds[key]
	if v ~= nil and v ~= "rbxassetid://0" then
		return v
	end
	return nil
end

-- Background music tracks. Upload each to Roblox (Audio) and paste the ID.
Assets.Music = {
	Menu = "rbxassetid://0", -- hub / menu loop
	Battle = "rbxassetid://0", -- intense battle loop
}

function Assets.music(key: string): string?
	local v = Assets.Music[key]
	if v ~= nil and v ~= "rbxassetid://0" then
		return v
	end
	return nil
end

-- Tileable textures (upload the image, paste the ID). Applied to world geometry.
Assets.Textures = {
	CityFacade = "rbxassetid://0", -- sci-fi building wall texture
}

function Assets.texture(key: string): string?
	local v = Assets.Textures[key]
	if v ~= nil and v ~= "rbxassetid://0" then
		return v
	end
	return nil
end

-- Premium 3D blade meshes. After importing a GLB in Studio (Import 3D), open
-- the resulting MeshPart and copy its MeshId + TextureID here. When MeshId is
-- set, ModelBuilder renders that blade as the premium mesh everywhere (battle,
-- collection, spawns). Scale/Rot let you fine-tune size + orientation once.
export type BladeMesh = { MeshId: string, TextureId: string, Scale: number, RotX: number, RotY: number, RotZ: number }

Assets.Blades = {
	celestial_prime = { MeshId = "rbxassetid://0", TextureId = "rbxassetid://0", Scale = 2, RotX = 0, RotY = 0, RotZ = -90 },
	void_reaper = { MeshId = "rbxassetid://0", TextureId = "rbxassetid://0", Scale = 2, RotX = 0, RotY = 0, RotZ = -90 },
	magma_core = { MeshId = "rbxassetid://0", TextureId = "rbxassetid://0", Scale = 2, RotX = 0, RotY = 0, RotZ = -90 },
} :: { [string]: BladeMesh }

-- Returns the mesh def for a blade only when a real MeshId is set.
function Assets.bladeMesh(bladeId: string): BladeMesh?
	local m = Assets.Blades[bladeId]
	if m and m.MeshId ~= "rbxassetid://0" then
		return m
	end
	return nil
end

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
