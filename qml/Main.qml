import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "util.js" as Util

ApplicationWindow {
    id: win
    width: 1180
    height: 720
    minimumWidth: 860
    minimumHeight: 600
    visible: true
    title: player.currentIndex >= 0 ? player.title + " — " + player.artist : "Nómada"

    // Vista actual: 0 = Canciones, 1 = Álbumes, 2 = Letra
    property int view: 0
    property int previousView: 0
    readonly property var viewNames: ["Canciones", "Álbumes", "Letra"]
    onViewChanged: if (view !== 2) previousView = view

    // Al abrir: volver a donde se quedó la reproducción.
    // Si sonaba un álbum, se abre ese álbum; si no, la lista de canciones.
    Component.onCompleted: {
        if (player.albumKey !== "") {
            view = 1
            albumsView.openKey = player.albumKey
        }
    }

    readonly property bool searchVisible: view === 0 || (view === 1 && albumsView.openKey === "")

    // Alterna entre la letra y la vista anterior
    function toggleLyrics() {
        view = view === 2 ? previousView : 2
    }

    // Colores compartidos (los demás archivos los leen vía ApplicationWindow.window)
    readonly property bool orangeTheme: appSettings.theme === "orange"
    readonly property color accent: palette.accent
    readonly property color hoverColor: Qt.rgba(palette.windowText.r, palette.windowText.g, palette.windowText.b, 0.06)

    // ----------------------------------------------------- tema naranja y negro
    // Con `when` en falso, cada Binding devuelve el color original del sistema.
    Binding { target: win.palette; property: "accent";          value: "#ff7a1a"; when: win.orangeTheme }
    Binding { target: win.palette; property: "highlight";       value: "#ff7a1a"; when: win.orangeTheme }
    Binding { target: win.palette; property: "highlightedText"; value: "#111111"; when: win.orangeTheme }
    Binding { target: win.palette; property: "window";          value: "#0b0b0c"; when: win.orangeTheme }
    Binding { target: win.palette; property: "base";            value: "#121214"; when: win.orangeTheme }
    Binding { target: win.palette; property: "alternateBase";   value: "#18181b"; when: win.orangeTheme }
    Binding { target: win.palette; property: "button";          value: "#1e1e21"; when: win.orangeTheme }
    Binding { target: win.palette; property: "windowText";      value: "#f5f1ec"; when: win.orangeTheme }
    Binding { target: win.palette; property: "text";            value: "#f5f1ec"; when: win.orangeTheme }

    // ------------------------------------------------------------------ atajos
    Shortcut { sequence: "Space"; onActivated: player.togglePlay() }
    Shortcut { sequences: ["Media Play", "Media Pause", "Toggle Media Play/Pause"]; onActivated: player.togglePlay() }
    Shortcut { sequences: ["Ctrl+Right", "Media Next"]; onActivated: player.next() }
    Shortcut { sequences: ["Ctrl+Left", "Media Previous"]; onActivated: player.previous() }
    Shortcut { sequence: "Right"; onActivated: player.seek(player.position + 5000) }
    Shortcut { sequence: "Left"; onActivated: player.seek(Math.max(0, player.position - 5000)) }
    Shortcut { sequence: "Ctrl+Up"; onActivated: player.volume = Math.min(1, player.volume + 0.05) }
    Shortcut { sequence: "Ctrl+Down"; onActivated: player.volume = Math.max(0, player.volume - 0.05) }
    Shortcut { sequence: "M"; onActivated: player.muted = !player.muted }
    Shortcut { sequence: "Ctrl+1"; onActivated: win.view = 0 }
    Shortcut { sequence: "Ctrl+2"; onActivated: win.view = 1 }
    Shortcut { sequence: "Ctrl+3"; onActivated: win.toggleLyrics() }
    Shortcut { sequence: "Ctrl+I"; onActivated: if (player.currentIndex >= 0) infoDialog.open() }
    Shortcut { sequence: "Ctrl+,"; onActivated: settingsDialog.open() }
    Shortcut { sequences: [StandardKey.Open]; onActivated: fileDialog.open() }
    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: {
            if (!win.searchVisible) view = 0
            searchField.forceActiveFocus()
            searchField.selectAll()
        }
    }

    // ------------------------------------------------------- diálogos y menú
    FileDialog {
        id: fileDialog
        title: "Agregar canciones"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Audio (*.mp3 *.flac *.ogg *.oga *.opus *.m4a *.mp4 *.aac *.wav *.wma *.aiff *.aif)",
                      "Todos los archivos (*)"]
        onAccepted: player.addUrls(selectedFiles)
    }
    FolderDialog {
        id: folderDialog
        title: "Agregar carpeta"
        onAccepted: player.addUrls([selectedFolder])
    }
    InfoDialog { id: infoDialog }
    SettingsDialog { id: settingsDialog }

    SideMenu {
        id: sideMenu
        height: win.height
        currentView: win.view
        onViewSelected: (v) => win.view = v
        onAddFilesRequested: fileDialog.open()
        onAddFolderRequested: folderDialog.open()
        onSettingsRequested: settingsDialog.open()
    }

    // ------------------------------------------------------------------ layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        NowPlaying {
            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(320, win.width * 0.38)
            onInfoRequested: infoDialog.open()
            lyricsShown: win.view === 2
            onLyricsToggled: win.toggleLyrics()

            IconButton {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 10
                glyph: ""
                size: 18
                tip: "Menú"
                onClicked: sideMenu.open()
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: win.hoverColor
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            LyricsBackdrop {
                anchors.fill: parent
                opacity: win.view === 2 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28
                    Layout.rightMargin: 24
                    Layout.topMargin: 18
                    Layout.bottomMargin: 10

                    Label {
                        text: win.viewNames[win.view]
                        font.pixelSize: 24
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }

                    // Buscador: en Canciones y en la cuadrícula de Álbumes (no dentro de un álbum ni en Letra)
                    SearchField {
                        id: searchField
                        Layout.preferredWidth: 320
                        Layout.minimumWidth: 160
                        visible: win.searchVisible
                        placeholderText: win.view === 1 ? "Buscar álbumes, artistas o canciones"
                                                        : "Buscar canciones, artistas o álbumes"
                        onTextChanged: {
                            songSearch.filterText = text
                            albumSearch.filterText = text
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: win.view

                    SongsView { onAddFolderRequested: folderDialog.open() }
                    AlbumsView {
                        id: albumsView
                        onAddFolderRequested: folderDialog.open()
                    }
                    LyricsView {}
                }
            }
        }
    }

    // ---------------------------------------------------------- arrastrar/soltar
    DropArea {
        id: dropArea
        anchors.fill: parent
        onDropped: (event) => {
            if (event.hasUrls) {
                player.addUrls(event.urls)
                event.accept()
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: dropArea.containsDrag
        color: Qt.rgba(0, 0, 0, 0.6)
        border.width: 3
        border.color: win.accent
        Label {
            anchors.centerIn: parent
            text: "Suelta para agregar a la lista"
            font.pixelSize: 24
            color: "white"
        }
    }
}
