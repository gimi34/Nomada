import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// Carátula con esquinas redondeadas y un marcador de posición si no hay imagen.
Item {
    id: art
    property string source
    property real radius: 8
    property int glyphSize: 24
    property int decodeSize: 128

    readonly property color accent: ApplicationWindow.window ? ApplicationWindow.window.accent : "#ff7a1a"

    Rectangle {
        anchors.fill: parent
        radius: art.radius
        visible: img.status !== Image.Ready
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.lighter(art.accent, 1.15) }
            GradientStop { position: 1; color: Qt.darker(art.accent, 2.4) }
        }
        Text {
            anchors.centerIn: parent
            text: ""
            font.family: iconFont
            font.pixelSize: art.glyphSize
            color: "white"
            opacity: 0.85
        }
    }
    Image {
        id: img
        anchors.fill: parent
        source: art.source
        sourceSize: Qt.size(art.decodeSize, art.decodeSize)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: art.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: img
        visible: img.status === Image.Ready
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
