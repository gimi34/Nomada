import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: empty
    property string glyph: ""
    property bool logo: false  // el símbolo de Nómada en lugar del glifo (biblioteca vacía)
    property string text
    property string detail
    property string actionText
    signal action()

    spacing: 8
    width: 380

    AppLogo {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 120
        Layout.preferredHeight: 120
        Layout.bottomMargin: 4
        visible: empty.logo
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        visible: !empty.logo
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
