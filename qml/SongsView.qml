import QtQuick
import QtQuick.Controls

// Todas las canciones de la lista (filtradas por el buscador).
Item {
    id: view
    signal addFolderRequested()

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        model: songSearch
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        delegate: TrackRow {
            required property var model
            // model.row = posición en la lista completa, aunque haya un filtro
            width: list.width
            number: model.row + 1
            title: model.title
            artist: model.artist
            duration: model.duration
            cover: model.cover
            current: model.row === player.currentIndex
            removable: true
            onActivated: player.playIndex(model.row)
            onRemoveRequested: player.removeAt(model.row)
        }
    }

    EmptyState {
        anchors.centerIn: parent
        visible: player.playlist.count === 0
        logo: true
        text: "Arrastra canciones o carpetas aquí"
        actionText: "Agregar carpeta…"
        onAction: view.addFolderRequested()
    }

    EmptyState {
        anchors.centerIn: parent
        visible: player.playlist.count > 0 && list.count === 0
        glyph: ""
        text: "No hay canciones que coincidan con «" + songSearch.filterText + "»"
        detail: "Prueba con otra palabra: se busca en el título, el artista y el álbum."
    }

    function showCurrent(mode) {
        const row = player.currentIndex >= 0 ? songSearch.proxyRow(player.currentIndex) : -1
        if (row >= 0)
            list.positionViewAtIndex(row, mode)
    }

    Connections {
        target: player
        function onTrackChanged() { view.showCurrent(ListView.Contain) }
    }

    // Al abrir la app, mostrar la canción que quedó seleccionada
    Component.onCompleted: Qt.callLater(() => view.showCurrent(ListView.Center))
}
