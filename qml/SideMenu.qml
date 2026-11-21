import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Menú de hamburguesa: navegación, acciones y configuración.
Drawer {
    id: menu
    property int currentView: 0
    signal viewSelected(int view)
    signal addFilesRequested()
    signal addFolderRequested()
    signal settingsRequested()

    width: 280
    edge: Qt.LeftEdge

    function pick(action) {
        close()
        action()
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        implicitHeight: 1
        color: ApplicationWindow.window ? ApplicationWindow.window.hoverColor : "gray"
    }

    component Section: Label {
        Layout.leftMargin: 24
        Layout.bottomMargin: 2
        opacity: 0.5
        font.pixelSize: 11
        font.bold: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 2

        RowLayout {
            Layout.leftMargin: 10
            Layout.bottomMargin: 10
            spacing: 6
            IconButton {
                glyph: ""
                tip: "Cerrar menú"
                onClicked: menu.close()
            }
            Label {
                text: "Nómada"
                font.pixelSize: 18
                font.bold: true
            }
        }

        Section { text: "BIBLIOTECA" }
        Repeater {
            model: [
                { glyph: "", text: "Canciones", key: "Ctrl+1" },
                { glyph: "", text: "Álbumes",   key: "Ctrl+2" },
                { glyph: "", text: "Letra",     key: "Ctrl+3" },
            ]
            MenuRow {
                required property int index
                required property var modelData
                Layout.fillWidth: true
                glyph: modelData.glyph
                text: modelData.text
                shortcut: modelData.key
                selected: menu.currentView === index
                onClicked: menu.pick(() => menu.viewSelected(index))
            }
        }

        Separator {}
        Section { text: "LISTA" }
        MenuRow {
            Layout.fillWidth: true
            glyph: ""
            text: "Agregar archivos…"
            shortcut: "Ctrl+O"
            onClicked: menu.pick(menu.addFilesRequested)
        }
        MenuRow {
            Layout.fillWidth: true
            glyph: ""
            text: "Agregar carpeta…"
            onClicked: menu.pick(menu.addFolderRequested)
        }
        MenuRow {
            Layout.fillWidth: true
            glyph: ""
            text: "Vaciar lista"
            enabled: player.playlist.count > 0
            onClicked: menu.pick(player.clear)
        }

        Item { Layout.fillHeight: true }

        Separator {}
        MenuRow {
            Layout.fillWidth: true
            Layout.bottomMargin: 12
            glyph: ""
            text: "Configuración"
            shortcut: "Ctrl+,"
            onClicked: menu.pick(menu.settingsRequested)
        }
    }
}
