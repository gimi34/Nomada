import QtQuick
import QtQuick.Controls

// Todas las canciones de la lista.
Item {
    id: view
    signal addFolderRequested()

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        model: player.playlist
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        delegate: TrackRow {
            required property int index
            required property var model
            width: ListView.view.width
            number: index + 1
            title: model.title
            artist: model.artist
            duration: model.duration
            cover: model.cover
            current: index === player.currentIndex
            removable: true
            onActivated: player.playIndex(index)
            onRemoveRequested: player.removeAt(index)
        }
    }

    EmptyState {
        anchors.centerIn: parent
        visible: list.count === 0
        text: "Arrastra canciones o carpetas aquí"
        actionText: "Agregar carpeta…"
        onAction: view.addFolderRequested()
    }

    Connections {
        target: player
        function onTrackChanged() {
            if (player.currentIndex >= 0)
                list.positionViewAtIndex(player.currentIndex, ListView.Contain)
        }
    }
}
