import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Mini reproductor: ventana pequeña, sin marco y siempre encima. Se arrastra desde cualquier parte.
Window {
    id: mini
    required property var mainWindow  // la ventana grande, para heredar colores y volver a ella

    width: 380
    height: 104
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    title: "Nómada"
    color: mainWindow.palette.window
    palette: mainWindow.palette

    // Primera vez: esquina inferior derecha de la pantalla de la ventana grande (sobre la barra de tareas)
    Component.onCompleted: {
        const s = mainWindow.screen
        x = s.virtualX + s.width - width - 24
        y = s.virtualY + s.height - height - 72
    }

    DragHandler {
        target: null
        onActiveChanged: if (active) mini.startSystemMove()
    }

    // Tamaño explícito: en esta ventana sin marco el contentItem se queda en 0×0
    Item {
        width: mini.width
        height: mini.height

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(mini.palette.windowText.r, mini.palette.windowText.g, mini.palette.windowText.b, 0.12)
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            anchors.bottomMargin: 16
            spacing: 12

            CoverArt {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                source: player.coverSource
                radius: 6
                glyphSize: 26
                decodeSize: 144
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    text: player.currentIndex >= 0 ? player.title : "Nada en reproducción"
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: player.artist
                    opacity: 0.6
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                RowLayout {
                    spacing: 0
                    IconButton { glyph: ""; tip: "Anterior"; onClicked: player.previous() }
                    IconButton { glyph: player.playing ? "" : ""; size: 20; onClicked: player.togglePlay() }
                    IconButton { glyph: ""; tip: "Siguiente"; onClicked: player.next() }
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                glyph: ""
                tip: "Volver al reproductor completo (Ctrl+M)"
                onClicked: mini.mainWindow.exitMini()
            }
        }

        // Progreso de la canción
        Rectangle {
            anchors.bottom: parent.bottom
            height: 3
            width: player.duration > 0 ? parent.width * player.position / player.duration : 0
            color: mini.mainWindow.accent
        }
    }
}
