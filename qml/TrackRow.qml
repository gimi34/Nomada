import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "util.js" as Util

// Fila de canción reutilizada en la lista completa y en el detalle de álbum.
Item {
    id: row
    property int number
    property string title
    property string artist
    property int duration
    property string cover
    property bool showCover: true
    property bool current: false
    property bool removable: false
    signal activated()
    signal removeRequested()

    readonly property var win: ApplicationWindow.window
    readonly property color accent: win ? win.accent : "gray"

    height: 60

    HoverHandler { id: hover }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        radius: 6
        color: row.current ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.16)
             : hover.hovered && row.win ? row.win.hoverColor : "transparent"
    }

    MouseArea {
        anchors.fill: parent
        onDoubleClicked: row.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        spacing: 12

        Item {
            Layout.preferredWidth: 26
            Layout.fillHeight: true
            Label {
                anchors.centerIn: parent
                visible: !row.current
                text: row.number
                opacity: 0.5
                font.pixelSize: 12
            }
            Label {
                anchors.centerIn: parent
                visible: row.current
                text: player.playing ? "" : ""
                font.family: iconFont
                color: row.accent
            }
        }

        CoverArt {
            visible: row.showCover
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            source: row.cover
            radius: 4
            glyphSize: 16
            decodeSize: 84
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label {
                Layout.fillWidth: true
                text: row.title
                elide: Text.ElideRight
                font.bold: row.current
            }
            Label {
                Layout.fillWidth: true
                text: row.artist
                elide: Text.ElideRight
                opacity: 0.6
                font.pixelSize: 12
            }
        }

        Label {
            text: Util.fmt(row.duration)
            opacity: 0.6
            font.pixelSize: 12
        }

        IconButton {
            visible: row.removable
            glyph: ""
            size: 11
            tip: "Quitar"
            opacity: hover.hovered ? 1 : 0
            enabled: hover.hovered
            onClicked: row.removeRequested()
        }
    }
}
