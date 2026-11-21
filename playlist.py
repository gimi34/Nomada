from PySide6.QtCore import QAbstractListModel, QModelIndex, Qt, Property, Signal

from covers import CoverProvider
from metadata import Track

_ROLES = ["title", "artist", "album", "duration", "cover", "path"]


class PlaylistModel(QAbstractListModel):
    countChanged = Signal()

    def __init__(self, covers: CoverProvider, parent=None):
        super().__init__(parent)
        self._covers = covers
        self._tracks: list[Track] = []

    # --- API de modelo para QML ---
    def rowCount(self, parent=QModelIndex()):
        return 0 if parent.isValid() else len(self._tracks)

    def roleNames(self):
        return {Qt.ItemDataRole.UserRole + i: name.encode() for i, name in enumerate(_ROLES)}

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid():
            return None
        track = self._tracks[index.row()]
        name = _ROLES[role - Qt.ItemDataRole.UserRole] if role >= Qt.ItemDataRole.UserRole else None
        if name == "cover":
            return self._covers.url_for(track)
        if name:
            return getattr(track, name)
        return None

    def _count(self):
        return len(self._tracks)

    def _total(self):
        return sum(t.duration for t in self._tracks)

    count = Property(int, _count, notify=countChanged)
    totalDuration = Property(int, _total, notify=countChanged)

    # --- API para Python ---
    def __len__(self):
        return len(self._tracks)

    def at(self, i: int) -> Track | None:
        return self._tracks[i] if 0 <= i < len(self._tracks) else None

    def paths(self) -> list[str]:
        return [t.path for t in self._tracks]

    def append(self, tracks: list[Track]):
        if not tracks:
            return
        start = len(self._tracks)
        self.beginInsertRows(QModelIndex(), start, start + len(tracks) - 1)
        self._tracks.extend(tracks)
        self.endInsertRows()
        self.countChanged.emit()

    def remove(self, i: int):
        self.beginRemoveRows(QModelIndex(), i, i)
        del self._tracks[i]
        self.endRemoveRows()
        self.countChanged.emit()

    def clear(self):
        self.beginResetModel()
        self._tracks.clear()
        self.endResetModel()
        self.countChanged.emit()
