# 🎬 Kit de Contenido Viral — Beyblade Arena

Guiones, prompts de generación, copys y calendario listos para producir Shorts /
Reels / TikToks y un trailer de YouTube. Cuando Higgsfield esté disponible,
cada concepto incluye el **prompt exacto** y el **modelo recomendado**.

> Muchos clips usan **image-to-video** partiendo de los renders ya generados (sus
> `job_id` están en `/assets/README.md`), lo que da resultados on-brand y baratos.
> Para animar una imagen previa, se pasa su `job_id` en `medias[]` con
> `role: "start_image"`.

## ✅ Vídeos ya generados (lote inicial)

Las 9 piezas del plan están **generadas** con `kling3_0` image-to-video (5 s, con
sonido), ancladas a los renders existentes. Están en tu cuenta de Higgsfield
(`show_generations` type `video`). Descárgalas, añade texto/subtítulos y CTA en
tu editor (CapCut/Premiere) y publica según el calendario.

| # | Pieza | Formato | start_image | job id del vídeo |
|---|---|---|---|---|
| 1 | Trailer de lanzamiento | 16:9 | key art `672d4789` | `cd37a8d0-43b0-42b3-a082-4c8304305651` |
| 2 | "SALIÓ MÍTICO" (cofre) | 9:16 | Prisma `403bdf4a` | `d912aabc-f4b5-4337-aea0-a597e2d887b4` |
| 3 | Fuego vs Rayo | 9:16 | Magma `0bcc2db7` | `fb221717-652d-4c61-ab71-83c6bf8bdefb` |
| 4 | Spin ASMR | 9:16 | Eternal Halo `a56b356f` | `07b4c39a-340a-4c6b-a643-472c0843ce93` |
| 5 | Tier List | 9:16 | Celestial Prime `8bf79d03` | `4fa20d1c-407e-4f15-98b3-5a8f4d008db1` |
| 6 | POV racha x10 | 9:16 | Void Reaper `d3b3177a` | `72476278-00ea-41e6-b61b-ef8f9f6a45b8` |
| 7 | Showcase de skins | 9:16 | Voltage `9c3255bd` | `49dfd2bc-26fa-404f-8b90-f6dc9ff5896f` |
| 8 | Flex Battle Pass | 9:16 | Celestial Halo `9a180fdf` | `22b0042e-366d-4601-b0bf-ed742fcc1938` |
| 9 | Code drop | 9:16 | key art `672d4789` | `f50d96ae-0bc8-4c9b-88a1-f70e29d3db41` |

> El texto en pantalla (hooks, "¿CUÁL GANA?", código `LAUNCH`, etc.) se añade en
> el editor: los modelos no rotulan texto fiable. Las captions/títulos/tags están
> abajo y en `youtube-seo-and-voiceover.md`.

### 🔁 v2 — versiones con el hook al inicio (recomendadas)

Regeneradas tras el análisis de viralidad: el pico de energía (explosión / flash
/ reveal) ahora ocurre en el **primer segundo** en vez de al final, para subir el
hook de Shorts/Reels. Usa estas como versión principal; las v1 quedan de respaldo.

| # | Pieza | job id v2 (hook al inicio) |
|---|---|---|
| 1 | Trailer de lanzamiento (16:9) | `b50076d3-dc6b-4a3a-af95-6a3a1f22e9ff` |
| 2 | "SALIÓ MÍTICO" (cofre) | `6e2e49eb-14d6-4efa-ab19-ce35478444ea` |
| 3 | Fuego vs Rayo | `667e6a95-6c9d-4ec6-8df3-5930baa48cb6` |
| 4 | Spin ASMR | `ecf67dcc-bfd7-4254-9b6b-defbd4922b17` |
| 5 | Tier List | `3951f7a5-9cf5-4a65-ae5b-1f6fbc5c6d9a` |
| 6 | POV racha x10 | `471fa53d-6ab8-4def-90d4-833f06f7f2f1` |
| 7 | Showcase de skins | `0841bc3b-dd80-48fd-9fda-ba6c14028dd8` |
| 8 | Flex Battle Pass | `94cadee6-9963-4c12-a06f-152192e12415` |
| 9 | Code drop | `2912b2de-3fea-428a-9ad3-504dcb22c8db` |

