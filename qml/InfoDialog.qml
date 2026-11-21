import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

// Información detallada de la canción actual y su calidad de audio.
Dialog {
    id: dialog
    title: "Información de la canción"
    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(520, Overlay.overlay ? Overlay.overlay.width - 48 : 520)
    standardButtons: Dialog.Close

    // Fondo modal: el resto de la ventana desenfocado y oscurecido
    Overlay.modal: Item {
        ShaderEffectSource {
            id: snapshot
            anchors.fill: parent
            sourceItem: ApplicationWindow.window ? ApplicationWindow.window.contentItem : null
            visible: false
        }
        // El contenido no incluye el fondo de la ventana: sin esto se vería la versión nítida debajo
        Rectangle {
            anchors.fill: parent
            color: ApplicationWindow.window ? ApplicationWindow.window.palette.window : "black"
        }
        MultiEffect {
            anchors.fill: parent
            source: snapshot
            blurEnabled: true
            blur: 1.0
            blurMax: 48
        }
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
        }
    }

    readonly property var info: player.audioInfo
    readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "orange"

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            spacing: 14
            CoverArt {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                source: player.coverSource
                radius: 6
                glyphSize: 26
                decodeSize: 144
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: player.title
                    font.pixelSize: 17
                    font.bold: true
                    elide: Text.ElideRight
                }
                QualityBadge { interactive: false }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 18
            rowSpacing: 7

            Repeater {
                model: dialog.info.rows ?? []
                delegate: Label {
                    required property int index
                    required property var modelData
                    text: modelData.label
                    opacity: 0.6
                    Layout.alignment: Qt.AlignTop
                    Layout.row: index
                    Layout.column: 0
                }
            }
            Repeater {
                model: dialog.info.rows ?? []
                delegate: TextEdit {
                    required property int index
                    required property var modelData
                    text: modelData.value
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.WrapAnywhere
                    color: dialog.palette.windowText
                    selectionColor: dialog.accent
                    selectedTextColor: "#111111"
                    font: dialog.font
                    Layout.fillWidth: true
                    Layout.row: index
                    Layout.column: 1
                }
            }
        }

        Button {
            text: "Abrir carpeta"
            visible: (dialog.info.folder ?? "") !== ""
            onClicked: Qt.openUrlExternally("file:///" + dialog.info.folder.replace(/\\/g, "/"))
        }
    }
}
