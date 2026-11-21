# Graph Report - reproductor  (2026-11-21)

## Corpus Check
- Corpus is ~3,689 words - fits in a single context window. You may not need a graph.

## Summary
- 171 nodes · 320 edges · 11 communities (5 shown, 6 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 33 edges (avg confidence: 0.87)
- Token cost: 52,343 input · 0 output

## Community Hubs (Navigation)
- Modelo de álbumes
- Estado del reproductor
- Módulos e importaciones
- Documentación y funciones
- Metadatos y calidad de audio
- Lectura de letras
- Preferencias y tema

## God Nodes (most connected - your core abstractions)
1. `Player` - 54 edges
2. `PlaylistModel` - 22 edges
3. `CoverProvider` - 18 edges
4. `AlbumModel` - 17 edges
5. `Nómada (desktop music player)` - 17 edges
6. `Track` - 10 edges
7. `read_track()` - 9 edges
8. `read_lyrics()` - 8 edges
9. `read_audio_info()` - 8 edges
10. `AppSettings` - 8 edges

## Surprising Connections (you probably didn't know these)
- `Player` --uses--> `AlbumModel`  [INFERRED]
  player.py → albums.py
- `CoverProvider` --uses--> `Track`  [INFERRED]
  covers.py → metadata.py
- `Player` --uses--> `CoverProvider`  [INFERRED]
  player.py → covers.py
- `PlaylistModel` --uses--> `Track`  [INFERRED]
  playlist.py → metadata.py
- `Player` --uses--> `PlaylistModel`  [INFERRED]
  player.py → playlist.py

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Metadata features powered by mutagen (covers, lyrics, technical info)** — readme_mutagen, readme_embedded_cover_art, readme_synced_lyrics, readme_technical_info [EXTRACTED 1.00]
- **State persisted via QSettings (session, playback modes, theme)** — readme_qsettings, readme_session_persistence, readme_playback_modes, readme_themes [INFERRED 0.85]

## Communities (11 total, 6 thin omitted)

### Community 0 - "Modelo de álbumes"
Cohesion: 0.08
Nodes (4): Album, AlbumModel, CoverProvider, PlaylistModel

### Community 3 - "Documentación y funciones"
Cohesion: 0.14
Nodes (21): Drag and drop files/folders, Embedded cover art, Fluent (WinUI 3) native style on Windows 11, Keyboard shortcuts and media keys, Library (songs and albums views), mutagen (>=1.47), Nómada (desktop music player), "Open with" command-line file arguments (+13 more)

### Community 4 - "Metadatos y calidad de audio"
Cohesion: 0.16
Nodes (10): _duration(), _first(), _format_name(), _id3_text(), _khz(), _number(), read_audio_info(), read_cover() (+2 more)

### Community 6 - "Lectura de letras"
Cohesion: 0.24
Nodes (4): _embedded_lyrics(), parse_lrc(), read_lyrics(), _read_text_file()

### Community 8 - "Preferencias y tema"
Cohesion: 0.24
Nodes (3): AppSettings, _option(), setter()

## Knowledge Gaps
- **8 isolated node(s):** `Python 3.10+ requirement`, `Library (songs and albums views)`, `Playback modes (shuffle, repeat all, repeat one)`, `Supported audio formats (MP3, FLAC, OGG, OGA, Opus, M4A, MP4, AAC, WAV, WMA, AIFF)`, `Keyboard shortcuts and media keys` (+3 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 68 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Player` connect `Estado del reproductor` to `Modelo de álbumes`, `Módulos e importaciones`, `Acciones de álbum y modos`, `Lectura de letras`, `Cola y avance de pistas`, `Quitar y vaciar lista`?**
  _High betweenness centrality (0.375) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Player` (e.g. with `AlbumModel` and `CoverProvider`) actually correct?**
  _`Player` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Python 3.10+ requirement`, `Library (songs and albums views)`, `Playback modes (shuffle, repeat all, repeat one)` to the rest of the system?**
  _8 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Modelo de álbumes` be split into smaller, more focused modules?**
  _Cohesion score 0.08333333333333333 - nodes in this community are weakly interconnected._
- **Why does `PlaylistModel` connect `Modelo de álbumes` to `Estado del reproductor`, `Módulos e importaciones`, `Metadatos y calidad de audio`, `Acciones de álbum y modos`, `Quitar y vaciar lista`?**
  _High betweenness centrality (0.108) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `PlaylistModel` (e.g. with `AlbumModel` and `Player`) actually correct?**
  _`PlaylistModel` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Should `Estado del reproductor` be split into smaller, more focused modules?**
  _Cohesion score 0.10276679841897234 - nodes in this community are weakly interconnected._