import os
import sys
from pathlib import Path

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QFontDatabase, QIcon, QPixmap
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle
from PySide6.QtWidgets import QApplication, QSplashScreen

from covers import CoverProvider
from media_controls import MediaControls
from player import Player
from search import SearchFilterModel
from settings import AppSettings

QML_DIR = Path(__file__).parent / "qml"


def main():
    QApplication.setOrganizationName("Nomada")
    QApplication.setApplicationName("Nomada")
    # QApplication (no QGuiApplication) solo por QSplashScreen, que es de QtWidgets
    app = QApplication(sys.argv)
    app.setWindowIcon(QIcon(str(QML_DIR / "images" / "app-icon.png")))  # ventana y barra de tareas

    # Pantalla de carga: se pinta ya, antes de leer las etiquetas de toda la biblioteca
    splash_image = QPixmap(str(QML_DIR / "images" / "splash.png"))
    splash_image.setDevicePixelRatio(splash_image.width() / 520)  # 520 px lógicos, nítida con escalado
    splash = QSplashScreen(splash_image)
    splash.show()
    app.processEvents()

    if sys.platform == "win32":
        QQuickStyle.setStyle("FluentWinUI3")  # aspecto nativo de Windows 11

    families = QFontDatabase.families()
    icon_font = "Segoe Fluent Icons" if "Segoe Fluent Icons" in families else "Segoe MDL2 Assets"

    settings = AppSettings()  # aplica el tema antes de crear la interfaz
    covers = CoverProvider()
    player = Player(covers)
    app.aboutToQuit.connect(player.save)
    media_controls = MediaControls(player)  # teclas multimedia y panel de Windows

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
    engine.load(QUrl.fromLocalFile(str(QML_DIR / "Main.qml")))
    if not engine.rootObjects():
        sys.exit(-1)

    # Se cierra cuando la ventana ya dibujó su primer fotograma (sin hueco entre las dos).
    # frameSwapped llega desde el hilo de dibujo: en cola y una sola vez.
    once_queued = Qt.ConnectionType(Qt.ConnectionType.QueuedConnection.value
                                    | Qt.ConnectionType.SingleShotConnection.value)
    engine.rootObjects()[0].frameSwapped.connect(splash.close, once_queued)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
