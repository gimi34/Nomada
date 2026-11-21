import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFontDatabase, QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from covers import CoverProvider
from player import Player
from search import SearchFilterModel
from settings import AppSettings


def main():
    QGuiApplication.setOrganizationName("Nomada")
    QGuiApplication.setApplicationName("Nomada")
    app = QGuiApplication(sys.argv)

    if sys.platform == "win32":
        QQuickStyle.setStyle("FluentWinUI3")  # aspecto nativo de Windows 11

    families = QFontDatabase.families()
    icon_font = "Segoe Fluent Icons" if "Segoe Fluent Icons" in families else "Segoe MDL2 Assets"

    settings = AppSettings()  # aplica el tema antes de crear la interfaz
    covers = CoverProvider()
    player = Player(covers)
    app.aboutToQuit.connect(player.save)

    # Archivos pasados por línea de comandos (p. ej. "Abrir con...")
    files = [os.path.abspath(a) for a in sys.argv[1:] if os.path.exists(a)]
    if files:
        player.addUrls([QUrl.fromLocalFile(f) for f in files])

    engine = QQmlApplicationEngine()
    engine.addImageProvider("cover", covers)
    engine.rootContext().setContextProperty("player", player)
    engine.rootContext().setContextProperty("appSettings", settings)
    song_search = SearchFilterModel(player.playlist)
    album_search = SearchFilterModel(player.albums)
    engine.rootContext().setContextProperty("songSearch", song_search)
    engine.rootContext().setContextProperty("albumSearch", album_search)
    engine.rootContext().setContextProperty("iconFont", icon_font)
    engine.load(QUrl.fromLocalFile(str(Path(__file__).parent / "qml" / "Main.qml")))
    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
