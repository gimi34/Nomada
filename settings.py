from PySide6.QtCore import QObject, QSettings, Qt, Property, Signal
from PySide6.QtGui import QGuiApplication

# nombre -> (valor por defecto, valores permitidos)
OPTIONS = {
    "theme": ("orange", ("orange", "midnight", "forest", "sunset", "arctic", "burgundy", "monochrome", "system")),
    "lyricsSize": ("large", ("small", "medium", "large", "xlarge")),
    "lyricsAlign": ("center", ("left", "center", "right")),
    "lyricsAnchor": ("center", ("top", "center", "bottom")),
}


def _option(name: str, notify: Signal):
    def getter(self):
        return self._values[name]

    def setter(self, value):
        self._set(name, value)

    return Property(str, getter, setter, notify=notify)


class AppSettings(QObject):
    """Preferencias de la aplicación expuestas a QML como `appSettings`."""

    changed = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        s = QSettings()
        self._values = {}
        for name, (default, allowed) in OPTIONS.items():
            value = s.value(name, default, type=str)
            self._values[name] = value if value in allowed else default
        self._apply_theme()

    def _set(self, name: str, value: str):
        if value in OPTIONS[name][1] and value != self._values[name]:
            self._values[name] = value
            QSettings().setValue(name, value)
            if name == "theme":
                self._apply_theme()
            self.changed.emit()

    def _apply_theme(self):
        # Todos los temas propios son oscuros; "system" sigue el modo de Windows.
        dark = self._values["theme"] != "system"
        QGuiApplication.styleHints().setColorScheme(Qt.ColorScheme.Dark if dark else Qt.ColorScheme.Unknown)

    theme = _option("theme", changed)
    lyricsSize = _option("lyricsSize", changed)
    lyricsAlign = _option("lyricsAlign", changed)
    lyricsAnchor = _option("lyricsAnchor", changed)
