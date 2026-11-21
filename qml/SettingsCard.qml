import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Tarjeta que agrupa ajustes relacionados: título, subtítulo y contenido.
Rectangle {
    id: card
    property string title
    property string subtitle
    default property alias content: body.data

    readonly property var win: ApplicationWindow.window
    readonly property color fg: win ? win.palette.windowText : "white"

    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + 40
    radius: 10
    color: Qt.rgba(fg.r, fg.g, fg.b, 0.04)
    border.width: 1
    border.color: Qt.rgba(fg.r, fg.g, fg.b, 0.08)

    ColumnLayout {
        id: body
        x: 20
        y: 20
        width: card.width - 40
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 2
            spacing: 2
            Label {
                text: card.title
                font.pixelSize: 15
                font.bold: true
            }
            Label {
                Layout.fillWidth: true
                visible: card.subtitle !== ""
                text: card.subtitle
                opacity: 0.55
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
}
