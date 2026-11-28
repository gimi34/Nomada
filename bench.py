"""Mide las rutas calientes de Nómada con tu biblioteca real (lee la lista guardada).

Uso:  .venv/Scripts/python.exe bench.py
Compara los números con los presupuestos de CLAUDE.md antes y después de un cambio.
"""
import json
import os
import statistics
import sys
import time

from PySide6.QtCore import QSettings
from PySide6.QtGui import QGuiApplication
from PySide6.QtMultimedia import QAudioBuffer, QAudioFormat, QMediaPlayer

QGuiApplication.setOrganizationName("Nomada")
QGuiApplication.setApplicationName("Nomada")
app = QGuiApplication(sys.argv)

from albums import AlbumModel  # noqa: E402
from covers import CoverProvider  # noqa: E402
from levels import LevelMeter  # noqa: E402
from metadata import read_track  # noqa: E402
from playlist import PlaylistModel  # noqa: E402
from search import SearchFilterModel  # noqa: E402


def timed(fn, repeat=5):
    """Mediana en milisegundos de `repeat` ejecuciones."""
    samples = []
    for _ in range(repeat):
        t = time.perf_counter()
        fn()
        samples.append((time.perf_counter() - t) * 1000)
    return statistics.median(samples)


paths = [p for p in json.loads(QSettings().value("playlist", "[]", type=str)) if os.path.isfile(p)]
if not paths:
    sys.exit("No hay canciones en la lista guardada: abre Nómada y agrega música primero.")
covers = CoverProvider()

tracks = [read_track(p) for p in paths]  # calienta la caché de disco
results = {"canciones": len(paths)}
results["leer etiquetas (arranque)"] = timed(lambda: [read_track(p) for p in paths], 3)

model = PlaylistModel(covers)
model.append(tracks)
albums = AlbumModel(model, covers)
results["reconstruir álbumes"] = timed(albums.rebuild)

songs = SearchFilterModel(model)
def type_query():
    for i in range(1, 6):  # simula teclear "alvar" letra por letra
        songs.filterText = "alvaro"[:i]
        songs.rowCount()  # Qt filtra al pedir las filas, como hace la vista
    songs.filterText = ""
    songs.rowCount()
results["buscador, por tecla"] = timed(type_query) / 6

fmt = QAudioFormat()
fmt.setSampleFormat(QAudioFormat.SampleFormat.Int32)
fmt.setChannelCount(2)
fmt.setSampleRate(48000)
buffer = QAudioBuffer(bytes(4608 * 2 * 4), fmt)  # bloque típico de Qt: 4608 frames, ~96 ms
meter = LevelMeter(QMediaPlayer())
results["medidor, por bloque de audio (~96 ms)"] = timed(lambda: meter._on_buffer(buffer), 20)

for name, value in results.items():
    print(f"{name:40} {value:9.1f}" + ("" if name == "canciones" else " ms"))
