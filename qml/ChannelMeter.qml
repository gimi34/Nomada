import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Medidor de intensidad de los canales izquierdo y derecho (dBFS).
ColumnLayout {
    id: meter
    readonly property var m: player.meter
    readonly property var win: ApplicationWindow.window
    readonly property color accent: win ? win.accent : "orange"
    readonly property color fg: win ? win.palette.windowText : "white"
    readonly property real floorDb: m.floor
    readonly property var ticks: [-60, -40, -30, -20, -12, -6, -3, 0]

    // dB -> fracción del ancho (escala lineal en dB)
    function frac(db) { return Math.max(0, Math.min(1, (db - floorDb) / -floorDb)) }
    function dbText(db) { return db <= floorDb ? "−∞" : (db > -0.05 ? "0.0" : db.toFixed(1).replace("-", "−")) }

    spacing: 8

    component Bar: RowLayout {
        id: bar
        property string name
        property real level
        property real peak
        spacing: 10

        Label {
            Layout.preferredWidth: 14
            text: bar.name
            font.bold: true
            opacity: 0.7
        }
        Item {
            id: track
            Layout.fillWidth: true
            implicitHeight: 14

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: Qt.rgba(meter.fg.r, meter.fg.g, meter.fg.b, 0.08)
            }
            // Barra: acento hasta −6 dB, ámbar hasta −3 dB, rojo cerca del límite
            Item {
                width: track.width * meter.frac(bar.level)
                height: parent.height
                clip: true
                Rectangle {
                    width: track.width
                    height: parent.height
                    radius: 4
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.darker(meter.accent, 1.5) }
                        GradientStop { position: meter.frac(-6); color: meter.accent }
                        GradientStop { position: meter.frac(-4); color: "#f2c230" }
                        GradientStop { position: meter.frac(-1); color: "#e5483b" }
                    }
                }
            }
            // Marca de pico que se queda un momento
            Rectangle {
                visible: bar.peak > meter.floorDb
                x: Math.min(track.width - width, track.width * meter.frac(bar.peak))
                width: 2
                height: parent.height
                color: bar.peak > -1 ? "#e5483b" : meter.fg
                opacity: 0.85
            }
        }
        Label {
            Layout.preferredWidth: 58
            horizontalAlignment: Text.AlignRight
            text: meter.dbText(bar.peak) + " dB"
            font.pixelSize: 12
            font.features: { "tnum": 1 }
            opacity: 0.7
        }
    }

    Bar { Layout.fillWidth: true; name: "I"; level: meter.m.left; peak: meter.m.leftPeak }
    Bar { Layout.fillWidth: true; name: "D"; level: meter.m.right; peak: meter.m.rightPeak }

    // Escala en dB alineada con las barras
    Item {
        Layout.fillWidth: true
        Layout.leftMargin: 24
        Layout.rightMargin: 68
        implicitHeight: 14
        Repeater {
            model: meter.ticks
            Label {
                required property int modelData
                x: parent.width * meter.frac(modelData) - width / 2
                text: modelData === 0 ? "0" : String(modelData).replace("-", "−")
                font.pixelSize: 10
                opacity: 0.45
            }
        }
    }
}
