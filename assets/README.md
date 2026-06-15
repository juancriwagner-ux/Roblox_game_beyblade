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

## 🔁 Regenerar o ampliar

Pídele a Claude que genere más (skins, más blades, banners, fondos de UI). Cada
imagen cuesta ~2 créditos en `nano_banana_pro` a 1K. También se pueden crear
**mallas 3D GLB** (`generate_3d`) a partir de estos renders para importarlas como
MeshParts premium en Roblox.
