import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "themes.js" as Themes

// Página completa de configuración, dividida en pestañas.
Item {
    id: page

    readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "orange"
    readonly property color fg: ApplicationWindow.window ? ApplicationWindow.window.palette.windowText : "white"

    // El medidor de canales solo trabaja con la pestaña Sonido a la vista
    Binding {
        target: player.meter
        property: "active"
        value: page.visible && tabs.currentIndex === 1
    }

    // ------------------------------------------------------------ componentes
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
            height: 64
            radius: 8
            color: tile.bg
            border.width: tile.selected ? 2 : 1
            border.color: tile.selected ? page.accent
                        : hover.hovered ? Qt.rgba(page.fg.r, page.fg.g, page.fg.b, 0.45)
                        : Qt.rgba(page.fg.r, page.fg.g, page.fg.b, 0.15)
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
                text: ""  // marca de verificación
                font.family: iconFont
                font.pixelSize: 11
                color: page.accent
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

    // Pestaña con scroll y ancho de lectura limitado
    component SettingsPage: ScrollView {
        id: sp
        default property alias content: column.data
        contentWidth: availableWidth
        contentHeight: column.implicitHeight + 28  // margen inferior
        clip: true

        ColumnLayout {
            id: column
            x: 28
            width: Math.min(sp.availableWidth - 52, 760)
            spacing: 16
        }
    }

    // ------------------------------------------------------------------ layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: tabs
            objectName: "settingsTabs"
            Layout.leftMargin: 28
            Layout.bottomMargin: 16
            Repeater {
                model: [
                    { glyph: "", text: "Personalización" },
                    { glyph: "", text: "Sonido" },
                    { glyph: "", text: "Letras" },
                ]
                TabButton {
                    id: tabButton
                    required property var modelData
                    width: implicitWidth
                    focusPolicy: Qt.NoFocus
                    contentItem: Row {
                        spacing: 8
                        Label {
                            text: modelData.glyph
                            font.family: iconFont
                            font.pixelSize: 15
                            anchors.verticalCenter: parent.verticalCenter
                            color: tabButton.checked ? page.accent : page.fg
                        }
                        Label {
                            text: modelData.text
                            font.bold: tabButton.checked
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            // ----------------------------------------------------- personalización
            SettingsPage {
                SettingsCard {
                    title: "Tema"
                    subtitle: "Colores de toda la aplicación."

                    GridLayout {
                        id: themeGrid
                        Layout.fillWidth: true
                        columns: Math.max(2, Math.min(4, Math.floor(width / 140)))
                        columnSpacing: 12
                        rowSpacing: 12

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
                }
            }

            // ---------------------------------------------------------------- sonido
            SettingsPage {
                SoundSettings { Layout.fillWidth: true }
            }

            // ---------------------------------------------------------------- letras
            SettingsPage {
                SettingsCard {
                    title: "Texto"
                    subtitle: "Cómo se ve la letra en la vista Letra."

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
                }

                SettingsCard {
                    title: "Vista previa"

                    // Miniatura (la letra real escala igual)
                    Rectangle {
                        id: preview
                        Layout.fillWidth: true
                        implicitHeight: 150
                        radius: 8
                        clip: true
                        color: Qt.rgba(page.accent.r * 0.25, page.accent.g * 0.25, page.accent.b * 0.25, 1)

                        readonly property real scaleFactor: 0.55
                        readonly property int size: (({ small: 22, medium: 28, large: 36, xlarge: 46 })[appSettings.lyricsSize] ?? 36) * scaleFactor
                        readonly property int align: ({ left: Text.AlignLeft, center: Text.AlignHCenter, right: Text.AlignRight })[appSettings.lyricsAlign] ?? Text.AlignHCenter
                        readonly property real ratio: ({ top: 0.16, center: 0.38, bottom: 0.6 })[appSettings.lyricsAnchor] ?? 0.38
                        readonly property int origin: align === Text.AlignLeft ? Item.Left
                                                    : align === Text.AlignRight ? Item.Right : Item.Center

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
                                color: page.accent
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
        }
    }

    SystemPalette { id: sysPalette }
}
