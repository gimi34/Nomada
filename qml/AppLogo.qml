import QtQuick
import QtQuick.Controls

// Símbolo de Nómada. Sobre temas oscuros va sin fondo; sobre temas claros, con su cuadro
// oscuro, porque el símbolo está pensado para fondo oscuro y sobre claro se ve lavado.
Image {
    readonly property bool darkBackground: ApplicationWindow.window
        ? ApplicationWindow.window.palette.window.hslLightness < 0.5 : true

    source: darkBackground ? "images/logo.png" : "images/app-icon.png"
    fillMode: Image.PreserveAspectFit
    mipmap: true  // se muestra mucho más chico que el archivo: así no se ve dentado
}
