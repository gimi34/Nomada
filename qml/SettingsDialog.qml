import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog
    title: "Configuración"
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(480, Overlay.overlay ? Overlay.overlay.width - 48 : 480)
    standardButtons: Dialog.Close

    // Tarjeta de tema con muestra de colores
    component ThemeOption: Rectangle {
        id: option
        property string themeKey
        property string name
        property string description
        property var swatches: []
        readonly property bool selected: appSettings.theme === themeKey
        readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "orange"
        readonly property color fg: ApplicationWindow.window ? ApplicationWindow.window.palette.windowText : "white"

        Layout.fillWidth: true
        implicitHeight: 76
        radius: 8
        color: hover.hovered ? Qt.rgba(accent.r, accent.g, accent.b, 0.08) : "transparent"
        border.width: selected ? 2 : 1
        border.color: selected ? accent : Qt.rgba(fg.r, fg.g, fg.b, 0.15)

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: appSettings.theme = option.themeKey }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Row {
                spacing: -8
                Repeater {
                    model: option.swatches
                    Rectangle {
                        required property var modelData
                        width: 30; height: 30; radius: 15
                        color: modelData
                        border.width: 2
                        border.color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label { text: option.name; font.bold: true }
                Label {
                    Layout.fillWidth: true
                    text: option.description
                    opacity: 0.6
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
            Label {
                visible: option.selected
                text: ""
                font.family: iconFont
                font.pixelSize: 16
                color: option.accent
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Label { text: "Apariencia"; font.pixelSize: 15; font.bold: true }
        Label {
            Layout.fillWidth: true
            text: "Elige los colores de la aplicación. El cambio se aplica al instante y se recuerda."
            opacity: 0.6
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        ThemeOption {
            themeKey: "orange"
            name: "Naranja y negro"
            description: "Fondo negro con acentos naranjas."
            swatches: ["#0b0b0c", "#1e1e21", "#ff7a1a"]
        }
        ThemeOption {
            themeKey: "system"
            name: "Sistema"
            description: "Sigue el modo claro u oscuro y el color de acento de Windows."
            swatches: ["#f3f3f3", "#202020", Qt.color(sysPalette.accent)]
        }
    }

    SystemPalette { id: sysPalette }
}
