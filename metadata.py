import base64
import os
import re
from dataclasses import dataclass
from pathlib import Path

from mutagen import File as MutagenFile
from mutagen.flac import Picture

AUDIO_EXTENSIONS = {
    ".mp3", ".flac", ".ogg", ".oga", ".opus", ".m4a", ".mp4",
    ".aac", ".wav", ".wma", ".aiff", ".aif",
}


@dataclass(frozen=True)
class Track:
    path: str
    title: str
    artist: str
    album: str
    album_artist: str
    year: str
    track_no: int
    disc_no: int
    duration: int  # milisegundos
    has_cover: bool


def _first(tags, key: str) -> str:
    try:
        value = tags.get(key)
    except Exception:
        return ""
    return str(value[0]).strip() if value else ""


def _number(text: str) -> int:
    """'3/12' -> 3"""
    m = re.match(r"\s*(\d+)", text)
    return int(m.group(1)) if m else 0


# Para WAV/AIFF mutagen no ofrece modo "easy": se leen los marcos ID3 directamente.
_ID3_FRAMES = {"title": "TIT2", "artist": "TPE1", "album": "TALB", "albumartist": "TPE2",
               "date": "TDRC", "tracknumber": "TRCK", "discnumber": "TPOS"}


def _id3_text(tags, frame_id: str) -> str:
    frame = tags.get(frame_id)
    return str(frame.text[0]).strip() if frame is not None and frame.text else ""


def read_track(path: str) -> Track:
    tags = {}
    duration = 0
    try:
        audio = MutagenFile(path, easy=True)
    except Exception:
        audio = None
    if audio is not None:
        duration = int(getattr(audio.info, "length", 0) * 1000)
        if audio.tags:
            if hasattr(audio.tags, "getall"):
                tags = {k: _id3_text(audio.tags, f) for k, f in _ID3_FRAMES.items()}
            else:
                tags = {k: _first(audio.tags, k) for k in _ID3_FRAMES}
    return Track(
        path=path,
        title=tags.get("title") or Path(path).stem,
        artist=tags.get("artist") or "Artista desconocido",
        album=tags.get("album", ""),
        album_artist=tags.get("albumartist", ""),
        year=tags.get("date", "")[:4],
        track_no=_number(tags.get("tracknumber", "")),
        disc_no=_number(tags.get("discnumber", "")),
        duration=duration,
        has_cover=read_cover(path) is not None,
    )


def read_cover(path: str) -> bytes | None:
    """Devuelve los bytes de la carátula embebida, o None."""
    try:
        audio = MutagenFile(path)
        if audio is None:
            return None
        pictures = getattr(audio, "pictures", None)  # FLAC
        if pictures:
            return pictures[0].data
        tags = audio.tags
        if not tags:
            return None
        if hasattr(tags, "getall"):  # ID3 (MP3, WAV, AIFF)
            frames = tags.getall("APIC")
            front = [f for f in frames if f.type == 3]
            return (front or frames)[0].data if frames else None
        covr = tags.get("covr")  # MP4 / M4A
        if covr:
            return bytes(covr[0])
        blocks = tags.get("metadata_block_picture")  # Ogg Vorbis / Opus
        if blocks:
            return Picture(base64.b64decode(blocks[0])).data
    except Exception:
        return None
    return None


# ------------------------------------------------------------------- letras
_LRC_TIME = re.compile(r"\[(\d+):(\d{1,2}(?:[.:]\d{1,3})?)\]")
_LRC_OFFSET = re.compile(r"\[offset:\s*([+-]?\d+)\s*\]", re.IGNORECASE)
_LRC_WORD_TIME = re.compile(r"<\d+:\d+(?:[.:]\d+)?>")

Lyrics = list[tuple[int, str]]  # (milisegundos o -1 si no está sincronizada, texto)


def parse_lrc(text: str) -> Lyrics:
    """Convierte texto LRC en [(ms, línea)]. Devuelve [] si no tiene marcas de tiempo."""
    offset = 0
    lines = []
    for raw in text.splitlines():
        raw = raw.strip()
        m = _LRC_OFFSET.match(raw)
        if m:
            offset = int(m.group(1))
            continue
        times, pos = [], 0
        while m := _LRC_TIME.match(raw, pos):
            minutes, seconds = int(m.group(1)), float(m.group(2).replace(":", "."))
            times.append(int(minutes * 60000 + seconds * 1000))
            pos = m.end()
        lyric = _LRC_WORD_TIME.sub("", raw[pos:]).strip()
        lines += [(max(0, t - offset), lyric) for t in times]
    return sorted(lines, key=lambda line: line[0])


