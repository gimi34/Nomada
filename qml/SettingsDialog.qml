import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "themes.js" as Themes

Dialog {
    id: dialog
    title: "Configuración"
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(600, Overlay.overlay ? Overlay.overlay.width - 48 : 600)
    standardButtons: Dialog.Close
    height: Math.min(implicitHeight, Overlay.overlay ? Overlay.overlay.height - 32 : implicitHeight)

    readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "orange"
    readonly property color fg: ApplicationWindow.window ? ApplicationWindow.window.palette.windowText : "white"

    // Miniatura de tema: vista previa con fondo, superficie, acento y texto
    component ThemeTile: Item {
        id: tile
        property string themeKey
        property string name
        property color bg
        property color surface
        property color secondary
        property color accentColor
        property color textColor
        readonly property bool selected: appSettings.theme === themeKey

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: preview.height + nameLabel.implicitHeight + 8

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: appSettings.theme = tile.themeKey }

        Rectangle {
            id: preview
            width: parent.width
            height: 54
            radius: 8
            color: tile.bg
            border.width: tile.selected ? 2 : 1
            border.color: tile.selected ? dialog.accent
                        : hover.hovered ? Qt.rgba(dialog.fg.r, dialog.fg.g, dialog.fg.b, 0.45)
                        : Qt.rgba(dialog.fg.r, dialog.fg.g, dialog.fg.b, 0.15)
            clip: true

            // "tarjeta" de superficie con dos líneas de texto y un botón de acento
            Rectangle {
                x: 8; y: 8
                width: parent.width - 16
                height: parent.height - 16
                radius: 5
                color: tile.surface
                Column {
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Rectangle { width: 34; height: 5; radius: 2.5; color: tile.textColor }
                    Rectangle { width: 22; height: 4; radius: 2; color: tile.secondary }
                }
                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: tile.accentColor
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
        Row {
            anchors.top: preview.bottom
            anchors.topMargin: 6
            spacing: 4
            Label {
                id: nameLabel
                text: tile.name
                font.pixelSize: 12
                font.bold: tile.selected
            }
            Label {
                visible: tile.selected
                text: ""
                font.family: iconFont
                font.pixelSize: 11
                color: dialog.accent
                anchors.verticalCenter: nameLabel.verticalCenter
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

    ScrollView {
        id: scroller
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: scroller.availableWidth
            spacing: 10

            // ----------------------------------------------------------- apariencia
            Section { text: "Apariencia"; Layout.topMargin: 0 }
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: Themes.list
                    ThemeTile {
                        required property var modelData
                        themeKey: modelData.key
                        name: modelData.name
                        bg: modelData.window
                        surface: modelData.surface
                        secondary: modelData.secondary
                        accentColor: modelData.accent
                        textColor: modelData.text
                    }
                }
                ThemeTile {
                    themeKey: "system"
                    name: "Sistema"
                    bg: "#202020"
                    surface: "#2b2b2b"
                    secondary: "#3a3a3a"
                    accentColor: sysPalette.accent
                    textColor: "#f3f3f3"
                }
            }
            Label {
                Layout.fillWidth: true
                text: "«Sistema» sigue el modo claro u oscuro y el color de acento de Windows."
                opacity: 0.5
                font.pixelSize: 11
                wrapMode: Text.WordWrap
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
                implicitHeight: 118
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

    }

    SystemPalette { id: sysPalette }
}
