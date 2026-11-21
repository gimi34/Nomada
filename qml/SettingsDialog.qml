import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog
    title: "Configuración"
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(600, Overlay.overlay ? Overlay.overlay.width - 48 : 600)
    standardButtons: Dialog.Close

    readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "orange"
    readonly property color fg: ApplicationWindow.window ? ApplicationWindow.window.palette.windowText : "white"

    // Tarjeta de tema con muestra de colores
    component ThemeOption: Rectangle {
        id: option
        property string themeKey
        property string name
        property string description
        property var swatches: []
        readonly property bool selected: appSettings.theme === themeKey

        Layout.fillWidth: true
        Layout.preferredWidth: 1  // las dos tarjetas a partes iguales
        implicitHeight: optionContent.implicitHeight + 24
        radius: 8
        color: hover.hovered ? Qt.rgba(dialog.accent.r, dialog.accent.g, dialog.accent.b, 0.08) : "transparent"
        border.width: selected ? 2 : 1
        border.color: selected ? dialog.accent : Qt.rgba(dialog.fg.r, dialog.fg.g, dialog.fg.b, 0.15)

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: appSettings.theme = option.themeKey }

        ColumnLayout {
            id: optionContent
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Row {
                    spacing: -7
                    Repeater {
                        model: option.swatches
                        Rectangle {
                            required property var modelData
                            width: 24; height: 24; radius: 12
                            color: modelData
                            border.width: 2
                            border.color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                Label {
                    visible: option.selected
                    text: ""
                    font.family: iconFont
                    color: dialog.accent
                }
            }
            Label { text: option.name; font.bold: true }
            Label {
                Layout.fillWidth: true
                text: option.description
                opacity: 0.6
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }

    // Fila "Nombre  [opción][opción][opción]"
    component ChoiceRow: RowLayout {
        id: choice
        property string name
        property string settingKey
        property var options: []  // [{ value, text }]

        Layout.fillWidth: true
        spacing: 4
        Label {
            Layout.fillWidth: true
            text: choice.name
        }
        Repeater {
            model: choice.options
            Button {
                required property var modelData
                text: modelData.text
                highlighted: appSettings[choice.settingKey] === modelData.value
                focusPolicy: Qt.NoFocus
                onClicked: appSettings[choice.settingKey] = modelData.value
            }
        }
    }

    component Section: Label {
        Layout.topMargin: 6
        font.pixelSize: 15
        font.bold: true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ----------------------------------------------------------- apariencia
        Section { text: "Apariencia"; Layout.topMargin: 0 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ThemeOption {
                themeKey: "orange"
                name: "Naranja y negro"
                description: "Fondo negro con acentos naranjas."
                swatches: ["#0b0b0c", "#1e1e21", "#ff7a1a"]
            }
            ThemeOption {
                themeKey: "system"
                name: "Sistema"
                description: "Sigue el modo y el color de acento de Windows."
                swatches: ["#f3f3f3", "#202020", Qt.color(sysPalette.accent)]
            }
        }

        // --------------------------------------------------------------- letras
        Section { text: "Letras" }
        ChoiceRow {
            name: "Tamaño"
            settingKey: "lyricsSize"
            options: [{ value: "small", text: "Pequeño" }, { value: "medium", text: "Mediano" },
                      { value: "large", text: "Grande" }, { value: "xlarge", text: "Muy grande" }]
        }
        ChoiceRow {
            name: "Alineación"
            settingKey: "lyricsAlign"
            options: [{ value: "left", text: "Izquierda" }, { value: "center", text: "Centro" },
                      { value: "right", text: "Derecha" }]
        }
        ChoiceRow {
            name: "Línea que suena"
            settingKey: "lyricsAnchor"
            options: [{ value: "top", text: "Arriba" }, { value: "center", text: "Centro" },
                      { value: "bottom", text: "Abajo" }]
        }

        // Vista previa en miniatura (la letra real escala igual)
        Rectangle {
            id: preview
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 150
            radius: 8
            clip: true
            color: Qt.rgba(dialog.accent.r * 0.25, dialog.accent.g * 0.25, dialog.accent.b * 0.25, 1)
            border.width: 1
            border.color: Qt.rgba(dialog.fg.r, dialog.fg.g, dialog.fg.b, 0.12)

            readonly property real scaleFactor: 0.5
            readonly property int size: (({ small: 22, medium: 28, large: 36, xlarge: 46 })[appSettings.lyricsSize] ?? 36) * scaleFactor
            readonly property int align: ({ left: Text.AlignLeft, center: Text.AlignHCenter, right: Text.AlignRight })[appSettings.lyricsAlign] ?? Text.AlignHCenter
            readonly property real ratio: ({ top: 0.16, center: 0.38, bottom: 0.6 })[appSettings.lyricsAnchor] ?? 0.38
            readonly property int origin: align === Text.AlignLeft ? Item.Left
                                        : align === Text.AlignRight ? Item.Right : Item.Center

            Label {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                text: "Vista previa"
                font.pixelSize: 10
                opacity: 0.45
            }

            Column {
                id: sample
                x: 20
                width: parent.width - 40
                // La línea activa (segunda) queda a la altura elegida
                y: preview.height * preview.ratio - activeLine.y - activeLine.height / 2 + 10
                spacing: preview.size * 0.45
                Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                Label {
                    width: parent.width
                    text: "Una línea que ya pasó"
                    horizontalAlignment: preview.align
                    font.pixelSize: preview.size
                    font.bold: true
                    opacity: 0.35
                    scale: 0.88
                    transformOrigin: preview.origin
                }
                Label {
                    id: activeLine
                    width: parent.width
                    text: "La línea que está sonando"
                    horizontalAlignment: preview.align
                    font.pixelSize: preview.size
                    font.bold: true
                    color: dialog.accent
                }
                Label {
                    width: parent.width
                    text: "La siguiente línea"
                    horizontalAlignment: preview.align
                    font.pixelSize: preview.size
                    font.bold: true
                    opacity: 0.45
                    scale: 0.88
                    transformOrigin: preview.origin
                }
            }
        }
    }

    SystemPalette { id: sysPalette }
}
