import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Fondo de la vista Letra: la carátula muy difuminada con un velo encima.
Item {
    id: backdrop
    clip: true

    readonly property var win: ApplicationWindow.window
    readonly property color bgColor: win ? win.palette.window : "black"

    // Imagen centrada y algo más grande que el panel, para que el desenfoque
    // no deje bordes transparentes y el centro de la carátula quede en el centro.
    Image {
        id: bg
        anchors.centerIn: parent
        width: parent.width + 160
        height: parent.height + 160
        source: player.coverSource
        sourceSize: Qt.size(64, 64)
        fillMode: Image.PreserveAspectCrop
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: bg
        autoPaddingEnabled: false
        source: bg
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        blurMultiplier: 1.0
        saturation: 0.25
        opacity: bg.status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }
    // Velo para que el texto se lea bien, más oscuro arriba y abajo
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: Qt.rgba(backdrop.bgColor.r, backdrop.bgColor.g, backdrop.bgColor.b, 0.9) }
            GradientStop { position: 0.25; color: Qt.rgba(backdrop.bgColor.r, backdrop.bgColor.g, backdrop.bgColor.b, 0.6) }
            GradientStop { position: 0.75; color: Qt.rgba(backdrop.bgColor.r, backdrop.bgColor.g, backdrop.bgColor.b, 0.6) }
            GradientStop { position: 1.0;  color: Qt.rgba(backdrop.bgColor.r, backdrop.bgColor.g, backdrop.bgColor.b, 0.9) }
        }
    }
}
