import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Pestaña Sonido: dispositivo de salida, intensidad de los canales y calidad.
ColumnLayout {
    id: sound
    spacing: 16

    readonly property var info: player.audioInfo
    readonly property bool hasTrack: player.currentIndex >= 0
    // Solo los datos de calidad (el resto ya está en «Información de la canción»)
    readonly property var qualityLabels: ["Formato", "Tipo", "Calidad", "Bitrate", "Canales"]
    readonly property var qualityRows: (info.rows ?? []).filter(r => qualityLabels.indexOf(r.label) >= 0)

    component InfoRow: RowLayout {
        property string label
        property string value
        Layout.fillWidth: true
        spacing: 12
        Label {
            Layout.preferredWidth: 150
            text: parent.label
            opacity: 0.6
        }
        Label {
            Layout.fillWidth: true
            text: parent.value
            wrapMode: Text.WrapAnywhere
        }
    }

    // ------------------------------------------------------------ dispositivo
    SettingsCard {
        title: "Salida de audio"
        subtitle: "Elige por qué dispositivo suena la música."

        ComboBox {
            id: outputBox
            Layout.fillWidth: true
            model: player.audioDevices
            textRole: "name"
            valueRole: "id"
            focusPolicy: Qt.NoFocus
            onActivated: player.audioDevice = currentValue

            // Recolocar la selección cuando cambia la lista o la preferencia
            function sync() {
                currentIndex = Math.max(0, player.audioDevices.findIndex(d => d.id === player.audioDevice))
            }
            Component.onCompleted: sync()
            Connections {
                target: player
                // callLater: esperar a que el ComboBox cargue el modelo nuevo
                function onAudioDevicesChanged() { Qt.callLater(outputBox.sync) }
                function onAudioDeviceChanged() { Qt.callLater(outputBox.sync) }
            }
        }
        InfoRow {
            label: "Sonando por"
            value: player.outputDeviceName + (player.outputFormat ? "  ·  " + player.outputFormat : "")
        }
        Label {
            Layout.fillWidth: true
            text: "Si el dispositivo elegido se desconecta, la música sigue por la salida predeterminada y vuelve a él cuando se reconecte."
            opacity: 0.5
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
    }

    // ------------------------------------------------------------- intensidad
    SettingsCard {
        title: "Intensidad de los canales"
        subtitle: "Nivel de pico de los canales izquierdo (I) y derecho (D) de lo que está sonando. "
                + "Si llega a 0 dB, el audio está al máximo y puede saturar."

        ChannelMeter {
            Layout.fillWidth: true
            opacity: player.playing ? 1 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        Label {
            visible: !player.playing
            text: sound.hasTrack ? "En pausa: reproduce la canción para ver los niveles." : "No hay ninguna canción cargada."
            opacity: 0.5
            font.pixelSize: 11
        }
    }

    // ---------------------------------------------------------------- calidad
    SettingsCard {
        title: "Calidad del audio"
        subtitle: sound.hasTrack ? player.title + (player.artist ? " — " + player.artist : "")
                                 : "No hay ninguna canción cargada."

        QualityBadge {
            visible: sound.hasTrack && (sound.info.badge ?? "") !== ""
            interactive: false
        }
        Repeater {
            model: sound.hasTrack ? sound.qualityRows : []
            InfoRow {
                required property var modelData
                label: modelData.label
                value: modelData.value
            }
        }
        InfoRow {
            visible: sound.hasTrack
            label: "Salida"
            value: player.outputFormat || "—"
        }
    }
}
