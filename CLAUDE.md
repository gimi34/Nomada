# Nómada — guía para Claude

Reproductor de música de escritorio: Python 3.14 + PySide6 6.12 (QML, estilo FluentWinUI3) + mutagen.
Responde siempre en español. Entorno: `.venv` creado con `uv` (no tiene `pip`; instala con
`uv pip install --python .venv/Scripts/python.exe <paquete>`).

## Antes de implementar algo: consulta el grafo

El grafo de graphify (`graphify-out/graph.json`, ignorado por git) es el mapa del código Python.
Úsalo para saber dónde va un cambio y qué toca, antes de leer archivos:

```bash
.venv/Scripts/python.exe -m graphify query "¿qué usa X / dónde se guarda Y?"   # contexto amplio
.venv/Scripts/python.exe -m graphify path "player_player" "levels_levelmeter"   # cómo se conectan dos cosas
.venv/Scripts/python.exe -m graphify explain "PlaylistModel"                    # qué es un nodo
.venv/Scripts/python.exe -m graphify update .                                   # tras cambiar código (sin LLM)
```

- Si un nombre es ambiguo (p. ej. `Player` es la clase y también `player.py`), usa el ID del nodo
  (`archivo_clase` en minúsculas: `player_player`); `explain` lo muestra.
- Ejecuta `graphify update .` al terminar cada cambio de código, para que el grafo no quede viejo.
- Límites del grafo: **no contiene los `.qml`** (búscalos con Grep en `qml/`), y los nodos `readme_*`
  del README no están unidos a los del código.
- No llames a `.venv/Scripts/graphify.exe`: Smart App Control lo bloquea. Usa `python -m graphify`.

## Arquitectura (según el grafo)

- **`Player`** (`player.py`) es el director: es dueño de `PlaylistModel`, `AlbumModel`, `LevelMeter`
  y usa `CoverProvider`. Es el nodo más conectado (62 aristas) y el puente entre comunidades.
  QML solo habla con las propiedades de contexto de `main.py`: `player`, `appSettings`,
  `songSearch`, `albumSearch`, `iconFont`.
- **Una función nueva con estado propio va en su propia clase y archivo**, como `levels.py`
  (`LevelMeter`): `Player` la crea y la expone con una `Property(QObject, ..., constant=True)`.
  No sigas engordando `Player` (ya tiene 56 métodos). Candidato a extraer si crece: la salida de
  audio (`player.py`, sección "salida audio"), que el grafo ya separa como comunidad propia.
- **Controles multimedia de Windows:** `media_controls.py` (`MediaControls`, creado en `main.py`)
  escucha las señales de `Player` y publica en SMTC; los botones del sistema llegan por señales en cola.
  El hilo de la interfaz es STA: **nunca llames a `.get()` de una operación WinRT ahí** (lanza
  `get() cannot block a single-threaded apartment`); hazlo en `QThreadPool`.
- **Preferencias:** `settings.py` → `OPTIONS` (opciones de texto) y `FLAGS` (interruptores).
  `AppSettings` las expone a QML; `Player` lee `QSettings` usando `FLAGS` como valor por defecto.
- **Metadatos:** todo pasa por `metadata.py`. `read_track` se ejecuta una vez por canción al arrancar.
- **Marca:** las imágenes de `qml/images/` salen de la hoja `iconos/iconos.jpg` (JPG sin transparencia:
  el símbolo se recortó quitando el fondo por color). El símbolo sin fondo se ve lavado sobre claro:
  usa `AppLogo.qml`, que cambia al icono con cuadro en temas claros. `main.py` usa `QApplication`
  (no `QGuiApplication`) solo por la pantalla de carga (`QSplashScreen`).
- **Configuración en la interfaz:** `qml/SettingsView.qml` (pestañas) + `SettingsCard` para agrupar;
  la pestaña Sonido vive en `qml/SoundSettings.qml`.

## Reglas de rendimiento

Mide antes y después con `bench.py` (usa la biblioteca real guardada en QSettings, 1468 canciones):

```bash
.venv/Scripts/python.exe bench.py
```

| Ruta caliente | Medido (2026-11-21) | Presupuesto |
|---|---|---|
| Leer etiquetas al arrancar (`read_track` × N) | 1,2–1,5 s | no subir; ~1 ms por canción |
| Buscador, por tecla (`SearchFilterModel`) | 4,6–9,9 ms | < 16 ms (un fotograma) |
| Reconstruir álbumes (`AlbumModel.rebuild`) | 11–15 ms | < 16 ms |
| Medidor, por bloque de audio (~96 ms) | 0,2–0,4 ms | < 2 ms |

1. **Abre cada archivo de audio una sola vez.** Reutiliza el objeto de mutagen (patrón `_cover_from`).
   Nada nuevo por canción en el arranque sin medirlo: multiplica por el tamaño de la biblioteca.
2. **Lo que corre por tecla, por fotograma o por bloque de audio no recalcula lo que no cambia:**
   precalcula o memoriza (como `normalize` con `lru_cache`).
3. **Lo costoso solo mientras se ve:** el medidor se activa con `active` cuando la pestaña Sonido está
   visible; el blur en vivo (`MultiEffect` + `ShaderEffectSource`) solo mientras su diálogo está abierto.
4. **No bloquees el hilo de la interfaz** con trabajo largo (lectura de muchos archivos, red):
   si algo nuevo pasa de ~50 ms, muévelo a un hilo (`QThreadPool`) o divídelo.
5. **Verifica cada optimización comparando versión vieja y nueva intercaladas** (la máquina tiene
   mucho ruido entre corridas: hasta ×2). Si no supera la variación, se revierte. Anótala abajo.

## Registro de optimizaciones

| Idea | Antes → después | Veredicto | Por qué |
|---|---|---|---|
| `read_track` reutiliza el archivo abierto para saber si hay carátula | 2,2–2,3 s → 1,2 s | mantenida | Se abría cada archivo dos veces |
| `normalize()` con `lru_cache` en el buscador | mediana 9,8 → 4,95 ms por tecla | mantenida | Normalizaba 1468 textos en cada tecla |
| Siguiente candidata (no hecha): caché en disco de etiquetas por ruta + fecha de modificación | — | pendiente | Solo si el arranque molesta; cambio grande |

## Cómo verificar cambios

- Interfaz: no hay tests de QML. Lanza la app con un script que cargue `qml/Main.qml`, conecte
  `engine.warnings` y guarde capturas con `win.grabWindow()`; revisa las capturas.
- Pruebas que guardan ajustes: usa un almacén aparte (`setOrganizationName("NomadaTest")`) y bórralo
  al final. No toques los ajustes reales del usuario; si cambias el volumen para probar, restáuralo.
- Empaquetado: `python -m PyInstaller --noconfirm --clean --name Nomada --windowed --add-data "qml;qml" main.py`
  y luego `ISCC Nomada.iss` (Inno Setup en `%LOCALAPPDATA%\Programs\Inno Setup 6`).
  **No uses `--icon`:** incrustar el icono cambia la huella del .exe y Smart App Control lo bloquea
  (sin él conserva la del lanzador de PyInstaller y arranca; comprobado el 2026-11-27). El logo llega
  igual a la ventana (`setWindowIcon`) y a los accesos directos (`nomada.ico` en `Nomada.iss`).
  El instalador de Inno puede bloquearse según la versión, con o sin icono: pruébalo antes de publicar.
