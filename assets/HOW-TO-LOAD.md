# 📥 Cómo cargar los assets premium en Roblox

Guía paso a paso para meter en el juego las imágenes, texturas, mallas 3D y audio
generados con IA. Aplica a todo lo que esté en tu cuenta de Higgsfield.

> ⚠️ Importante: los archivos viven en **tu cuenta de Higgsfield** (yo no puedo
> descargarlos al repo por una restricción de red del entorno). Tú los descargas
> del panel y los subes a Roblox. El resto (pegar IDs) es trivial.

---

## Paso 0 — Descargar de Higgsfield
En tu panel de Higgsfield → **Generations / History**:
- **Imágenes** → botón de descargar → `.png`
- **Mallas 3D** → descargar → `.glb`
- **Audio** → descargar → `.mp3`

(Pídele a Claude `show_generations` para verlas y ubicarlas por su `job id`.)

---

## 1) Imágenes y texturas → ID de Roblox

**Subir:**
1. En Studio, abre **Recursos** (Asset Manager), arriba en la pestaña **Inicio**.
2. Click derecho en **Imágenes** → **Agregar imágenes…** (Import) → elige el `.png`.
3. Espera la aprobación de moderación (suele ser rápida). Aparece con un **ID**.
4. Click derecho sobre la imagen → **Copiar ID del recurso** (Copy Asset ID).

**Pegar el ID en el código** (`src/Shared/Assets.lua`):
- Logo, íconos de moneda, renders de skins/blades → tabla `Images`
  (`Logo`, `BoltsIcon`, `CoresIcon`, `Skin_molten`, etc.).
- **Textura de ciudad** → `Assets.Textures.CityFacade`.
  En cuanto la pegues, **los edificios la usan solos** (ya está cableado).

Formato: `Skin_molten = "rbxassetid://123456789"`.

---

## 2) Mallas 3D (GLB) → MeshPart

**Importar:**
1. En Studio, pestaña **Avatar** (o **Inicio**) → botón **Importar 3D** (Import 3D).
   - Si no lo ves: **Recursos** (Asset Manager) → click derecho en **Mallas
     (Meshes)** → **Agregar mallas**.
2. Selecciona el `.glb`. Se abre el **Importador 3D** con una vista previa.
3. Ajusta escala si hace falta y pulsa **Importar** (Insert). Se crea un
   **MeshPart** (o un Modelo con MeshParts) en el **Workspace**.
4. Selecciónalo → en **Propiedades** verás **MeshId** y **TextureID**.

**Cómo usarlas (2 opciones):**
- **Rápido (display):** arrastra el MeshPart donde quieras (un monumento, una
  vitrina en el mercado, pantalla de carga). Ánclalo (Anchored ✔).
- **Integrarlas al juego (lo potente):** pásame el **MeshId** (y TextureID) de
  cada trompo y yo conecto las mallas para que **reemplacen el modelo procedural**
  en batalla, colección y cofres. (Añado un campo `MeshId` por blade y hago que
  el constructor use la malla cuando exista.) Es un paso que hago yo; tú solo me
  das los IDs.

> Nota: Roblox importa **.glb/.gltf, .fbx y .obj**. Si una malla sale muy
> grande/chica, ajusta la escala en el importador o el `Size` del MeshPart.

---

## 3) Audio (música y SFX) → ID de Roblox

1. **Recursos** (Asset Manager) → click derecho en **Audio** → **Agregar audio**
   → elige el `.mp3`. (El audio pasa por **moderación**; puede tardar un poco.)
2. Copia el **ID** y pégalo en `src/Shared/Assets.lua`:
   - SFX → `Assets.Sounds` (`Launch`, `Clash`, `Spin`, `Victory`, `Defeat`,
     `Collect`).
   - Música → `Assets.Music` (`Menu`, `Battle`).
3. Ya están cableados (crossfade menú/batalla, toggles). Funcionan al pegar el ID.

> Estado actual: la **generación** de audio con Higgsfield está pidiendo una
> aprobación que no se está concediendo en esta sesión. La **imagen y el 3D sí
> funcionan**. Para el audio: reintenta en una sesión nueva, o usa pistas/SFX
> propios (mismo proceso de subida).

---

## 4) Después de pegar los IDs

- Si trabajas con el **archivo `.rbxlx`**: avísame y te **genero uno nuevo** ya
  con los IDs integrados (texturas, etc.).
- Si usas **Rojo** (sync en vivo): vuelve a sincronizar y listo.

---

## 📌 Resumen rápido
| Asset | Subir en | Pegar ID en |
|---|---|---|
| Logo / íconos / skins | Recursos → Imágenes | `Assets.Images` |
| Textura de ciudad | Recursos → Imágenes | `Assets.Textures.CityFacade` |
| Mallas 3D de blades | Importar 3D (GLB) | (me pasas el MeshId y lo cableo) |
| SFX | Recursos → Audio | `Assets.Sounds` |
| Música | Recursos → Audio | `Assets.Music` |
