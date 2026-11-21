import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "util.js" as Util

// Panel izquierdo: carátula, información y controles.
Item {
    id: nowPlaying
    clip: true
    signal infoRequested()

    readonly property real coverSize: Math.max(140, Math.min(width - 80, height - 400))
    readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "#ff7a1a"

    // Resplandor del color de acento en la parte inferior
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(nowPlaying.accent.r, nowPlaying.accent.g, nowPlaying.accent.b, 0.14) }
        }
    }

    // Fondo difuminado con la carátula
    Image {
        id: bgCover
        anchors.fill: parent
        source: player.coverSource
        sourceSize: Qt.size(200, 200)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: bgCover
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        saturation: 0.3
        opacity: bgCover.status === Image.Ready ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 14

        Item { Layout.fillHeight: true }

        CoverArt {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: nowPlaying.coverSize
            Layout.preferredHeight: nowPlaying.coverSize
            Layout.bottomMargin: 10
            source: player.coverSource
            radius: 14
            glyphSize: nowPlaying.coverSize / 3
            decodeSize: 600
        }

        Label {
            Layout.fillWidth: true
            text: player.currentIndex >= 0 ? player.title : "Nada en reproducción"
            font.pixelSize: 22
            font.bold: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            Layout.fillWidth: true
            Layout.topMargin: -10
            text: player.currentIndex >= 0
                  ? player.artist + (player.album ? "  ·  " + player.album : "")
                  : "Agrega canciones para empezar"
            opacity: 0.7
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        QualityBadge {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2
            Layout.maximumWidth: nowPlaying.width - 80
            onClicked: nowPlaying.infoRequested()
        }

        // Barra de progreso
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 0

            Slider {
                id: seek
                Layout.fillWidth: true
                from: 0
                to: Math.max(1, player.duration)
                enabled: player.currentIndex >= 0
                focusPolicy: Qt.NoFocus
                Binding on value {
                    when: !seek.pressed
                    value: player.position
                    restoreMode: Binding.RestoreNone
                }
                onPressedChanged: if (!pressed) player.seek(value)
            }
            RowLayout {
                Layout.fillWidth: true
                Label { text: Util.fmt(seek.value); opacity: 0.6; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
                Label { text: Util.fmt(player.duration); opacity: 0.6; font.pixelSize: 12 }
            }
        }

        // Controles
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            IconButton {
                glyph: ""; tip: "Aleatorio"
                checked: player.shuffle
                onClicked: player.shuffle = !player.shuffle
            }
            IconButton {
                glyph: ""; size: 20; tip: "Anterior (Ctrl+←)"
                onClicked: player.previous()
            }
            RoundButton {
                implicitWidth: 64
                implicitHeight: 64
                highlighted: true
                focusPolicy: Qt.NoFocus
                text: player.playing ? "" : ""
                font.family: iconFont
                font.pixelSize: 24
                onClicked: player.togglePlay()
            }
            IconButton {
                glyph: ""; size: 20; tip: "Siguiente (Ctrl+→)"
                onClicked: player.next()
            }
            IconButton {
                glyph: player.repeatMode === 2 ? "" : ""
                tip: ["Repetir: desactivado", "Repetir: todo", "Repetir: una"][player.repeatMode]
                checked: player.repeatMode > 0
                onClicked: player.cycleRepeat()
            }
        }

        // Volumen
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 280
            IconButton {
                glyph: player.muted || player.volume === 0 ? ""
                     : player.volume < 0.34 ? ""
                     : player.volume < 0.67 ? "" : ""
                tip: player.muted ? "Activar sonido (M)" : "Silenciar (M)"
                onClicked: player.muted = !player.muted
            }
            Slider {
                Layout.fillWidth: true
                from: 0; to: 1
                value: player.volume
                focusPolicy: Qt.NoFocus
                onMoved: player.volume = value
            }
            Label {
                text: Math.round(player.volume * 100)
                opacity: 0.6
                font.pixelSize: 12
                Layout.preferredWidth: 26
            }
        }

        Item { Layout.fillHeight: true }
    }
}
