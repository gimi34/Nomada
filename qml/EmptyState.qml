import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: empty
    property string glyph: ""
    property string text
    property string detail
    property string actionText
    signal action()

    spacing: 8
    width: 380

    Label {
        Layout.alignment: Qt.AlignHCenter
        text: empty.glyph
        font.family: iconFont
        font.pixelSize: 48
        opacity: 0.3
    }
    Label {
        Layout.fillWidth: true
        text: empty.text
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        opacity: 0.75
    }
    Label {
        Layout.fillWidth: true
        visible: empty.detail.length > 0
        text: empty.detail
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        opacity: 0.5
        font.pixelSize: 12
    }
    Button {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 6
        visible: empty.actionText.length > 0
        text: empty.actionText
        highlighted: true
        onClicked: empty.action()
    }
}
