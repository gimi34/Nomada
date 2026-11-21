import QtQuick
import QtQuick.Controls

ToolButton {
    property string glyph
    property int size: 16
    property string tip

    text: glyph
    font.family: iconFont
    font.pixelSize: size
    focusPolicy: Qt.NoFocus
    ToolTip.text: tip
    ToolTip.visible: hovered && tip.length > 0
    ToolTip.delay: 600
}