## 🎯 Estrategia

- **80% vertical 9:16** (TikTok / Reels / Shorts) para alcance; **20% 16:9**
  (YouTube / anuncios) para conversión.
- **Hook en el primer segundo** (movimiento + texto grande). Sin intro lenta.
- **Texto en pantalla** siempre (mucha gente mira sin sonido).
- **CTA**: nombre del juego + código `LAUNCH` (25 núcleos) para incentivar la
  instalación.
- **Cadencia**: 1 Short/día durante 2 semanas + 1 trailer largo. Repostear el
  mejor a las 48 h.
- **Series recurrentes** (algoritmo premia consistencia): "¿Cuál gana?",
  "Cofre del día", "Tier list semanal".

## 🎥 Modelos recomendados (Higgsfield)

- `marketing_studio_video` → trailer/anuncio con CTA.
- `kling3_0` → multi-shot, movimiento complejo, audio.
- `seedance_2_0` → consistencia de un mismo objeto entre tomas.
- **image-to-video** desde un render (`role: start_image`) → animar blades/skins.

---

## 1) Trailer de lanzamiento (16:9 · ~15 s · YouTube/anuncio)

- **Hook (0-2 s):** negro → chispa → primer plano de un blade cayendo al estadio.
- **Desarrollo (2-10 s):** dos blades chocan, explosión de energía elemental,
  cortes rápidos de fuego vs rayo, cámara orbital.
- **Cierre (10-15 s):** logo "BEYBLADE ARENA" + texto **"JUEGA GRATIS"** + chip
  **"Código: LAUNCH"**.
- **Modelo:** `marketing_studio_video` (o `kling3_0`).
- **Prompt:** *"Cinematic 15-second trailer for a Beyblade battle game. Two
  glowing spinning tops launch into a neon futuristic stadium and collide in a
  massive burst of fire and electric energy, sparks flying, dramatic orbital
  camera, slow-motion impact, vibrant cyan and orange, AAA game cinematic,
  high energy build-up."*
- **Caption:** "El estadio está listo. ¿Tienes lo necesario para ser el #1? 🌀🔥
  Juega GRATIS — código LAUNCH = 25 núcleos. #Roblox #Beyblade"
- **Hashtags:** #Roblox #RobloxGames #Beyblade #BeybladeBurst #gaming

## 2) "SALIÓ MÍTICO" — apertura de cofre (9:16 · 8 s) ⭐ el más viral

- **Hook:** texto grande "ABRIENDO COFRE ÉLITE 👀" sobre el orbe pulsando.
- **Beat:** suspenso que acelera → **flash** → reveal del **Prisma Mítico**
  girando con arcoíris.
- **Cierre:** "1 entre 250 😱 ¿Tú qué sacarías?"
- **Modelo:** image-to-video desde el render del **Prisma** (`job_id`
  `403bdf4a-3465-4eeb-b211-742fffaf6d09`, `role: start_image`).
- **Prompt:** *"The holographic rainbow mythic beyblade spins fast and rises,
  prismatic light rays burst outward, sparkles and lens flares, slow zoom in,
  epic legendary reveal moment, dark background, glowing."*
- **Caption:** "MÍTICO al primer intento 😱🌈 ¿suerte o skill? #Roblox #Beyblade"
- **Hashtags:** #Roblox #fyp #beyblade #luckydrop #gaming

## 3) "Fuego vs Rayo, ¿quién gana?" (9:16 · 8 s) — bait de comentarios

- **Hook:** split screen Magma Core (🔥) vs Storm/Voltage (⚡), texto "¿CUÁL GANA?".
- **Beat:** ambos giran y chocan en el centro, freeze en el impacto.
- **Cierre:** "Comenta 🔥 o ⚡ — yo respondo a todos".
- **Modelo:** `kling3_0` (multi-shot) o image-to-video combinando renders
  `0bcc2db7` (Magma) y `9c3255bd` (Voltage).
