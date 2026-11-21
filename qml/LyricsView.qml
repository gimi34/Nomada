import QtQuick
import QtQuick.Controls

// Letra de la canción actual. Si está sincronizada (LRC), resalta la línea actual.
Item {
    id: view
    readonly property var win: ApplicationWindow.window

    ListView {
        id: lyrics
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        visible: count > 0
        clip: true
        spacing: player.lyricsSynced ? 14 : 4
        model: player.lyrics
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        currentIndex: player.lyricsSynced ? player.lyricIndex : -1
        highlight: Item {}
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 350
        highlightRangeMode: player.lyricsSynced ? ListView.ApplyRange : ListView.NoHighlightRange
        preferredHighlightBegin: height * 0.35
        preferredHighlightEnd: height * 0.45

        header: Item { height: 24 }
        footer: Item { height: player.lyricsSynced ? lyrics.height * 0.5 : 24 }

        delegate: Label {
            id: line
            required property int index
            required property var modelData
            readonly property bool active: player.lyricsSynced && index === player.lyricIndex

            width: ListView.view.width
            text: modelData.text.length > 0 ? modelData.text : (player.lyricsSynced ? "♪" : " ")
            wrapMode: Text.WordWrap
            font.pixelSize: player.lyricsSynced ? 22 : 16
            font.bold: player.lyricsSynced
            lineHeight: 1.15
            color: active && view.win ? view.win.accent : (view.win ? view.win.palette.windowText : "white")
            Behavior on color { ColorAnimation { duration: 250 } }
            opacity: !player.lyricsSynced ? 0.9
                   : active ? 1.0
                   : index < player.lyricIndex ? 0.3 : 0.45
            Behavior on opacity { NumberAnimation { duration: 250 } }

            MouseArea {
                anchors.fill: parent
                enabled: player.lyricsSynced && line.modelData.time >= 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: player.seek(line.modelData.time)
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        visible: lyrics.count === 0
        glyph: ""
        text: player.currentIndex < 0 ? "Reproduce una canción para ver su letra"
                                      : "Esta canción no tiene letra"
        detail: player.currentIndex < 0 ? ""
              : "Incrusta la letra en las etiquetas del archivo, o pon un archivo .lrc "
                + "con el mismo nombre que la canción en la misma carpeta."
    }
}
