# 🎬 Kit de Contenido Viral — Beyblade Arena

Guiones, prompts de generación, copys y calendario listos para producir Shorts /
Reels / TikToks y un trailer de YouTube. Cuando Higgsfield esté disponible,
cada concepto incluye el **prompt exacto** y el **modelo recomendado**.

> Muchos clips usan **image-to-video** partiendo de los renders ya generados (sus
> `job_id` están en `/assets/README.md`), lo que da resultados on-brand y baratos.
> Para animar una imagen previa, se pasa su `job_id` en `medias[]` con
> `role: "start_image"`.

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
