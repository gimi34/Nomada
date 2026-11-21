from PySide6.QtCore import QObject, QSettings, Qt, Property, Signal
from PySide6.QtGui import QGuiApplication

THEMES = ("orange", "system")


class AppSettings(QObject):
    """Preferencias de la aplicación expuestas a QML como `appSettings`."""

    themeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        theme = QSettings().value("theme", "orange", type=str)
        self._theme = theme if theme in THEMES else "orange"
        self._apply_theme()

    def _apply_theme(self):
        # El tema naranja siempre es oscuro; "system" sigue el modo de Windows.
        scheme = Qt.ColorScheme.Dark if self._theme == "orange" else Qt.ColorScheme.Unknown
        QGuiApplication.styleHints().setColorScheme(scheme)

    def _get_theme(self):
        return self._theme

    def _set_theme(self, theme):
        if theme in THEMES and theme != self._theme:
            self._theme = theme
            QSettings().setValue("theme", theme)
            self._apply_theme()
            self.themeChanged.emit()

    theme = Property(str, _get_theme, _set_theme, notify=themeChanged)