- **Prompt:** *"Two beyblades clash in a neon arena: a molten lava fire top vs a
  crackling electric lightning top, sparks and energy collision in the center,
  freeze on impact, dramatic, vertical."*
- **Caption:** "🔥 vs ⚡ ¿quién se lleva la victoria? Comenta 👇 #Roblox #Beyblade"
- **Hashtags:** #Roblox #fyp #thisorthat #beyblade

## 4) Spin satisfactorio / ASMR (9:16 · 6 s) — retención/loop

- **Hook:** primer plano extremo del blade girando perfecto, partículas.
- **Beat:** loop perfecto (mismo frame inicial y final) → re-watch.
- **Cierre:** sin texto, solo el giro hipnótico (subtítulo: "loop perfecto 🌀").
- **Modelo:** image-to-video desde **Eternal Halo** (`a56b356f`) o **Celestial
  Prime** (`8bf79d03`).
- **Prompt:** *"Macro close-up of a glowing beyblade spinning steadily on a dark
  reflective surface, soft golden particles orbiting, seamless loop, satisfying,
  hypnotic, shallow depth of field."*
- **Caption:** "No puedo dejar de mirarlo 🌀✨ #satisfying #Roblox #Beyblade"
- **Hashtags:** #satisfying #asmr #Roblox #beyblade #fyp

## 5) Tier List de blades (9:16 · 10 s)

- **Hook:** "TIER LIST de los mejores blades 🏆".
- **Beat:** cortes rápidos: Celestial Prime (S), Void Reaper (A), Magma Core (A),
  Iron Aegis (B)… con etiqueta de letra apareciendo.
- **Cierre:** "¿Cuál es tu main? 👇".
- **Modelo:** `kling3_0` multi-shot o secuencia de image-to-video por blade.
- **Caption:** "La TIER LIST definitiva 🏆 ¿estás de acuerdo? #Roblox #Beyblade"
- **Hashtags:** #tierlist #Roblox #beyblade #gaming #fyp

## 6) "POV: racha de 10 victorias" (9:16 · 8 s)

- **Hook:** texto "POV: vas 9-0 y esta es la 10".
- **Beat:** montaje rápido de impactos ganadores + contador de trofeos subiendo.
- **Cierre:** "VICTORIA #10 🏆 racha imparable".
- **Modelo:** `kling3_0` (multi-shot con texto de contador).
- **Caption:** "Racha imparable 🔥🏆 ¿tu mejor racha? #Roblox #Beyblade"
- **Hashtags:** #Roblox #pov #wstreak #beyblade #fyp

## 7) Showcase de skins (9:16 · 8 s)

- **Hook:** "TODAS las skins en 8 segundos 🎨".
- **Beat:** morph fluido entre skins: Molten → Glacier → Voltage → Obsidiana →
  Celestial → Prisma.
- **Cierre:** "¿Cuál te comprarías? 👇".
- **Modelo:** `kling3_0` (transición/morph) usando los renders de skins
  (`9c6a2b18`, `e963e671`, `9c3255bd`, `987baf18`, `9a180fdf`, `403bdf4a`).
- **Caption:** "Glow up de skins ✨🎨 ¿tu favorita? #Roblox #Beyblade"
- **Hashtags:** #Roblox #skins #beyblade #fyp #gaming

## 8) Flex del Battle Pass (9:16 · 8 s)

- **Hook:** "Nivel 30 del Pase = blade LEGENDARIO 🏅".
- **Beat:** barra del pase llenándose rápido hasta el nivel 30 → reveal del Void
  Reaper legendario.
- **Cierre:** "¿Vale la pena el pase premium? 👀".
- **Modelo:** image-to-video desde **Void Reaper** (`d3b3177a`).
- **Caption:** "Terminé el Pase y MIRA lo que cayó 🏅🐉 #Roblox #Beyblade"
- **Hashtags:** #Roblox #battlepass #beyblade #fyp

## 9) Code drop (9:16 · 6 s) — adquisición

