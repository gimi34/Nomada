import os
from dataclasses import dataclass, field

from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Property, Signal, Slot

from covers import CoverProvider
from playlist import PlaylistModel

_ROLES = ["key", "title", "artist", "year", "count", "duration", "cover"]


@dataclass
class Album:
    key: str
    title: str
    artist: str = ""
    year: str = ""
    duration: int = 0
    cover: str = ""
    indices: list[int] = field(default_factory=list)  # índices en la lista, en orden de pista

    @property
    def count(self):
        return len(self.indices)


class AlbumModel(QAbstractListModel):
    """Agrupa las canciones de la lista por álbum (o por carpeta si no tienen álbum)."""

    revisionChanged = Signal()

    def __init__(self, playlist: PlaylistModel, covers: CoverProvider, parent=None):
        super().__init__(parent)
        self._playlist = playlist
        self._covers = covers
        self._albums: list[Album] = []
        self._by_key: dict[str, Album] = {}
        self._revision = 0
        playlist.countChanged.connect(self.rebuild)

    # --- modelo ---
    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._albums)

    def roleNames(self):
        return {Qt.ItemDataRole.UserRole + i: name.encode() for i, name in enumerate(_ROLES)}

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid() or role < Qt.ItemDataRole.UserRole:
            return None
        return getattr(self._albums[index.row()], _ROLES[role - Qt.ItemDataRole.UserRole])

    def _get_revision(self):
        return self._revision

    revision = Property(int, _get_revision, notify=revisionChanged)

    # --- agrupación ---
    def rebuild(self):
        groups: dict[str, Album] = {}
        tracks = [self._playlist.at(i) for i in range(len(self._playlist))]
        for i, t in enumerate(tracks):
            folder = os.path.dirname(t.path)
            if t.album:
                key = f"{t.album.casefold()}|{(t.album_artist or folder).casefold()}"
                title = t.album
            else:
                key = f"dir|{folder.casefold()}"
                title = os.path.basename(folder) or "Sin álbum"
            album = groups.setdefault(key, Album(key=key, title=title))
            album.indices.append(i)

        for album in groups.values():
            album.indices.sort(key=lambda i: (tracks[i].disc_no, tracks[i].track_no or 9999,
                                              tracks[i].title.casefold()))
            members = [tracks[i] for i in album.indices]
            artists = {t.album_artist or t.artist for t in members}
            album.artist = artists.pop() if len(artists) == 1 else "Varios artistas"
            album.year = next((t.year for t in members if t.year), "")
            album.duration = sum(t.duration for t in members)
            album.cover = next((self._covers.url_for(t) for t in members if t.has_cover), "")

        self.beginResetModel()
        self._albums = sorted(groups.values(), key=lambda a: (a.artist.casefold(), a.year, a.title.casefold()))
        self._by_key = groups
        self.endResetModel()
        self._revision += 1
        self.revisionChanged.emit()

    # --- consultas ---
    def indices(self, key: str) -> list[int]:
        album = self._by_key.get(key)
        return list(album.indices) if album else []

    @Slot(str, result="QVariantMap")
    def info(self, key):
        album = self._by_key.get(key)
        if album is None:
            return {}
        return {name: getattr(album, name) for name in _ROLES}

    @Slot(str, result="QVariantList")
    def tracks(self, key):
        album = self._by_key.get(key)
        if album is None:
            return []
        result = []
        for i in album.indices:
            t = self._playlist.at(i)
            result.append({"index": i, "title": t.title, "artist": t.artist,
                           "duration": t.duration, "trackNo": t.track_no})
        return result