def _read_text_file(path: Path) -> str | None:
    for encoding in ("utf-8-sig", "cp1252"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
        except OSError:
            return None
    return None


def _embedded_lyrics(path: str) -> tuple[str | None, Lyrics]:
    """Devuelve (texto, líneas_sincronizadas) de las etiquetas del archivo."""
    try:
        audio = MutagenFile(path)
        tags = audio.tags if audio is not None else None
        if not tags:
            return None, []
        if hasattr(tags, "getall"):  # ID3
            for frame in tags.getall("SYLT"):
                if frame.format == 2 and frame.text:  # marcas en milisegundos
                    return None, sorted((t, s.strip()) for s, t in frame.text)
            uslt = tags.getall("USLT")
            return (uslt[0].text if uslt else None), []
        for key in ("\xa9lyr", "lyrics", "syncedlyrics", "unsyncedlyrics"):  # MP4 / Vorbis (FLAC, OGG)
            try:
                value = tags.get(key)
            except ValueError:  # p. ej. "©lyr" no es una clave válida en Vorbis
                continue
            if value:
                return str(value[0]), []
    except Exception:
        pass
    return None, []


def read_lyrics(path: str) -> tuple[Lyrics, bool]:
    """Busca un .lrc junto al archivo y, si no hay, la letra incrustada.
    Devuelve (líneas, sincronizada)."""
    lrc = Path(path).with_suffix(".lrc")
    text = _read_text_file(lrc) if lrc.is_file() else None
    if text is None:
        text, synced = _embedded_lyrics(path)
        if synced:
            return synced, True
    if not text or not text.strip():
        return [], False
    synced = parse_lrc(text)
    if synced:
        return synced, True
    return [(-1, line.rstrip()) for line in text.strip().splitlines()], False


# ------------------------------------------------------------ calidad de audio
_LOSSLESS = {"FLAC", "WAV", "AIFF", "ALAC", "WavPack", "APE", "TTA"}
_FORMAT_BY_CLASS = {
    "FLAC": "FLAC", "MP3": "MP3", "EasyMP3": "MP3", "OggVorbis": "Vorbis", "OggOpus": "Opus",
    "OggFLAC": "FLAC", "WAVE": "WAV", "AIFF": "AIFF", "ASF": "WMA", "WavPack": "WavPack",
    "MonkeysAudio": "APE", "TrueAudio": "TTA", "AAC": "AAC",
}


def _format_name(audio, path: str) -> tuple[str, str]:
    """Devuelve (formato, descripción del códec)."""
    name = type(audio).__name__ if audio is not None else ""
    if name in ("MP4", "EasyMP4"):
        codec = getattr(audio.info, "codec", "") or ""
        desc = getattr(audio.info, "codec_description", "") or ""
        return ("ALAC" if codec == "alac" else "AAC"), desc
    if name in ("MP3", "EasyMP3"):
        info = audio.info
        return "MP3", f"MPEG-{info.version:g} Layer {info.layer}"
    fmt = _FORMAT_BY_CLASS.get(name) or Path(path).suffix.lstrip(".").upper() or "Desconocido"
    return fmt, ""


def _khz(sample_rate: int) -> str:
    return f"{sample_rate / 1000:g} kHz"


def _duration(ms: int) -> str:
    s = ms // 1000
    return f"{s // 3600}:{s // 60 % 60:02d}:{s % 60:02d}" if s >= 3600 else f"{s // 60}:{s % 60:02d}"


def read_audio_info(track: Track) -> dict:
    """Datos técnicos de la canción, listos para mostrar."""
    path = track.path
    try:
        audio = MutagenFile(path)
    except Exception:
        audio = None
    info = audio.info if audio is not None else None
    fmt, codec = _format_name(audio, path)

    sample_rate = getattr(info, "sample_rate", 0) or (48000 if fmt == "Opus" else 0)
    bits = getattr(info, "bits_per_sample", 0) or 0
    channels = getattr(info, "channels", 0) or 0
    try:
        size = os.path.getsize(path)
    except OSError:
        size = 0
    bitrate = getattr(info, "bitrate", 0) or 0  # bits por segundo
    if not bitrate and size and track.duration:
        bitrate = int(size * 8 * 1000 / track.duration)
    mode = getattr(info, "bitrate_mode", None)
    mode = {1: "CBR", 2: "VBR", 3: "ABR"}.get(int(mode), "") if mode is not None else ""

    lossless = fmt in _LOSSLESS
    hires = lossless and (bits > 16 or sample_rate > 48000)
    tag = "HI-RES" if hires else "LOSSLESS" if lossless else ""

    if lossless and bits and sample_rate:
        badge = f"{fmt} · {bits} bit / {_khz(sample_rate)}"
    else:
        parts = [fmt]
        if bitrate:
            parts.append(f"{round(bitrate / 1000)} kbps")
        if sample_rate:
            parts.append(_khz(sample_rate))
        badge = " · ".join(parts)

    quality = " · ".join(p for p in (f"{bits} bit" if bits else "", _khz(sample_rate) if sample_rate else "") if p)
    channel_text = {1: "Mono", 2: "Estéreo"}.get(channels, f"{channels} canales" if channels else "")
    rows = [
        ("Título", track.title),
        ("Artista", track.artist),
        ("Álbum", track.album),
        ("Artista del álbum", track.album_artist if track.album_artist != track.artist else ""),
        ("Año", track.year),
        ("Pista", str(track.track_no) if track.track_no else ""),
        ("Formato", f"{fmt} ({codec})" if codec else fmt),
        ("Tipo", "Hi-Res (alta resolución)" if hires else "Sin pérdida" if lossless else "Con pérdida"),
        ("Calidad", quality),
        ("Bitrate", f"{round(bitrate / 1000)} kbps" + (f" ({mode})" if mode else "") if bitrate else ""),
        ("Canales", channel_text),
        ("Duración", _duration(track.duration) if track.duration else ""),
        ("Tamaño", (f"{size / 1_048_576:.1f} MB" if size >= 1_048_576 else f"{size / 1024:.0f} KB") if size else ""),
        ("Ubicación", os.path.normpath(path)),
    ]
    return {
        "badge": badge,
        "tag": tag,
        "folder": os.path.dirname(os.path.abspath(path)),
        "rows": [{"label": k, "value": v} for k, v in rows if v],
    }
