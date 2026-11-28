"""Integración con los controles multimedia de Windows (SMTC).

Hace que Windows trate a Nómada como reproductor: las teclas multimedia
(reproducir/pausa, siguiente, anterior) lo controlan, y la canción actual
aparece en el panel de medios del sistema con título, artista y carátula.
"""
import sys
import time
from datetime import timedelta

from PySide6.QtCore import QObject, Qt, QThreadPool, QTimer, Signal

from metadata import read_cover

try:
    from winrt.windows.media import (
        MediaPlaybackStatus,
        MediaPlaybackType,
        SystemMediaTransportControlsButton as Button,
        SystemMediaTransportControlsTimelineProperties,
    )
    from winrt.windows.media.playback import MediaPlayer
    from winrt.windows.storage.streams import (
        DataWriter,
        InMemoryRandomAccessStream,
        RandomAccessStreamReference,
    )
except ImportError:  # otro sistema, o falta el paquete winrt
    MediaPlayer = None

TIMELINE_SYNC_MS = 5000  # cada cuánto se corrige la posición mientras suena
JUMP_MS = 1500            # salto de posición que se avisa al momento (búsqueda)


class MediaControls(QObject):
    """Conecta un `Player` con los controles multimedia del sistema."""

    # Windows llama a los manejadores desde sus propios hilos: se pasa al hilo
    # de la interfaz con estas señales (conexión en cola).
    _button = Signal(int)
    _seek = Signal(int)
    _cover_ready = Signal(int, object)  # (número de canción, carátula para Windows)

    def __init__(self, player, parent=None):
        super().__init__(parent)
        self._player = player
        self._smtc = None
        if MediaPlayer is None or sys.platform != "win32":
            return
        try:
            # Un MediaPlayer de WinRT da acceso a los SMTC sin ventana propia;
            # se desactiva su gestor para que no reaccione él a los botones.
            self._winrt_player = MediaPlayer()
            self._winrt_player.command_manager.is_enabled = False
            smtc = self._winrt_player.system_media_transport_controls
        except Exception as e:
            print(f"[controles multimedia] No disponibles: {e}")
            return
        self._smtc = smtc
        smtc.is_enabled = True
        smtc.is_play_enabled = smtc.is_pause_enabled = True
        smtc.is_next_enabled = smtc.is_previous_enabled = True
        smtc.is_stop_enabled = True

        self._button.connect(self._on_button, Qt.ConnectionType.QueuedConnection)
        self._seek.connect(player.seek, Qt.ConnectionType.QueuedConnection)
        self._tokens = (
            smtc.add_button_pressed(lambda _s, args: self._button.emit(int(args.button))),
            smtc.add_playback_position_change_requested(
                lambda _s, args: self._seek.emit(
                    int(args.requested_playback_position.total_seconds() * 1000))),
        )

        self._generation = 0  # descarta carátulas de canciones que ya no suenan
        self._cover_ready.connect(self._set_cover, Qt.ConnectionType.QueuedConnection)
        self._sent = (0, time.monotonic())  # última posición enviada y cuándo
        self._timeline_timer = QTimer(self, interval=TIMELINE_SYNC_MS)
        self._timeline_timer.timeout.connect(self._update_timeline)
        player.trackChanged.connect(self._update_track)
        player.playingChanged.connect(self._update_status)
        player.durationChanged.connect(self._update_timeline)
        player.positionChanged.connect(self._check_jump)
        self._update_track()
        self._update_status()

    # ------------------------------------------------------------- de Windows
    def _on_button(self, button: int):
        p = self._player
        if button == Button.PLAY:
            if not p.playing:
                p.togglePlay()
        elif button == Button.PAUSE or button == Button.STOP:
            if p.playing:
                p.togglePlay()
        elif button == Button.NEXT:
            p.next()
        elif button == Button.PREVIOUS:
            p.previous()

    # --------------------------------------------------------------- a Windows
    def _update_status(self):
        p = self._player
        if p.currentIndex < 0:
            status = MediaPlaybackStatus.CLOSED
        elif p.playing:
            status = MediaPlaybackStatus.PLAYING
        else:
            status = MediaPlaybackStatus.PAUSED
        self._smtc.playback_status = status
        if p.playing:
            self._timeline_timer.start()
        else:
            self._timeline_timer.stop()
        self._update_timeline()

    def _update_track(self):
        p = self._player
        updater = self._smtc.display_updater
        track = p.playlist.at(p.currentIndex) if p.currentIndex >= 0 else None
        if track is None:
            updater.clear_all()
            updater.update()
            self._update_status()
            return
        updater.type = MediaPlaybackType.MUSIC
        music = updater.music_properties
        music.title = p.title
        music.artist = p.artist
        music.album_title = p.album
        updater.thumbnail = None
        updater.update()
        self._update_status()
        self._generation += 1
        if track.has_cover:
            # Leer el archivo y esperar a WinRT no puede hacerse en el hilo de la
            # interfaz (es STA: WinRT no deja bloquearlo), así que va a otro hilo.
            generation, path = self._generation, track.path
            QThreadPool.globalInstance().start(
                lambda: self._cover_ready.emit(generation, self._thumbnail(path)))

    def _set_cover(self, generation: int, thumbnail):
        if generation == self._generation and thumbnail is not None:
            updater = self._smtc.display_updater
            updater.thumbnail = thumbnail
            updater.update()

    def _check_jump(self):
        sent_pos, sent_at = self._sent
        expected = sent_pos + ((time.monotonic() - sent_at) * 1000 if self._player.playing else 0)
        if abs(self._player.position - expected) > JUMP_MS:
            self._update_timeline()

    def _update_timeline(self):
        p = self._player
        duration = max(0, p.duration)
        position = min(max(0, p.position), duration)
        timeline = SystemMediaTransportControlsTimelineProperties()
        timeline.start_time = timeline.min_seek_time = timedelta(0)
        timeline.end_time = timeline.max_seek_time = timedelta(milliseconds=duration)
        timeline.position = timedelta(milliseconds=position)
        self._smtc.update_timeline_properties(timeline)
        self._sent = (position, time.monotonic())

    @staticmethod
    def _thumbnail(path: str):
        data = read_cover(path)
        if not data:
            return None
        try:
            stream = InMemoryRandomAccessStream()
            writer = DataWriter(stream)
            writer.write_bytes(data)
            writer.store_async().get()
            writer.detach_stream()
            stream.seek(0)
            return RandomAccessStreamReference.create_from_stream(stream)
        except Exception as e:
            print(f"[controles multimedia] Carátula no disponible: {e}")
            return None
