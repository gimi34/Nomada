# Nómada

Nómada es un reproductor de música de escritorio hecho con Python, PySide6 y QML. En Windows 11 usa el estilo nativo Fluent (WinUI 3).

## Características

- **Biblioteca**: vista de canciones y vista de álbumes (agrupados por carpeta y etiquetas).
- **Carátulas**: muestra las portadas incluidas dentro de los archivos de audio.
- **Letras**: lee archivos `.lrc` junto a la canción o letras incluidas en el archivo. Si están sincronizadas, la línea actual se resalta mientras suena.
- **Información técnica**: formato, códec, calidad, tamaño y ubicación de cada pista.
- **Modos de reproducción**: aleatorio, repetir todo y repetir una.
- **Arrastrar y soltar**: suelta archivos o carpetas sobre la ventana para agregarlos.
- **"Abrir con…"**: acepta archivos pasados por línea de comandos.
- **Memoria**: al cerrar guarda la lista, la pista actual, el volumen y los modos de reproducción. Opcionalmente (Configuración → Sonido) sigue en el segundo donde se quedó y empieza a sonar sola al abrir.
- **Configuración**: página propia con tres pestañas:
  - **Personalización**: tema de la aplicación y botón para abrir el **mini reproductor**, una ventana pequeña que flota sobre las demás.
  - **Sonido**: dispositivo de salida (audífonos, bocinas, monitor… o el predeterminado de Windows), medidor de intensidad de los canales izquierdo y derecho, y calidad del audio que suena.
  - **Letras**: tamaño, alineación y posición de la letra, con vista previa.
- **Temas**: "Naranja y negro" o "Sistema", que sigue el modo claro u oscuro y el color de acento de Windows.

Formatos admitidos: MP3, FLAC, OGG, OGA, Opus, M4A, MP4, AAC, WAV, WMA y AIFF.

## Requisitos

- Python 3.10 o superior
- [PySide6](https://pypi.org/project/PySide6/) 6.8 o superior
- [mutagen](https://pypi.org/project/mutagen/) 1.47 o superior

## Instalación

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Uso

```powershell
python main.py
```

También puedes abrir archivos o carpetas directamente:

```powershell
python main.py "C:\Música\canción.mp3" "C:\Música\Álbum"
```

## Atajos de teclado

| Atajo | Acción |
| --- | --- |
| `Espacio` | Reproducir / pausar |
| `Ctrl + →` / `Ctrl + ←` | Siguiente / anterior |
| `→` / `←` | Adelantar / retroceder 5 segundos |
| `Ctrl + ↑` / `Ctrl + ↓` | Subir / bajar volumen |
| `M` | Silenciar |
| `Ctrl + 1` | Canciones |
| `Ctrl + 2` | Álbumes |
| `Ctrl + 3` | Letra |
| `Ctrl + I` | Información de la pista |
| `Ctrl + ,` | Abrir / cerrar Configuración |
| `Esc` | Salir de Configuración |
| `Ctrl + O` | Agregar archivos |

Las teclas multimedia del teclado (reproducir, pausar, siguiente, anterior) también funcionan.

## Estructura del proyecto

```
main.py          Punto de entrada: crea la aplicación y carga la interfaz QML
player.py        Lógica de reproducción, cola, modos y persistencia
playlist.py      Modelo de la lista de canciones
albums.py        Modelo de álbumes
metadata.py      Lectura de etiquetas, carátulas, letras e información técnica (mutagen)
covers.py        Proveedor de carátulas para QML (image://cover/…)
levels.py        Medidor de intensidad de los canales izquierdo y derecho
settings.py      Preferencias de la aplicación (tema)
qml/             Interfaz de usuario
```

## Datos guardados

Las preferencias y la lista se guardan con `QSettings`. En Windows quedan en el registro, en
`HKEY_CURRENT_USER\Software\Nomada\Nomada`, no en la carpeta del proyecto.
