import QtQuick
import QtQuick.Controls

// Campo de búsqueda al estilo de Windows 11: lupa a la derecha y ✕ para borrar.
// Esc también borra.
TextField {
    id: field
    leftPadding: 12
    rightPadding: clearButton.visible ? 66 : 38  // espacio para los iconos: el texto no los pisa
    selectByMouse: true

    Label {
        id: searchIcon
        x: field.width - width - 12
        anchors.verticalCenter: parent.verticalCenter
        text: ""
        font.family: iconFont
        opacity: 0.6
    }

    IconButton {
        id: clearButton
        x: searchIcon.x - width - 2
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 28
        implicitHeight: 28
        visible: field.text.length > 0
        glyph: ""
        size: 10
        tip: "Borrar búsqueda (Esc)"
        onClicked: {
            field.clear()
            field.forceActiveFocus()
        }
    }

    Keys.onEscapePressed: clear()
}
