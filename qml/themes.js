.pragma library

// Temas oscuros de la aplicación. "system" (seguir a Windows) no está aquí:
// usa los colores del sistema tal cual.
//   window    = fondo
//   surface   = superficies (listas, campos, diálogos)
//   secondary = elementos secundarios (botones, bordes)
//   accent    = acento
//   text      = texto
var list = [
    { key: "orange",     name: "Naranja y negro", window: "#0b0b0c", surface: "#18181b", secondary: "#2a2a2e", accent: "#ff7a1a", text: "#f5f1ec" },
    { key: "midnight",   name: "Midnight",        window: "#101418", surface: "#1c252b", secondary: "#34434a", accent: "#a5b5b2", text: "#e7e9e4" },
    { key: "forest",     name: "Forest",          window: "#101c18", surface: "#1b3028", secondary: "#29483a", accent: "#8baf91", text: "#e4ebdd" },
    { key: "sunset",     name: "Sunset",          window: "#211b1a", surface: "#352724", secondary: "#674337", accent: "#d58b61", text: "#f2dcc3" },
    { key: "arctic",     name: "Arctic",          window: "#101820", surface: "#1d2a35", secondary: "#304656", accent: "#70c5d6", text: "#e5f1f5" },
    { key: "burgundy",   name: "Burgundy",        window: "#191315", surface: "#302126", secondary: "#59323d", accent: "#c17a83", text: "#f0e4e3" },
    { key: "monochrome", name: "Monochrome",      window: "#090909", surface: "#191919", secondary: "#303030", accent: "#a0a0a0", text: "#f5f5f5" }
]

function byKey(key) {
    for (var i = 0; i < list.length; ++i)
        if (list[i].key === key)
            return list[i]
    return null
}
