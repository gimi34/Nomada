import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Letra de la canción actual sobre la carátula difuminada.
// Si está sincronizada (LRC), resalta, agranda y sigue la línea que suena.
Item {
    id: view
    clip: true

    readonly property var win: ApplicationWindow.window
    readonly property color accent: win ? win.accent : "#ff7a1a"
    readonly property color fg: win ? win.palette.windowText : "white"
    readonly property bool synced: player.lyricsSynced
    // Compacta: dentro del panel de la portada (letra más pequeña y sin márgenes laterales)
    property bool compact: false

    // Preferencias (Configuración → Letras)
    readonly property int baseFontSize: ({ small: 22, medium: 28, large: 36, xlarge: 46 })[appSettings.lyricsSize] ?? 36
    readonly property int fontSize: compact ? Math.round(baseFontSize * 0.6) : baseFontSize
    readonly property int hAlign: ({ left: Text.AlignLeft, center: Text.AlignHCenter, right: Text.AlignRight })[appSettings.lyricsAlign] ?? Text.AlignHCenter
    readonly property real anchorRatio: ({ top: 0.16, center: 0.38, bottom: 0.6 })[appSettings.lyricsAnchor] ?? 0.38

    // ------------------------------------------------------------------ letra
    ListView {
        id: lyrics
        anchors.fill: parent
        anchors.leftMargin: view.compact ? 0 : 48
        anchors.rightMargin: view.compact ? 0 : 48
        visible: count > 0
        clip: true
        model: player.lyrics
        spacing: Math.round(view.fontSize * (view.synced ? 0.5 : 0.2))
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        currentIndex: view.synced ? player.lyricIndex : -1
        highlight: Item {}
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 450
        highlightMoveVelocity: -1
        highlightRangeMode: view.synced ? ListView.ApplyRange : ListView.NoHighlightRange
        preferredHighlightBegin: height * view.anchorRatio
        preferredHighlightEnd: height * view.anchorRatio + (currentItem ? currentItem.height : 0)

        // Al cambiar tamaño, posición o alto de la ventana, recolocar la línea actual
        // sin esperar a la siguiente línea.
        function recenter() {
            if (view.synced && currentItem)
                contentY = currentItem.y - preferredHighlightBegin
        }
        onHeightChanged: Qt.callLater(recenter)
        Connections {
            target: view
            function onAnchorRatioChanged() { Qt.callLater(lyrics.recenter) }
            function onFontSizeChanged() { Qt.callLater(lyrics.recenter) }
        }

        // Márgenes para que la primera y la última línea puedan llegar a la posición elegida
        header: Item { width: 1; height: view.synced ? lyrics.height * view.anchorRatio : 40 }
        footer: Item { width: 1; height: view.synced ? lyrics.height * (1 - view.anchorRatio) : 40 }

        delegate: Item {
            id: line
            required property int index
            required property var modelData

            readonly property bool active: view.synced && index === player.lyricIndex
            readonly property int distance: !view.synced ? 0
                                          : player.lyricIndex < 0 ? index + 1
                                          : Math.abs(index - player.lyricIndex)
            width: lyrics.width
            height: label.implicitHeight

            Label {
                id: label
                width: parent.width
                topPadding: 4
                bottomPadding: 4
                text: line.modelData.text.length > 0 ? line.modelData.text : (view.synced ? "♪" : " ")
                wrapMode: Text.WordWrap
                horizontalAlignment: view.hAlign
                font.pixelSize: view.synced ? view.fontSize : Math.round(view.fontSize * 0.68)
                font.bold: view.synced
                lineHeight: 1.08
                color: line.active ? view.accent : view.fg
                opacity: !view.synced ? 0.92 : line.active ? 1.0 : Math.max(0.28, 0.62 - line.distance * 0.08)
                scale: !view.synced || line.active ? 1.0 : 0.88
                transformOrigin: view.hAlign === Text.AlignLeft ? Item.Left
                               : view.hAlign === Text.AlignRight ? Item.Right : Item.Center

                Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 350 } }
                Behavior on color { ColorAnimation { duration: 350 } }

                // Desenfoque creciente en las líneas que no suenan
                layer.enabled: view.synced
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 20
                    blur: line.active ? 0 : Math.min(0.9, line.distance * 0.22)
                    Behavior on blur { NumberAnimation { duration: 350 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: view.synced && line.modelData.time >= 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: player.seek(line.modelData.time)
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        width: Math.min(380, view.width)
        visible: lyrics.count === 0
        glyph: ""
        text: player.currentIndex < 0 ? "Reproduce una canción para ver su letra"
                                      : "Esta canción no tiene letra"
        detail: player.currentIndex < 0 ? ""
              : "Incrusta la letra en las etiquetas del archivo, o pon un archivo .lrc "
                + "con el mismo nombre que la canción en la misma carpeta."
    }
}
