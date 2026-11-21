.pragma library

function fmt(ms) {
    if (!ms || ms < 0) return "0:00"
    const s = Math.floor(ms / 1000)
    const m = Math.floor(s / 60)
    const ss = String(s % 60).padStart(2, "0")
    return m >= 60 ? Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0") + ":" + ss
                   : m + ":" + ss
}

function songs(n) {
    return n === 1 ? "1 canción" : n + " canciones"
}

function minutes(ms) {
    return Math.max(1, Math.round(ms / 60000)) + " min"
}
