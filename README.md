# 🌀 Beyblade Arena — Roblox

Juego world-class de batallas de Beyblade: recolecta trompos de distintas
categorías y elementos que aparecen aleatoriamente en el mundo, acumula moneda,
desbloquea **skins desarrolladas** exclusivas y combate en **batallas PvP
probabilísticas** con animación cinematográfica en una arena 3D.

Todo el código y los modelos 3D se generan **proceduralmente** (sin necesidad de
subir assets), así que el juego es jugable en cuanto lo sincronizas a Studio.

---

## 🎮 Características

- **Colección de Beyblades** con 4 arquetipos (Ataque, Defensa, Resistencia,
  Balance), 8 elementos (Fuego, Hielo, Rayo, Tierra, Viento, Metal, Sombra, Luz)
  y 6 rarezas (Común → Mítico) con multiplicadores de stats.
- **Spawns aleatorios temporizados** en oleadas: Goteo (~75 s), Lluvia (~6 min),
  Tormenta (~30 min) y Eclipse (~2 h, con opción a Mítico). Se recogen por
  proximidad.
- **Economía F2P** con dos monedas: **Tuercas** (ganables) y **Núcleos**
  (premium, para skins). Recompensas por recolectar, combatir y por login diario.
- **Batallas PvP probabilísticas** basadas en las habilidades de cada Beyblade,
  con matchmaking real entre jugadores y **bot escalado** de respaldo. El
  servidor es autoritativo; el cliente solo reproduce el resultado.
- **Tienda de skins desarrolladas** (materiales emisivos, auras de partículas,
  estelas) compradas con Núcleos.
- **Sistema de Prestigio**: fusiona 3 duplicados para subir un Beyblade de rareza.
- **UI completa**: HUD, colección con previews 3D en vivo, tienda, recompensa
  diaria y arena de batalla cinematográfica con cámara, choques y barras de
  resistencia.
- **Persistencia** con DataStore (autosave + guardado al salir y al cerrar).
- **Monetización** lista vía Developer Products (solo faltan tus IDs).

---

## 📂 Estructura del proyecto

```
src/
├── Shared/        → ReplicatedStorage.Shared  (lógica y datos compartidos)
│   ├── Config.lua            Tunables globales (balance, drops, economía)
│   ├── RarityData.lua        Rarezas + tirada ponderada
│   ├── CategoryData.lua      Arquetipos, elementos y afinidades
│   ├── BeybladeData.lua      Catálogo de Beyblades + stats efectivos
│   ├── SkinData.lua          Catálogo de skins
│   ├── BattleResolver.lua    Simulación probabilística determinista (semilla)
│   ├── ModelBuilder.lua      Generación 3D procedural de los trompos
│   ├── Net.lua               Definición central de remotes
│   └── Util.lua
├── Server/        → ServerScriptService.Server
│   ├── init.server.lua       Bootstrap + handlers de remotes + ciclo de vida
│   ├── DataService.lua       Perfil persistente (DataStore)
│   ├── EconomyService.lua    Monedas
│   ├── BeybladeService.lua   Inventario, equipar, prestigio
│   ├── SpawnService.lua      Spawns aleatorios en el mundo
│   ├── BattleService.lua     Matchmaking + resolución autoritativa
│   ├── ShopService.lua       Compra de skins
│   ├── RewardService.lua     Recompensa diaria
│   ├── MonetizationService.lua  Robux (Developer Products)
│   └── Hub.lua               Construcción procedural del mundo/arena
└── Client/        → StarterPlayer.StarterPlayerScripts.Client
    ├── init.client.lua       Bootstrap de UI + ruteo de resultados
    ├── UITheme.lua           Tokens de diseño + fábrica de UI
    ├── ClientState.lua       Caché del perfil + señal de cambios
    ├── App.lua               HUD, Colección, Tienda, Diario
    ├── BattleView.lua        Animación cinematográfica de la batalla
    ├── ViewportPreview.lua   Preview 3D rotatorio en la UI
    └── Toasts.lua            Notificaciones + popup de recolección
```

---

## 🛠️ Cómo abrirlo en Roblox Studio (lo que haces TÚ)

1. **Instala Roblox Studio** (https://create.roblox.com/).
2. **Instala Rokit** (gestor de toolchain) y luego Rojo:
   ```bash
   # https://github.com/rojo-rbx/rokit
   rokit install      # instala Rojo 7.4.4 según rokit.toml
   ```
   (Alternativa: instala Rojo manualmente y el plugin de Rojo para Studio.)
3. **Arranca el servidor de Rojo** en la carpeta del repo:
   ```bash
   rojo serve
   ```
4. En **Studio** → pestaña Plugins → **Rojo** → **Connect**. El árbol del juego
   se construirá solo.
5. Pulsa **Play** ▶️. Ya puedes recolectar trompos y combatir (contra un bot si
   estás solo).

> Para probar PvP real: Studio → Test → **Players: 2** → Start.

---

## 💰 Activar la monetización (lo que haces TÚ)

El juego funciona 100% sin esto. Para vender Núcleos por Robux:

1. En Studio/Creator Dashboard crea **Developer Products** (uno por paquete de
   Núcleos).
2. Abre `src/Server/MonetizationService.lua` y rellena la tabla `PRODUCTS` con
   tus IDs reales:
   ```lua
   local PRODUCTS = {
       [1234567] = 50,   -- "Puñado de Núcleos"
       [1234568] = 150,  -- "Bolsa de Núcleos"
   }
   ```
3. Para iniciar la compra desde la UI usa
   `MarketplaceService:PromptProductPurchase(player, productId)` (puedo añadir
   los botones cuando me pases los IDs).

---

## ⚖️ Balancear el juego

Casi todo se ajusta desde **`src/Shared/Config.lua`** (tiempos de spawn,
recompensas, varianza de combate, rondas, etc.) sin tocar la lógica. Para añadir
Beyblades nuevos edita `BeybladeData.lua`; para skins, `SkinData.lua`.

---

## 🚀 Roadmap sugerido (siguientes iteraciones)

- Tabla de clasificación (OrderedDataStore) y temporadas con ranking.
- Cofres/gacha con animación de apertura.
- Mallas/texturas premium modeladas en Blender para los trompos top.
- Eventos de jefe mundial y trompos de evento limitados.
- Chat de equipo y batallas 2v2.

> ¿Migración a producción? Cambia el DataStore crudo de `DataService.lua` por
> **ProfileService/ProfileStore** para session-locking (evita duplicación de
> ítems en saltos de servidor). La API está pensada para que el cambio sea fácil.
