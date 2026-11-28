# Nómada

Nómada es un reproductor de música de escritorio hecho con Python, PySide6 y QML. En Windows 11 usa el estilo nativo Fluent (WinUI 3).

## Características

- **Biblioteca**: vista de canciones y vista de álbumes (agrupados por carpeta y etiquetas).
- **Buscador**: filtra canciones o álbumes mientras escribes, sin importar mayúsculas ni acentos ("cancion" encuentra "Canción").
- **Carátulas**: muestra las portadas incluidas dentro de los archivos de audio. En las vistas Canciones y Letra, la portada de lo que suena aparece difuminada de fondo.
- **Letras**: lee archivos `.lrc` junto a la canción o letras incluidas en el archivo. Si están sincronizadas, la línea actual se resalta mientras suena. Haz clic en la portada del panel de reproducción para ver la letra ahí mismo, y en la miniatura para volver a la portada.
- **Mini reproductor**: una ventana pequeña que flota sobre las demás (`Ctrl + M`, desde el menú lateral o desde Configuración → Personalización).
- **Integración con Windows**: las teclas multimedia del teclado controlan Nómada aunque la ventana no esté a la vista, y la canción aparece en el panel de medios de Windows (junto al volumen) con título, artista, carátula y barra de posición.
- **Información técnica**: formato, códec, calidad, tamaño y ubicación de cada pista.
- **Modos de reproducción**: aleatorio, repetir todo y repetir una.
- **Arrastrar y soltar**: suelta archivos o carpetas sobre la ventana para agregarlos.
- **"Abrir con…"**: acepta archivos pasados por línea de comandos.
- **Memoria**: guarda al momento la lista, la pista actual, el volumen y los modos de reproducción, así que no se pierde nada aunque la aplicación se cierre de golpe. Opcionalmente (Configuración → Sonido) sigue en el segundo donde se quedó y empieza a sonar sola al abrir.
- **Configuración**: página propia con tres pestañas:
  - **Personalización**: tema de la aplicación y botón para abrir el mini reproductor.
  - **Sonido**: dispositivo de salida (audífonos, bocinas, monitor… o el predeterminado de Windows), medidor de intensidad de los canales izquierdo y derecho, y calidad del audio que suena.
  - **Letras**: tamaño, alineación y posición de la letra, con vista previa.
- **Temas**: siete temas oscuros (Naranja y negro, Midnight, Forest, Sunset, Arctic, Burgundy y Monochrome) y "Sistema", que sigue el modo claro u oscuro y el color de acento de Windows.

Formatos admitidos: MP3, FLAC, OGG, OGA, Opus, M4A, MP4, AAC, WAV, WMA y AIFF.

## Descargar (Windows)

