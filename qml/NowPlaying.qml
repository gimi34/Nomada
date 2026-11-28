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
    signal lyricsToggled()
    property bool lyricsShown: false
    // Letra en lugar de la portada (clic en la portada); la lista de la derecha sigue a la vista
    property bool coverLyrics: false

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
        anchors.centerIn: parent
        width: parent.width + 160   // más grande que el panel: sin bordes transparentes
        height: parent.height + 160
        source: player.coverSource
        sourceSize: Qt.size(64, 64)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: bgCover
        autoPaddingEnabled: false
        source: bgCover
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 1.0
        saturation: 0.3
        opacity: bgCover.status === Image.Ready ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        anchors.topMargin: nowPlaying.coverLyrics ? 60 : 40  // deja libre el botón de menú
        spacing: 14

        Item { Layout.fillHeight: true; visible: !nowPlaying.coverLyrics }

        CoverArt {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: nowPlaying.coverSize
            Layout.preferredHeight: nowPlaying.coverSize
            Layout.bottomMargin: 10
            visible: !nowPlaying.coverLyrics
            source: player.coverSource
            radius: 14
            glyphSize: nowPlaying.coverSize / 3
            decodeSize: 600

            HoverHandler { id: coverHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: nowPlaying.coverLyrics = true }
            ToolTip.text: "Ver letra"
            ToolTip.visible: coverHover.hovered
            ToolTip.delay: 600
        }

        // Con la letra: portada en miniatura y título en una fila; clic en la miniatura para volver
        RowLayout {
            Layout.fillWidth: true
            visible: nowPlaying.coverLyrics
            spacing: 12

            CoverArt {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                source: player.coverSource
                radius: 6
                glyphSize: 20
                decodeSize: 600  // el mismo tamaño que la grande: reutiliza la imagen ya cargada

                HoverHandler { id: thumbHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: nowPlaying.coverLyrics = false }
                ToolTip.text: "Ver portada"
                ToolTip.visible: thumbHover.hovered
                ToolTip.delay: 600
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    text: player.currentIndex >= 0 ? player.title : "Nada en reproducción"
                    font.pixelSize: 17
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: player.artist + (player.album ? "  ·  " + player.album : "")
                    opacity: 0.7
                    elide: Text.ElideRight
                }
            }
        }

        // Se crea solo mientras se ve
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: nowPlaying.coverLyrics
            active: nowPlaying.coverLyrics
            sourceComponent: LyricsView { compact: true }
        }

        Label {
            Layout.fillWidth: true
            visible: !nowPlaying.coverLyrics
            text: player.currentIndex >= 0 ? player.title : "Nada en reproducción"
            font.pixelSize: 22
            font.bold: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            Layout.fillWidth: true
            Layout.topMargin: -10
            visible: !nowPlaying.coverLyrics
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
            Layout.preferredWidth: 320
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
            IconButton {
                id: lyricsButton
                Layout.leftMargin: 6
                glyph: ""
                tip: nowPlaying.lyricsShown ? "Volver (Ctrl+3)" : "Ver letra (Ctrl+3)"
                checked: nowPlaying.lyricsShown
                onClicked: nowPlaying.lyricsToggled()

                // Punto que indica que la canción tiene letra
                Rectangle {
                    visible: player.lyrics.length > 0 && !lyricsButton.checked
                    width: 7
                    height: 7
                    radius: 3.5
                    color: nowPlaying.accent
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                }
            }
        }

        Item { Layout.fillHeight: true; visible: !nowPlaying.coverLyrics }
    }
}
