# 🎨 Premium Assets — Beyblade Arena

8 imágenes premium generadas con IA (modelo `nano_banana_pro`) para el juego.
Están guardadas en **tu cuenta de Higgsfield** (no se pudieron versionar aquí
porque el entorno bloquea el dominio de descarga del CDN). Para verlas/descargarlas:

> Higgsfield → tu workspace → **Generations / History** (o pide a Claude que las
> muestre con `show_generations`). Los `job id` de abajo te ayudan a localizarlas.

## 📥 Cómo integrarlas en el juego (lo que haces TÚ)

1. **Descarga** cada PNG desde Higgsfield.
2. **Súbela a Roblox**: Studio → *Asset Manager* → *Images* → *Import*
   (o en https://create.roblox.com → *Creations* → *Decals/Images*).
3. Roblox te da un **ID numérico**. Pégalo en `src/Shared/Assets.lua` como
   `"rbxassetid://<ID>"` en la clave indicada.
4. El juego usará la imagen automáticamente. Lo que dejes en `0` cae al
   fallback procedural/texto, así que nada se rompe.

> Sugerencia: para texturas/sprites usa *Decal/Image*; para el **ícono** y el
> **thumbnail** del juego, súbelos en la página del juego (Configure → Icon /
> Thumbnails), no hace falta ID en el código.

## 🗂️ Catálogo y mapeo

| Imagen | Clave en `Assets.lua` | Uso en el juego | job id |
|---|---|---|---|
| **Logo wordmark** "BEYBLADE ARENA" | `Logo` | Cabecera del HUD | `bb6efbeb-dace-4e2e-ba30-79b720f975f8` |
| **Ícono del juego** | `Icon` | Ícono en la página de Roblox | `11632a65-daab-4608-80db-e278ad8ad74e` |
| **Key art / thumbnail** | `KeyArt` | Portada/thumbnail del juego | `672d4789-fdef-4f06-830b-d821f5bc9064` |
| **Ícono moneda Tuercas** (engranaje dorado) | `BoltsIcon` | Pill de moneda en HUD | `be5bef73-...` (sheet) |
| **Ícono moneda Núcleos** (cristal cian) | `CoresIcon` | Pill de moneda en HUD | `be5bef73-...` (sheet) |
| **Celestial Prime** (mítico) | `Blade_celestial_prime` | Splash art de tienda/colección | `8bf79d03-edb6-4514-b19e-ea17085e3331` |
| **Void Reaper** (legendario) | `Blade_void_reaper` | Splash art | `d3b3177a-8917-4f9a-9ff6-c569780f0f33` |
| **Magma Core** (épico) | `Blade_magma_core` | Splash art | `0bcc2db7-b98a-4256-819d-8917037bd999` |
| **Eternal Halo** (legendario) | `Blade_eternal_halo` | Splash art | `a56b356f-8a0b-4b99-bb7f-c0bcee235dd5` |

> El **icono de monedas** se generó como una lámina con las dos monedas juntas.
> Recórtala en dos PNG (Tuercas / Núcleos) antes de subirlas, o regenérala como
> dos imágenes separadas si prefieres.

## 🎭 Skins (renders premium)

Súbelas como *Image/Decal* y pega el ID en `Assets.Images` (clave `Skin_<id>`).
La tienda mostrará el render premium automáticamente; si no, usa el preview 3D.

| Skin | Clave en `Assets.lua` | Rareza | job id |
|---|---|---|---|
| **Molten Core** (lava) | `Skin_molten` | Raro | `9c6a2b18-e104-48c0-ae2e-f7e74732f5d9` |
| **Glacier** (hielo) | `Skin_glacier` | Raro | `e963e671-524b-480c-a0dd-33ffb2b64da9` |
| **Voltage** (rayo) | `Skin_voltage` | Épico | `9c3255bd-abc6-4228-8f3a-630de6c6aafc` |
| **Abyssal Obsidian** (sombra) | `Skin_obsidian` | Épico | `987baf18-af34-4e61-a536-0e7434af69e8` |
| **Celestial Halo** (luz) | `Skin_celestial` | Legendario | `9a180fdf-ec76-42da-a734-ba28e1082698` |
| **Mythic Prism** (arcoíris) | `Skin_prism` | Mítico | `403bdf4a-3465-4eeb-b211-742fffaf6d09` |
| **Venom** (tóxico) ⭐ nueva | `Skin_venom` | Épico | `757b1091-4320-4840-b357-7a65ccffa164` |

> *Venom* se añadió al catálogo (`SkinData.lua`) como skin jugable nueva.

## 🔊 Sonidos (SFX)

Súbelos en *Asset Manager → Audio → Import* y pega el ID en `Assets.Sounds`.
Ya están cableados en el juego (no-op hasta que pegues los IDs).

| Sonido | Clave en `Assets.lua` | Cuándo suena | job id |
|---|---|---|---|
| **Lanzamiento** | `Launch` | Al empezar la batalla | `7d7ed898-038e-427b-b032-7cea46d9a34f` |
| **Choque** | `Clash` | En cada ronda (impacto) | `4d2c993a-3d8c-40e3-a2e3-adf4eca6a644` |
| **Giro (loop)** | `Spin` | Durante la batalla | `3b9ae4d8-67e6-48bf-98e0-c48dbc72ec42` |
| **Victoria** | `Victory` | Al ganar | `3ab655ed-c601-4543-83e8-614d5c394b21` |
| **Derrota** | `Defeat` | Al perder | `fb85fb0b-4bca-46f3-a45c-9f4999ac4c9c` |
| **Recolección** | `Collect` | Al recoger un Beyblade | `12aac364-477f-4047-a2ea-26a05bbc4b59` |

> Para audio importado, Roblox puede requerir aprobación de moderación antes de
> que el ID sea reproducible.

## 🎵 Música de fondo (pendiente de generar)

Cableada en el juego (`MusicController` + `Assets.Music`), con crossfade entre
el tema del menú y el de batalla y respeto al ajuste de Música. Falta generar
las pistas (el acceso de generación estaba bloqueado por aprobación). Genéralas
con `sonilo_music` (~60 s, loop) y pega los IDs en `Assets.Music`:

| Pista | Clave | Prompt sugerido |
|---|---|---|
| **Menú/Hub** | `Menu` | "Energetic upbeat electronic menu theme, futuristic arcade, driving synth arpeggios, punchy drums, heroic, seamless loop, no vocals" |
| **Batalla** | `Battle` | "Intense fast electronic battle theme, aggressive bass, epic percussion, rising tension, esports hype, seamless loop, no vocals" |

> Súbelas en *Asset Manager → Audio → Import* (puede requerir moderación) y pega
> los IDs en `src/Shared/Assets.lua` → `Assets.Music`.

## 🔁 Regenerar o ampliar

Pídele a Claude que genere más (skins, más blades, banners, fondos de UI). Cada
imagen cuesta ~2 créditos en `nano_banana_pro` a 1K. También se pueden crear
**mallas 3D GLB** (`generate_3d`) a partir de estos renders para importarlas como
MeshParts premium en Roblox.
