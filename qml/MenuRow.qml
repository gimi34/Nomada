import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Fila del menú lateral: icono + texto, con estado seleccionado.
Item {
    id: row
    property string glyph
    property string text
    property string shortcut
    property bool selected: false
    signal clicked()

    readonly property var win: ApplicationWindow.window
    readonly property color accent: win ? win.accent : "orange"

    implicitHeight: 42
    opacity: enabled ? 1 : 0.4

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: row.clicked() }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        radius: 6
        color: row.selected ? Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.16)
             : hover.hovered && row.win ? row.win.hoverColor : "transparent"

        Rectangle {
            visible: row.selected
            width: 3
            height: 16
            radius: 2
            color: row.accent
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 20
        spacing: 14

        Label {
            text: row.glyph
            font.family: iconFont
            font.pixelSize: 16
            color: row.selected ? row.accent : (row.win ? row.win.palette.windowText : "white")
        }
        Label {
            Layout.fillWidth: true
            text: row.text
            font.bold: row.selected
            elide: Text.ElideRight
        }
        Label {
            visible: row.shortcut.length > 0
            text: row.shortcut
            opacity: 0.45
            font.pixelSize: 11
        }
    }
}
