import bisect
import json
import os
import random
from pathlib import Path

from PySide6.QtCore import QObject, QSettings, QTimer, QUrl, Property, Signal, Slot
from PySide6.QtMultimedia import QAudioOutput, QMediaDevices, QMediaPlayer

from albums import AlbumModel
from covers import CoverProvider
from levels import LevelMeter
from metadata import AUDIO_EXTENSIONS, read_audio_info, read_lyrics, read_track
from playlist import PlaylistModel
from settings import FLAGS

REPEAT_OFF, REPEAT_ALL, REPEAT_ONE = 0, 1, 2


def _collect_audio_files(path: str) -> list[str]:
    if os.path.isdir(path):
        found = []
        for root, dirs, files in os.walk(path):
            dirs.sort()
            found += [os.path.join(root, f) for f in sorted(files)
                      if Path(f).suffix.lower() in AUDIO_EXTENSIONS]
        return found
    if os.path.isfile(path) and Path(path).suffix.lower() in AUDIO_EXTENSIONS:
        return [path]
    return []


def _device_id(device) -> str:
    return bytes(device.id().data()).decode("utf-8", "replace")


class Player(QObject):
    playingChanged = Signal()
    positionChanged = Signal()
    durationChanged = Signal()
    trackChanged = Signal()
    volumeChanged = Signal()
    modeChanged = Signal()
    queueChanged = Signal()
    lyricsChanged = Signal()
    lyricIndexChanged = Signal()
    audioDevicesChanged = Signal()
    audioDeviceChanged = Signal()
    outputDeviceChanged = Signal()

    def __init__(self, covers: CoverProvider, parent=None):
        super().__init__(parent)
        self._covers = covers
        self._model = PlaylistModel(covers, self)
        self._albums = AlbumModel(self._model, covers, self)
        self._audio = QAudioOutput(self)
        self._media = QMediaPlayer(self)
        self._media.setAudioOutput(self._audio)
        self._meter = LevelMeter(self._media, self)
        self._index = -1
        self._album_key = ""  # "" = se reproduce toda la lista
        self._shuffle = False
        self._repeat = REPEAT_OFF
        self._lyrics: list[tuple[int, str]] = []
        self._lyric_times: list[int] = []
        self._lyrics_synced = False
        self._lyric_index = -1
        self._audio_info: dict = {}
        # Al abrir: posición y reproducción que se aplican cuando la canción termina de cargar
        # (Qt ignora setPosition antes de eso)
        self._pending_seek = 0
        self._pending_play = False
        self._audio.deviceChanged.connect(self.outputDeviceChanged)
        self._device_pref = ""  # "" = salida predeterminada del sistema
        self._devices = QMediaDevices(self)
        self._devices.audioOutputsChanged.connect(self._on_outputs_changed)

        self._media.playbackStateChanged.connect(lambda *_: self.playingChanged.emit())
        self._media.positionChanged.connect(self._on_position)
        self._media.durationChanged.connect(lambda *_: self.durationChanged.emit())
        self._media.mediaStatusChanged.connect(self._on_status)
        self._media.errorOccurred.connect(lambda _e, msg: print(f"[reproductor] Error: {msg}"))
        self._audio.mutedChanged.connect(lambda *_: self.volumeChanged.emit())

        self._restore()

        # Guardar al momento cada cambio (no solo al cerrar): así no se pierde
        # nada aunque se cierre la terminal o la app termine de golpe.
        self._save_timer = QTimer(self, singleShot=True, interval=500)
        self._save_timer.timeout.connect(self.save)
        for signal in (self.trackChanged, self.queueChanged, self.modeChanged,
                       self.volumeChanged, self.audioDeviceChanged, self.playingChanged,
                       self._model.countChanged):
            signal.connect(self._save_timer.start)

    # ------------------------------------------------------------------ estado
    def _track(self):
        return self._model.at(self._index)

    def _get_playing(self):
        return self._media.playbackState() == QMediaPlayer.PlaybackState.PlayingState

    def _get_position(self):
        return self._media.position()

    def _get_duration(self):
        d = self._media.duration()
        t = self._track()
        return d if d > 0 or t is None else t.duration

    def _get_index(self):
        return self._index

    def _get_title(self):
        t = self._track()
        return t.title if t else ""

    def _get_artist(self):
        t = self._track()
        return t.artist if t else ""

    def _get_album(self):
        t = self._track()
        return t.album if t else ""

    def _get_cover(self):
        return self._covers.url_for(self._track())

    def _get_volume(self):
        return self._audio.volume()

    def _set_volume(self, v):
        v = max(0.0, min(1.0, float(v)))
        if v != self._audio.volume():
            self._audio.setVolume(v)
            self.volumeChanged.emit()

    def _get_muted(self):
        return self._audio.isMuted()

    def _set_muted(self, m):
        self._audio.setMuted(bool(m))

    def _get_shuffle(self):
        return self._shuffle

    def _set_shuffle(self, s):
        self._shuffle = bool(s)
        self.modeChanged.emit()

    def _get_repeat(self):
        return self._repeat

    def _get_playlist(self):
        return self._model

    def _get_albums(self):
        return self._albums

    def _get_album_key(self):
        return self._album_key

    def _get_audio_info(self):
        return self._audio_info

    def _get_lyrics(self):
        return [{"time": t, "text": s} for t, s in self._lyrics]

    def _get_lyrics_synced(self):
        return self._lyrics_synced

    def _get_lyric_index(self):
        return self._lyric_index

    playing = Property(bool, _get_playing, notify=playingChanged)
    position = Property(int, _get_position, notify=positionChanged)
    duration = Property(int, _get_duration, notify=durationChanged)
    currentIndex = Property(int, _get_index, notify=trackChanged)
    title = Property(str, _get_title, notify=trackChanged)
    artist = Property(str, _get_artist, notify=trackChanged)
    album = Property(str, _get_album, notify=trackChanged)
    coverSource = Property(str, _get_cover, notify=trackChanged)
    volume = Property(float, _get_volume, _set_volume, notify=volumeChanged)
    muted = Property(bool, _get_muted, _set_muted, notify=volumeChanged)
    shuffle = Property(bool, _get_shuffle, _set_shuffle, notify=modeChanged)
    repeatMode = Property(int, _get_repeat, notify=modeChanged)
    playlist = Property(QObject, _get_playlist, constant=True)
    albums = Property(QObject, _get_albums, constant=True)
    albumKey = Property(str, _get_album_key, notify=queueChanged)
    audioInfo = Property("QVariantMap", _get_audio_info, notify=trackChanged)
    lyrics = Property("QVariantList", _get_lyrics, notify=lyricsChanged)
    lyricsSynced = Property(bool, _get_lyrics_synced, notify=lyricsChanged)
    lyricIndex = Property(int, _get_lyric_index, notify=lyricIndexChanged)

    # ------------------------------------------------------------ salida audio
    def _apply_device(self):
        """Usa la salida elegida; si no está conectada, la predeterminada."""
        outputs = QMediaDevices.audioOutputs()
        device = next((d for d in outputs if _device_id(d) == self._device_pref), None)
        if device is None:
            device = QMediaDevices.defaultAudioOutput()
        if device != self._audio.device():
            self._audio.setDevice(device)

    def _on_outputs_changed(self):
        # Se conectó/desconectó un dispositivo o cambió el predeterminado de Windows
        self._apply_device()
        self.audioDevicesChanged.emit()

    def _get_audio_devices(self):
        default = QMediaDevices.defaultAudioOutput()
        name = default.description() if not default.isNull() else ""
        items = [{"id": "", "name": f"Predeterminado del sistema ({name})" if name
                  else "Predeterminado del sistema"}]
        items += [{"id": _device_id(d), "name": d.description()}
                  for d in QMediaDevices.audioOutputs()]
        return items

    def _get_output_format(self):
        """Formato con el que trabaja el dispositivo de salida, p. ej. "48 kHz · Estéreo"."""
        device = self._audio.device()
        if device.isNull():
            return ""
        fmt = device.preferredFormat()
        rate = fmt.sampleRate()
        channels = fmt.channelCount()
        parts = []
        if rate:
            parts.append(f"{rate / 1000:g} kHz")
        if channels:
            parts.append({1: "Mono", 2: "Estéreo"}.get(channels, f"{channels} canales"))
        return " · ".join(parts)

    def _get_meter(self):
        return self._meter

    def _get_audio_device(self):
        return self._device_pref

    def _set_audio_device(self, device_id):
        device_id = str(device_id)
        if device_id != self._device_pref:
            self._device_pref = device_id
            self._apply_device()
            self.audioDeviceChanged.emit()

    audioDevices = Property("QVariantList", _get_audio_devices, notify=audioDevicesChanged)
    audioDevice = Property(str, _get_audio_device, _set_audio_device, notify=audioDeviceChanged)
    outputDeviceName = Property(str, lambda self: self._audio.device().description(), notify=outputDeviceChanged)
    outputFormat = Property(str, _get_output_format, notify=outputDeviceChanged)
    meter = Property(QObject, _get_meter, constant=True)

    # ------------------------------------------------------------------- cola
    def _set_album_key(self, key: str):
        if key != self._album_key:
            self._album_key = key
            self.queueChanged.emit()

    def _queue(self) -> list[int]:
        """Índices de la lista que se están reproduciendo, en orden."""
        if self._album_key:
            indices = self._albums.indices(self._album_key)
            if indices:
                return indices
            self._set_album_key("")  # el álbum ya no existe
        return list(range(len(self._model)))

    # ----------------------------------------------------------------- letras
    def _load_lyrics(self):
        t = self._track()
        self._lyrics, self._lyrics_synced = read_lyrics(t.path) if t else ([], False)
        self._lyric_times = [time for time, _ in self._lyrics]
        self._lyric_index = -1
        self.lyricsChanged.emit()
        self.lyricIndexChanged.emit()

    def _on_position(self, pos: int):
        self.positionChanged.emit()
        if self._lyrics_synced:
            i = bisect.bisect_right(self._lyric_times, pos) - 1
            if i != self._lyric_index:
                self._lyric_index = i
                self.lyricIndexChanged.emit()

    # ----------------------------------------------------------------- acciones
    def _load(self, i: int, play: bool = True):
        self._pending_seek, self._pending_play = 0, False
        self._index = i
        track = self._model.at(i)
        self._media.setSource(QUrl.fromLocalFile(track.path))
        self._audio_info = read_audio_info(track)
        self.trackChanged.emit()
        self.durationChanged.emit()
        self._load_lyrics()
        if play:
            self._media.play()

    def _unload(self):
        self._media.stop()
        self._media.setSource(QUrl())
        self._index = -1
        self._audio_info = {}
        self.trackChanged.emit()
        self.durationChanged.emit()
        self._load_lyrics()

    def _advance(self, auto: bool):
        queue = self._queue()
        if not queue:
            return
        if auto and self._repeat == REPEAT_ONE:
            self._media.setPosition(0)
            self._media.play()
            return
        if self._shuffle and len(queue) > 1:
            i = random.choice([j for j in queue if j != self._index])
        else:
            pos = queue.index(self._index) + 1 if self._index in queue else 0
            if pos >= len(queue):
                if auto and self._repeat == REPEAT_OFF:
                    self._media.stop()
                    return
                pos = 0
            i = queue[pos]
        self._load(i)

    def _on_status(self, status):
        if status == QMediaPlayer.MediaStatus.EndOfMedia:
            self._advance(auto=True)
        elif status == QMediaPlayer.MediaStatus.LoadedMedia:
            if self._pending_seek:
                self._media.setPosition(self._pending_seek)
            if self._pending_play:
                self._media.play()
            self._pending_seek, self._pending_play = 0, False

    @Slot()
    def togglePlay(self):
        if self._index < 0:
            queue = self._queue()
            if queue:
                self._load(queue[0])
        elif self._get_playing():
            self._media.pause()
        else:
            self._media.play()

    @Slot()
    def next(self):
        self._advance(auto=False)

    @Slot()
    def previous(self):
        queue = self._queue()
        if not queue:
            return
        if self._media.position() > 3000:
            self._media.setPosition(0)
            return
        pos = queue.index(self._index) - 1 if self._index in queue else -1
        self._load(queue[pos])  # pos = -1 vuelve a la última

    @Slot(int)
    def playIndex(self, i: int):
        """Reproduce desde la lista completa."""
        if 0 <= i < len(self._model):
            self._set_album_key("")
            self._load(i)

    @Slot(str)
    def playAlbum(self, key: str):
        self.playAlbumFrom(key, -1)

    @Slot(str, int)
    def playAlbumFrom(self, key: str, index: int):
        indices = self._albums.indices(key)
        if not indices:
            return
        self._set_album_key(key)
        self._load(index if index in indices else indices[0])

    @Slot(str)
    def shuffleAlbum(self, key: str):
        indices = self._albums.indices(key)
        if indices:
            self._set_shuffle(True)
            self.playAlbumFrom(key, random.choice(indices))

    @Slot(int)
    def seek(self, ms: int):
        self._media.setPosition(int(ms))

    @Slot()
    def cycleRepeat(self):
        self._repeat = (self._repeat + 1) % 3
        self.modeChanged.emit()

    @Slot("QVariantList")
    def addUrls(self, urls):
        paths = []
        for u in urls:
            local = QUrl(u).toLocalFile() or str(u)
            paths += _collect_audio_files(local)
        self.addPaths(paths)

    def addPaths(self, paths: list[str]):
        was_empty = self._index < 0
        first_new = len(self._model)
        self._model.append([read_track(p) for p in paths])
        if was_empty and len(self._model) > first_new:
            self._set_album_key("")
            self._load(first_new)

    @Slot(int)
    def removeAt(self, i: int):
        if not 0 <= i < len(self._model):
            return
        if i == self._index:
            self._unload()
        if i < self._index:
            self._index -= 1
        self._model.remove(i)
        self.trackChanged.emit()

    @Slot()
    def clear(self):
        self._unload()
        self._set_album_key("")
        self._model.clear()

    # ----------------------------------------------------------- persistencia
    def _restore(self):
        s = QSettings()
        self._audio.setVolume(s.value("volume", 0.8, type=float))
        self._device_pref = s.value("audioDevice", "", type=str)
        self._apply_device()
        self._shuffle = s.value("shuffle", False, type=bool)
        self._repeat = s.value("repeat", REPEAT_OFF, type=int)
        try:
            paths = json.loads(s.value("playlist", "[]", type=str))
        except ValueError:
            paths = []
        self._model.append([read_track(p) for p in paths if os.path.isfile(p)])
        self._album_key = s.value("album", "", type=str)
        index = s.value("index", -1, type=int)
        if 0 <= index < len(self._model):
            self._load(index, play=False)
            if s.value("resumePosition", FLAGS["resumePosition"], type=bool):
                self._pending_seek = s.value("position", 0, type=int)
            self._pending_play = s.value("autoplay", FLAGS["autoplay"], type=bool)

    @Slot()
    def save(self):
        s = QSettings()
        s.setValue("volume", self._audio.volume())
        s.setValue("audioDevice", self._device_pref)
        s.setValue("shuffle", self._shuffle)
        s.setValue("repeat", self._repeat)
        s.setValue("playlist", json.dumps(self._model.paths()))
        s.setValue("index", self._index)
        s.setValue("position", self._media.position())
        s.setValue("album", self._album_key)
