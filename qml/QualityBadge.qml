import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Insignia de calidad: "LOSSLESS  FLAC · 16 bit / 44.1 kHz". Clic = más información.
Rectangle {
    id: badge
    property bool interactive: true
    signal clicked()

    readonly property var info: player.audioInfo
    readonly property string tag: info.tag ?? ""
    readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "orange"

    visible: (info.badge ?? "") !== ""
    implicitWidth: content.implicitWidth + 20
    implicitHeight: 28
    radius: height / 2
    color: Qt.rgba(accent.r, accent.g, accent.b, hover.hovered && interactive ? 0.22 : 0.10)
    border.width: 1
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.45)

    HoverHandler {
        id: hover
        enabled: badge.interactive
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        enabled: badge.interactive
        onTapped: badge.clicked()
    }

    ToolTip.text: "Ver información de la canción"
    ToolTip.visible: hover.hovered && interactive
    ToolTip.delay: 600

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 7

        Rectangle {
            visible: badge.tag !== ""
            implicitWidth: tagLabel.implicitWidth + 10
            implicitHeight: 17
            radius: 4
            color: badge.accent
            Label {
                id: tagLabel
                anchors.centerIn: parent
                text: badge.tag
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 0.6
                color: "#111111"
            }
        }
        Label {
            text: badge.info.badge ?? ""
            font.pixelSize: 12
        }
        Label {
            visible: badge.interactive
            text: ""
            font.family: iconFont
            font.pixelSize: 11
            opacity: 0.6
        }
    }
}