En la página de [Releases](https://github.com/gimi34/Nomada/releases) hay dos opciones:

| Archivo | Qué es |
| --- | --- |
| `NomadaSetup-<versión>.exe` | Instalador: crea el acceso en el menú Inicio y aparece en *Aplicaciones instaladas*. |
| `Nomada-<versión>-windows.zip` | Versión portable: no se instala, se usa desde cualquier carpeta o un USB. |

### Instalador

Ejecuta `NomadaSetup-<versión>.exe` y sigue los pasos. No pide permisos de administrador si eliges instalar solo para tu usuario. Para actualizar, instala la versión nueva encima de la anterior: no hace falta desinstalar.

### Versión portable

1. **Descomprime el zip**: clic derecho sobre `Nomada-<versión>-windows.zip` → *Extraer todo…* y elige una carpeta (Documentos, el escritorio, un USB…). No lo abras desde dentro del zip: el programa necesita todos sus archivos al lado.
2. Abre la carpeta `Nomada` que se crea al extraer.
3. Haz doble clic en **`Nomada.exe`**. La carpeta `_internal` que está junto a él tiene que quedarse ahí: contiene todo lo que el programa necesita.

Para abrirlo más cómodo, crea un acceso directo: clic derecho en `Nomada.exe` → *Mostrar más opciones* → *Enviar a* → *Escritorio (crear acceso directo)*. No muevas el `.exe` solo fuera de su carpeta.

Para quitarla, borra la carpeta. Ten en cuenta que los ajustes y la lista no se guardan en esa carpeta, sino en el registro de Windows (ver [Datos guardados](#datos-guardados)). Por eso la versión portable y la instalada comparten configuración en el mismo equipo, y en otra computadora empieza con la lista vacía.

### Si Windows lo bloquea

Nómada no está firmado digitalmente, así que Windows puede desconfiar de un archivo descargado:

- **"Windows protegió su PC"** (SmartScreen): pulsa *Más información* → *Ejecutar de todas formas*.
- **Zip descargado**: antes de extraerlo, clic derecho → *Propiedades* → marca **Desbloquear** → *Aceptar*.
- **Control inteligente de aplicaciones** (Smart App Control): si está activado, bloquea los programas sin firma y no admite excepciones por programa. El instalador puede quedar bloqueado; la **versión portable** suele funcionar. Si tampoco arranca, usa Nómada desde el código fuente (ver abajo), que se ejecuta con el `python.exe` oficial, que sí está firmado.

## Ejecutar desde el código fuente

### Requisitos

- Python 3.10 o superior
- [PySide6](https://pypi.org/project/PySide6/) 6.8 o superior
- [mutagen](https://pypi.org/project/mutagen/) 1.47 o superior
- [winrt](https://pypi.org/project/winrt-runtime/) 3 o superior (solo Windows: teclas multimedia y panel de medios; se instala solo con `requirements.txt`)

### Instalación

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Uso

```powershell
python main.py
```

También puedes abrir archivos o carpetas directamente:

```powershell
python main.py "C:\Música\canción.mp3" "C:\Música\Álbum"
```

Para abrirlo sin ventana de consola, usa `pythonw main.py`.

## Atajos de teclado

| Atajo | Acción |
| --- | --- |
| `Espacio` | Reproducir / pausar |
| `Ctrl + →` / `Ctrl + ←` | Siguiente / anterior |
| `→` / `←` | Adelantar / retroceder 5 segundos |
| `Ctrl + ↑` / `Ctrl + ↓` | Subir / bajar volumen |
| `M` | Silenciar |
| `Ctrl + F` | Buscar |
| `Ctrl + 1` | Canciones |
| `Ctrl + 2` | Álbumes |
| `Ctrl + 3` | Letra |
| `Ctrl + I` | Información de la pista |
| `Ctrl + M` | Abrir / cerrar el mini reproductor |
| `Ctrl + ,` | Abrir / cerrar Configuración |
| `Esc` | Salir de Configuración |
| `Ctrl + O` | Agregar archivos |

Las teclas multimedia del teclado (reproducir, pausar, siguiente, anterior) funcionan aunque Nómada esté minimizado o en segundo plano.

## Crear el instalador y la versión portable

Con el entorno instalado (ver arriba) y [Inno Setup 6](https://jrsoftware.org/isinfo.php):

1. Cambia el número de versión en la línea `#define AppVersion` de `Nomada.iss`.
2. Genera el programa con PyInstaller (queda en `dist\Nomada`):

   ```powershell
   python -m pip install pyinstaller
   python -m PyInstaller --noconfirm --clean --name Nomada --windowed --add-data "qml;qml" main.py
   ```

3. Genera el instalador (queda en `dist\NomadaSetup-<versión>.exe`):

   ```powershell
   & "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" Nomada.iss
   ```

4. Genera la versión portable:

   ```powershell
   Compress-Archive -Path dist\Nomada -DestinationPath dist\Nomada-<versión>-windows.zip -Force
   ```

## Estructura del proyecto

```
main.py            Punto de entrada: crea la aplicación y carga la interfaz QML
player.py          Lógica de reproducción, cola, modos y persistencia
playlist.py        Modelo de la lista de canciones
albums.py          Modelo de álbumes
search.py          Filtro del buscador (sin mayúsculas ni acentos)
metadata.py        Lectura de etiquetas, carátulas, letras e información técnica (mutagen)
covers.py          Proveedor de carátulas para QML (image://cover/…)
levels.py          Medidor de intensidad de los canales izquierdo y derecho
media_controls.py  Teclas multimedia y panel de medios de Windows
settings.py        Preferencias de la aplicación (tema, sonido, letras)
bench.py           Mide el rendimiento (arranque, buscador, álbumes, medidor) con tu biblioteca
Nomada.iss         Script del instalador (Inno Setup)
qml/               Interfaz de usuario
qml/images/        Icono, símbolo y pantalla de carga (recortados de iconos/iconos.jpg)
iconos/            Hoja de iconos original y nomada.ico (icono del .exe y del instalador)
```

## Datos guardados

Las preferencias y la lista se guardan con `QSettings`. En Windows quedan en el registro, en
`HKEY_CURRENT_USER\Software\Nomada\Nomada`, no en la carpeta del programa. Lo comparten la
versión instalada, la portable y la del código fuente.
