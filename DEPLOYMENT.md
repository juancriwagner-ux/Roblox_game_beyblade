# 🚀 Plan de Deployment — Beyblade Arena

Guía paso a paso para llevar el proyecto del repositorio a un juego **publicado y
monetizado** en Roblox. Marca cada casilla a medida que avanzas.

Leyenda: 🧑‍💻 = lo haces TÚ · 🤖 = ya está hecho en el código.

---

## Fase 0 — Requisitos (una sola vez)

- [ ] 🧑‍💻 Cuenta de Roblox + **Roblox Studio** instalado (https://create.roblox.com).
- [ ] 🧑‍💻 Instala **Rokit** (gestor de toolchain) → https://github.com/rojo-rbx/rokit
- [ ] 🧑‍💻 En la carpeta del repo: `rokit install` (instala Rojo 7.4.4 según `rokit.toml`).
- [ ] 🧑‍💻 Instala el **plugin de Rojo** en Studio (desde la Creator Store, busca "Rojo").

---

## Fase 1 — Pasar el código a Studio

- [ ] 🧑‍💻 En la carpeta del repo: `rojo serve`
- [ ] 🧑‍💻 Studio → abre un **lugar nuevo (Baseplate)** → pestaña **Plugins → Rojo → Connect**.
      El árbol del juego se construye solo (Server, Client, Shared, World, etc.).
- [ ] 🧑‍💻 Pulsa **Play** ▶️. Deberías ver el HUD, recolectar trompos y combatir contra un bot.

> Nota: en Studio los datos **no persisten** (usamos un mock para testear sin
> DataStore). La persistencia real solo funciona en el juego **publicado**.

---

## Fase 2 — Publicar el lugar

- [ ] 🧑‍💻 Studio → **File → Publish to Roblox As…** → crea una experiencia nueva
      (nombre: *Beyblade Arena*).
- [ ] 🧑‍💻 Esto crea la **Experiencia (universo)** y el **Lugar** inicial.

---

## Fase 3 — Activar servicios de Roblox

- [ ] 🧑‍💻 **DataStores** (guardado de progreso): en el panel de creador
      (create.roblox.com → tu experiencia → **Configure → Security**) activa
      **"Enable Studio Access to API Services"** (necesario para probar DataStore
      desde Studio; en el juego publicado ya funciona).
      - Stores usados: `BeybladeProfiles_v1`, `LB_Trophies_v1`, `LB_Wins_v1`.
- [ ] 🧑‍💻 **Badges** (para los logros): se crean en la Fase 6. `BadgeService` ya
      está integrado; sin IDs simplemente no otorga badge (el logro funciona igual).
- [ ] 🤖 HTTP: **no** se requiere (no usamos servicios externos).

---

## Fase 4 — Configurar la experiencia (página del juego)

- [ ] 🧑‍💻 **Nombre** y **descripción** (usa los textos SEO de
      `marketing/youtube-seo-and-voiceover.md`).
- [ ] 🧑‍💻 **Ícono** del juego: sube `game_icon` (de Higgsfield).
- [ ] 🧑‍💻 **Miniaturas**: sube `key_art` y renders de blades/skins.
- [ ] 🧑‍💻 **Géneros/tags**: Battle, Fighting, Anime.
- [ ] 🧑‍💻 **Dispositivos**: Computer + Phone + Tablet (la UI ya es responsive).
- [ ] 🧑‍💻 **Servidores**: máx. jugadores ~12-20 (bueno para 2v2 y jefes).
- [ ] 🧑‍💻 **Acceso**: déjalo **privado** hasta terminar el QA (Fase 8).

---

## Fase 5 — Subir assets y pegar IDs

> Todo lo de Higgsfield está en tu cuenta (ver `/assets/README.md`). Súbelo a
> Roblox y pega los IDs. Lo que dejes en `0` usa el fallback procedural; nada se rompe.

- [ ] 🧑‍💻 **Imágenes** (Asset Manager → Images → Import) → pega IDs en
      `src/Shared/Assets.lua` (`Logo`, `BoltsIcon`, `CoresIcon`, `Skin_*`, etc.).
- [ ] 🧑‍💻 **Sonidos** (Asset Manager → Audio → Import; requiere aprobación de
      moderación) → `Assets.Sounds` (`Launch`, `Clash`, `Spin`, `Victory`,
      `Defeat`, `Collect`).
- [ ] 🧑‍💻 **Música** → `Assets.Music` (`Menu`, `Battle`).
- [ ] 🧑‍💻 Vuelve a sincronizar Rojo tras editar los archivos.

---

## Fase 6 — Monetización (Robux)

- [ ] 🧑‍💻 Crea **Developer Products** para los paquetes de Núcleos
      (Configure → **Monetization → Developer Products**).
- [ ] 🧑‍💻 Pega los IDs en `src/Server/MonetizationService.lua` → tabla `PRODUCTS`
      (productId → cantidad de Núcleos).
- [ ] 🤖 `ProcessReceipt` ya está implementado (otorga Núcleos y es a prueba de
      reintentos).
- [ ] 🧑‍💻 (Opcional) Botones de compra en la UI: avísame con los IDs y agrego los
      `PromptProductPurchase` en la tienda.
- [ ] 🧑‍💻 Crea los **Badges** de logros (Configure → **Badges**) y pega sus IDs en
      `src/Shared/AchievementData.lua` (campo `Badge`).
- [ ] 🧑‍💻 Revisa/edita los **códigos** en `src/Server/CodesService.lua`
      (`LAUNCH`, `BEYBLADE`, `SPINSTORM`, `FREEBLADE`).

### ✅ Cumplimiento: odds de cajas (ya resuelto)
Los Núcleos se compran con Robux y el **Cofre Élite** se abre con Núcleos → la
**Paid Random Items Policy** de Roblox exige mostrar las probabilidades. **Ya
está implementado**: cada tarjeta de cofre muestra sus odds exactas por rareza
(calculadas de los mismos pesos que usa el servidor). Si cambias pesos/sesgos en
`RarityData`/`CrateData`, las odds mostradas se actualizan solas.

---

## Fase 7 — Balance y live-ops (opcional pre-launch)

- [ ] 🧑‍💻 Ajusta economía/tiempos en `src/Shared/Config.lua` (spawns, recompensas).
- [ ] 🧑‍💻 Jefe: `src/Shared/BossData.lua` (intervalo, HP, recompensas).
- [ ] 🧑‍💻 Battle Pass: `src/Shared/SeasonData.lua` (precio premium, recompensas).
- [ ] 🤖 La temporada **rota sola** cada mes natural.

---

## Fase 8 — QA antes de lanzar (checklist)

- [ ] 🧑‍💻 **Solo**: tutorial FTUE, recolectar, 1v1 vs bot, tienda, cofres, misiones.
- [ ] 🧑‍💻 **2 jugadores** (Studio → Test → Players: 2): 1v1 humano, **2v2**, **espectador**.
- [ ] 🧑‍💻 **Jefe Mundial**: espera el evento (~90s en server nuevo), atácalo, verifica
      recompensas y el drop de Inferno Titan.
- [ ] 🧑‍💻 **Persistencia** (en server PUBLICADO, no Studio): gana monedas → sal →
      reentra → verifica que se guardó.
- [ ] 🧑‍💻 **Battle Pass / Ranking / Logros / Historial**: revisa que avanzan y se reclaman.
- [ ] 🧑‍💻 **Compra de prueba** de un Developer Product (modo test de Roblox).
- [ ] 🧑‍💻 **Móvil**: prueba en la app de Roblox (botones táctiles, escalado).

---

## Fase 9 — Lanzamiento

- [ ] 🧑‍💻 Cambia el acceso de la experiencia a **Público**.
- [ ] 🧑‍💻 Publica un parche final si tocaste código (Rojo → Publish).
- [ ] 🧑‍💻 Activa el **plan de marketing**: sube el trailer + Shorts
      (`marketing/viral-content-kit.md`) y fija los **códigos** en cada video.

---

## Fase 10 — Post-lanzamiento (operación)

- [ ] 🧑‍💻 Monitorea errores en el **Developer Console** (F9 en el juego) y en
      **Analytics** del panel de creador.
- [ ] 🧑‍💻 Vigila límites de **DataStore** (cuotas) con muchos jugadores.
- [ ] 🧑‍💻 Live-ops: agrega **códigos** nuevos, **skins**, **eventos** y rota
      recompensas para mantener retención.
- [ ] 🧑‍💻 (Producción seria) Considera migrar `DataService` a
      **ProfileStore** para session-locking de nivel industrial (la API ya está
      preparada para el cambio).

---

## 🤖 (Avanzado/opcional) CI/CD automatizado
Se puede automatizar el build y la publicación con **GitHub Actions** +
**Rojo build** + la **Open Cloud API** de Roblox (publicar el `.rbxl` al hacer
push). Si lo quieres, te preparo el workflow y te indico qué API key generar.

---

## 📌 Resumen de IDs que debes pegar
| Dónde | Qué |
|---|---|
| `src/Shared/Assets.lua` → `Images` | Logo, íconos de moneda, renders de skins/blades |
| `src/Shared/Assets.lua` → `Sounds` | SFX (launch, clash, spin, victory, defeat, collect) |
| `src/Shared/Assets.lua` → `Music` | Menú, Batalla |
| `src/Server/MonetizationService.lua` → `PRODUCTS` | Developer Products de Núcleos |
| `src/Shared/AchievementData.lua` → `Badge` | BadgeIds de Roblox |
| `src/Server/CodesService.lua` → `CODES` | Códigos canjeables |
