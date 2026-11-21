import math
import time
from collections import deque

from PySide6.QtCore import QObject, QTimer, Property, Signal
from PySide6.QtMultimedia import QAudioBufferOutput, QAudioFormat, QMediaPlayer

FLOOR_DB = -60.0      # lo más bajo que muestra el medidor
FALL_DB_PER_S = 30.0  # caída de la barra
HOLD_S = 1.2          # tiempo que se queda la marca de pico
PEAK_FALL_DB_PER_S = 15.0
SLICE_FRAMES = 1024   # Qt entrega ~100 ms por bloque; se reparte en trozos de ~20 ms

# formato de muestra -> (código de array, valor de escala completa, desplazamiento)
_FORMATS = {
    QAudioFormat.SampleFormat.UInt8: ("B", 128.0, 128),
    QAudioFormat.SampleFormat.Int16: ("h", 32768.0, 0),
    QAudioFormat.SampleFormat.Int32: ("i", 2147483648.0, 0),
    QAudioFormat.SampleFormat.Float: ("f", 1.0, 0),
}


def _to_db(amplitude: float) -> float:
    return max(FLOOR_DB, 20 * math.log10(amplitude)) if amplitude > 0 else FLOOR_DB


class LevelMeter(QObject):
    """Nivel de pico (dBFS) de los canales izquierdo y derecho de lo que suena.

    Solo analiza el audio mientras `active` es verdadero (la página de Sonido
    está a la vista), para no gastar CPU el resto del tiempo.
    """

    changed = Signal()
    activeChanged = Signal()

    def __init__(self, media: QMediaPlayer, parent=None):
        super().__init__(parent)
        self._media = media
        self._output = QAudioBufferOutput(self)
        self._output.audioBufferReceived.connect(self._on_buffer)
        self._active = False
        self._pending: deque[tuple[float, float, float]] = deque()  # (cuándo suena, izq, der)
        self._level = [FLOOR_DB, FLOOR_DB]
        self._peak = [FLOOR_DB, FLOOR_DB]
        self._peak_time = [0.0, 0.0]
        self._last_tick = time.monotonic()
        self._timer = QTimer(self, interval=33)
        self._timer.timeout.connect(self._tick)

    # ---------------------------------------------------------------- análisis
    def _on_buffer(self, buffer):
        fmt = buffer.format()
        spec = _FORMATS.get(fmt.sampleFormat())
        channels = fmt.channelCount()
        rate = fmt.sampleRate()
        if spec is None or channels < 1 or rate <= 0:
            return
        code, full_scale, offset = spec
        samples = buffer.constData().cast(code)
        frames = len(samples) // channels
        now = time.monotonic()
        right_channel = 1 if channels > 1 else 0
        for start in range(0, frames, SLICE_FRAMES):
            chunk = samples[start * channels:min(frames, start + SLICE_FRAMES) * channels]
            levels = []
            for ch in (0, right_channel):
                values = chunk[ch::channels]
                peak = max(max(values) - offset, offset - min(values)) / full_scale
                levels.append(_to_db(peak))
            self._pending.append((now + start / rate, levels[0], levels[1]))
        if not self._timer.isActive():
            self._last_tick = now
            self._timer.start()

    def _tick(self):
        now = time.monotonic()
        dt, self._last_tick = now - self._last_tick, now
        due = [FLOOR_DB, FLOOR_DB]
        while self._pending and self._pending[0][0] <= now:
            _, left, right = self._pending.popleft()
            due = [max(due[0], left), max(due[1], right)]

        for ch in (0, 1):
            self._level[ch] = max(due[ch], self._level[ch] - FALL_DB_PER_S * dt, FLOOR_DB)
            if due[ch] >= self._peak[ch]:
                self._peak[ch], self._peak_time[ch] = due[ch], now
            elif now - self._peak_time[ch] > HOLD_S:
                self._peak[ch] = max(FLOOR_DB, self._peak[ch] - PEAK_FALL_DB_PER_S * dt)
        self.changed.emit()

        # En pausa o al terminar: parar el temporizador cuando todo llegó a cero
        if not self._pending and all(v <= FLOOR_DB for v in self._level + self._peak):
            self._timer.stop()

    def _reset(self):
        self._pending.clear()
        self._level = [FLOOR_DB, FLOOR_DB]
        self._peak = [FLOOR_DB, FLOOR_DB]
        self._timer.stop()
        self.changed.emit()

    # -------------------------------------------------------------- propiedades
    def _get_active(self):
        return self._active

    def _set_active(self, active):
        active = bool(active)
        if active == self._active:
            return
        self._active = active
        self._media.setAudioBufferOutput(self._output if active else None)
        if not active:
            self._reset()
        self.activeChanged.emit()

    active = Property(bool, _get_active, _set_active, notify=activeChanged)
    left = Property(float, lambda self: self._level[0], notify=changed)
    right = Property(float, lambda self: self._level[1], notify=changed)
    leftPeak = Property(float, lambda self: self._peak[0], notify=changed)
    rightPeak = Property(float, lambda self: self._peak[1], notify=changed)
    floor = Property(float, lambda self: FLOOR_DB, constant=True)