- **Hook:** "CÓDIGO GRATIS 🎟️ (úsalo ya)".
- **Beat:** se escribe `LAUNCH` en la caja de códigos → +25 núcleos animados.
- **Cierre:** "Códigos LAUNCH · BEYBLADE · SPINSTORM — corre antes de que expiren".
- **Modelo:** `marketing_studio_video` o image-to-video del key art (`672d4789`).
- **Caption:** "3 códigos GRATIS antes de que expiren 🎟️👀 #Roblox #Beyblade"
- **Hashtags:** #Roblox #codes #freestuff #beyblade #fyp

---

## 🗓️ Calendario sugerido (2 semanas)

| Día | Pieza | Plataforma |
|---|---|---|
| 1 | Trailer de lanzamiento | YouTube + anuncio |
| 2 | "SALIÓ MÍTICO" (cofre) | TikTok/Reels/Shorts |
| 3 | Fuego vs Rayo | TikTok/Reels/Shorts |
| 4 | Code drop | TikTok/Reels/Shorts |
| 5 | Spin ASMR | TikTok/Reels/Shorts |
| 6 | Tier List | TikTok/Reels/Shorts |
| 7 | POV racha x10 | TikTok/Reels/Shorts |
| 8 | Showcase de skins | TikTok/Reels/Shorts |
| 9 | Flex Battle Pass | TikTok/Reels/Shorts |
| 10 | "SALIÓ MÍTICO" v2 (otra rareza) | TikTok/Reels/Shorts |
| 11 | Fuego vs Hielo (variante) | TikTok/Reels/Shorts |
| 12 | Repost del mejor + duet/stitch | TikTok |
| 13 | Tier list de skins | TikTok/Reels/Shorts |
| 14 | Recap + "evento esta semana" | Todas |

## ✅ Checklist de publicación
- Hook visible y con texto en el primer segundo.
- Subtítulos/Texto grande, legible en móvil.
- Música de tendencia (TikTok/Reels) + el SFX del juego cuando aplique.
- CTA + código en la descripción y fijado en comentarios.
- Mismo @usuario y nombre del juego en todas las plataformas.
- Hashtags: 1 de marca + 2 de nicho + 1-2 amplios (#fyp #Roblox).

## 🔎 Validar antes de publicar
Con `virality_predictor` (Higgsfield) se puede analizar cada video generado y
quedarte con el de mayor hook/retención antes de subirlo.

## 🧠 Resultados del virality_predictor (lote inicial)

Análisis de los clips con `virality_predictor`. El servicio falló de forma
intermitente en varios clips ese día (cofre mítico, ASMR, POV, battle pass y
code drop quedaron sin puntuar — es un fallo del analizador, no de calidad;
reintenta cuando quieras). Scores normalizados 0-100 (proxy predictivo):

| Pieza | Overall | Viral pot. | Hook (0-3s) | Engagement | Pico |
|---|---|---|---|---|---|
| **Tier List** 🥇 | 48 | 46 | 33 | 41 | s5 |
| **Fuego vs Rayo** 🥈 | 47 | 44 | 32 | 40 | s5 |
| **Showcase skins** 🥉 | 46 | 43 | 31 | 37 | s5 |
| **Trailer** | 45 | 44 | 30 | 35 | s5 |

**Orden de publicación sugerido (de los puntuados):** Tier List → Fuego vs Rayo
→ Showcase → Trailer.

### ⚠️ Hallazgo clave (aplica a TODOS los clips)
Todos tienen **sustain alto (100)** pero **hook bajo (30-33)** y el **pico de
atención cae en el segundo 5** (el final), no al principio. Para Shorts/Reels esto
es justo lo contrario de lo ideal. Acciones en la edición antes de publicar:

- **Adelanta el impacto al primer segundo**: corta el clip para empezar por el
  fotograma de mayor energía (la colisión/explosión/flash), no por el arranque.
- **Texto-hook enorme en t=0s** ("¿CUÁL GANA?", "SALIÓ MÍTICO 😱", "1 entre 250").
- **Loop**: enlaza el último frame con el primero para forzar el re-watch.
- Reanaliza la versión recortada y quédate con la de mayor hook.
