import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "util.js" as Util

// Cuadrícula de álbumes y, al abrir uno, su lista de canciones.
Item {
    id: view
    signal addFolderRequested()

    property string openKey: ""
    readonly property var info: {
        player.albums.revision
        return openKey ? player.albums.info(openKey) : ({})
    }
    readonly property var win: ApplicationWindow.window

    // Si el álbum abierto desaparece (se quitaron sus canciones), volver a la cuadrícula
    onInfoChanged: if (openKey && info.key === undefined) openKey = ""

    // ------------------------------------------------------------ cuadrícula
    GridView {
        id: grid
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        visible: view.openKey === ""
        clip: true
        model: albumSearch  // filtrado por el buscador
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        readonly property int columns: Math.max(2, Math.floor(width / 190))
        cellWidth: Math.floor(width / columns)
        cellHeight: cellWidth + 50

        delegate: Item {
            id: card
            required property var model
            readonly property bool playingThis: player.albumKey === model.key
            width: grid.cellWidth
            height: grid.cellHeight

            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 8
                color: hover.hovered && view.win ? view.win.hoverColor : "transparent"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: view.openKey = card.model.key
                onDoubleClicked: player.playAlbum(card.model.key)
            }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                Item {
                    width: parent.width
                    height: width

                    CoverArt {
                        anchors.fill: parent
                        source: card.model.cover
                        radius: 6
                        glyphSize: width / 3
                        decodeSize: 320
                    }
                    RoundButton {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        implicitWidth: 44
                        implicitHeight: 44
                        visible: hover.hovered || card.playingThis
                        highlighted: true
                        focusPolicy: Qt.NoFocus
                        text: card.playingThis && player.playing ? "" : ""
                        font.family: iconFont
                        font.pixelSize: 16
                        onClicked: card.playingThis ? player.togglePlay() : player.playAlbum(card.model.key)
                    }
                }
                Label {
                    width: parent.width
                    topPadding: 4
                    text: card.model.title
                    font.bold: true
                    elide: Text.ElideRight
                }
                Label {
                    width: parent.width
                    text: card.model.artist + (card.model.year ? "  ·  " + card.model.year : "")
                    elide: Text.ElideRight
                    opacity: 0.6
                    font.pixelSize: 12
                }
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        visible: player.playlist.count === 0 && view.openKey === ""
        glyph: ""
        text: "Todavía no hay álbumes"
        detail: "Las canciones se agrupan por la etiqueta de álbum o, si no la tienen, por carpeta."
        actionText: "Agregar carpeta…"
        onAction: view.addFolderRequested()
    }

    EmptyState {
        anchors.centerIn: parent
        visible: player.playlist.count > 0 && grid.count === 0 && view.openKey === ""
        glyph: ""
        text: "No hay álbumes que coincidan con «" + albumSearch.filterText + "»"
        detail: "Se busca en el nombre del álbum, el artista y los títulos de sus canciones."
    }

    // --------------------------------------------------------------- detalle
    ColumnLayout {
        anchors.fill: parent
        visible: view.openKey !== ""
        spacing: 0

        IconButton {
            Layout.leftMargin: 14
            glyph: ""
            tip: "Volver a álbumes"
            onClicked: view.openKey = ""
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Layout.bottomMargin: 16
            spacing: 22

            CoverArt {
                Layout.preferredWidth: 160
                Layout.preferredHeight: 160
                source: view.info.cover ?? ""
                radius: 8
                glyphSize: 48
                decodeSize: 320
                // Carga directa: en modo asíncrono esta carátula a veces no llegaba a mostrarse
                asynchronous: false
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                Label { text: "ÁLBUM"; opacity: 0.5; font.pixelSize: 11; font.bold: true }
                Label {
                    Layout.fillWidth: true
                    text: view.info.title ?? ""
                    font.pixelSize: 26
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: [view.info.artist, view.info.year,
                           Util.songs(view.info.count ?? 0), Util.minutes(view.info.duration ?? 0)]
                          .filter(s => s).join("  ·  ")
                    opacity: 0.7
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.topMargin: 10
                    spacing: 8
                    Button {
                        text: "Reproducir"
                        highlighted: true
                        onClicked: player.playAlbum(view.openKey)
                    }
                    Button {
                        text: "Aleatorio"
                        onClicked: player.shuffleAlbum(view.openKey)
                    }
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            model: {
                player.albums.revision
                return view.openKey ? player.albums.tracks(view.openKey) : []
            }
            delegate: TrackRow {
                required property int index
                required property var modelData
                width: ListView.view.width
                number: modelData.trackNo > 0 ? modelData.trackNo : index + 1
                title: modelData.title
                artist: modelData.artist
                duration: modelData.duration
                showCover: false
                current: modelData.index === player.currentIndex
                onActivated: player.playAlbumFrom(view.openKey, modelData.index)
            }
        }
    }
}
