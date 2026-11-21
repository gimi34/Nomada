import hashlib

from PySide6.QtCore import Qt
from PySide6.QtGui import QImage
from PySide6.QtQuick import QQuickImageProvider

from metadata import Track, read_cover


class CoverProvider(QQuickImageProvider):
    """Sirve carátulas embebidas a QML como image://cover/<clave>."""

    def __init__(self):
        super().__init__(QQuickImageProvider.ImageType.Image)
        self._paths: dict[str, str] = {}

    def url_for(self, track: Track | None) -> str:
        if track is None or not track.has_cover:
            return ""
        key = hashlib.sha1(track.path.encode("utf-8")).hexdigest()
        self._paths[key] = track.path
        return f"image://cover/{key}"

    def requestImage(self, id, size, requestedSize):
        image = QImage()
        path = self._paths.get(id)
        data = read_cover(path) if path else None
        if data:
            image.loadFromData(data)
        if not image.isNull() and requestedSize.width() > 0 and requestedSize.height() > 0:
            image = image.scaled(
                requestedSize,
                Qt.AspectRatioMode.KeepAspectRatioByExpanding,
                Qt.TransformationMode.SmoothTransformation,
            )
        return image
