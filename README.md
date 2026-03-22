# RSSReader für macOS

Ein nativer macOS RSS-Reader mit unbegrenzten Feeds, Gruppen-Organisation, Smart Folders, Lesemodus, Feed-Entdeckung, Menüleisten-Integration, Widget und Regelautomatisierung.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.10-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-%E2%9C%93-brightgreen) ![Version](https://img.shields.io/badge/Version-1.0.3-green)

---

## Download

**[→ Neueste Version herunterladen (v1.0.3)](https://github.com/hansy2/rss-reader-macos/releases/latest)**

DMG öffnen → App in Programme ziehen → fertig. Vollständig notarisiert, keine Sicherheitswarnung.

---

## Features

### Feeds & Navigation
- **Unbegrenzte Feeds** — RSS, Atom und JSON Feed unterstützt
- **Feed-Entdeckung** — Normale Website-URL eingeben, RSS-Feed wird automatisch gefunden
- **Gruppen-Sidebar (rechts, immer sichtbar)** — Feeds per Drag & Drop in Gruppen sortieren
- **Smart Folders** — Heute, Alle ungelesen, Favoriten + eigene Filter mit Stichworten
- **3-spaltige Ansicht** — Feeds · Artikel · Detail nebeneinander

### Lesen
- **Tastaturkürzel** — `J`/`K` Navigation, `M` gelesen markieren, `S` Stern, `Space` Browser
- **Schriftgröße & Lesemodus** — `A-`/`A+` Schriftgröße, Themes: Standard, Sepia, Schwarz
- **Volltext-Abruf** — Feeds mit Kurzinhalt können den vollständigen Artikel laden
- **Globale Artikelsuche** — Suche über alle Feeds (Titel, Autor, Beschreibung)

### Automatisierung
- **Regelautomatisierung** — Bedingungen → Aktionen (Benachrichtigung, Favorit, Sound, Kurzbefehl)
- **Hintergrund-Refresh** — Konfigurierbares Intervall (5–120 Minuten)

### Integration
- **Menüleisten-Icon** — App immer per Klick oben rechts erreichbar
- **macOS Widget** — Neueste Artikel im macOS Widget-Center (Klein, Mittel, Groß)
- **Import/Export** — OPML (kompatibel mit Reeder, NetNewsWire, Feedly) + eigenes Backup-Format

### Design
- **Light & Dark Mode** — Vollständig unterstützt inkl. WebView-Artikelansicht
- **Native macOS App** — SwiftUI + SwiftData, kein Electron

---

## Tastaturkürzel

| Kürzel | Aktion |
|---|---|
| `J` | Nächster Artikel |
| `K` | Vorheriger Artikel |
| `M` | Als gelesen/ungelesen markieren |
| `S` | Favorit setzen/entfernen |
| `Space` | Im Browser öffnen |
| `⌘R` | Alle Feeds aktualisieren |
| `⌘⇧E` | Backup exportieren |
| `⌘⇧I` | Importieren |

---

## Voraussetzungen (für Entwicklung)

- macOS 14 (Sonoma) oder neuer
- Xcode 16+
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

---

## Projekt aufsetzen

```bash
git clone https://github.com/hansy2/rss-reader-macos.git
cd rss-reader-macos/RSSReader

xcodegen generate
open RSSReader.xcodeproj
```

Dann in Xcode **⌘R** drücken.

---

## Projektstruktur

```
RSSReader/
├── project.yml                        # xcodegen Konfiguration
├── RSSReader/
│   ├── App/
│   │   ├── RSSReaderApp.swift         # @main, Menüleiste, Befehle
│   │   └── AppRouter.swift            # Deep-Link Navigation
│   ├── Models/
│   │   ├── Feed.swift                 # SwiftData: RSS-Feed-Quelle
│   │   ├── FeedGroup.swift            # SwiftData: Gruppe mit Sortierung
│   │   ├── FeedItem.swift             # SwiftData: Artikel (guid unique)
│   │   ├── Rule.swift                 # SwiftData: Automatisierungsregel
│   │   └── SmartFolder.swift          # SwiftData: Gespeicherter Filter
│   ├── Services/
│   │   ├── FeedFetchService.swift     # Concurrent Feed-Abruf via TaskGroup
│   │   ├── FeedDiscoveryService.swift # RSS-Auto-Discovery aus Website-URL
│   │   ├── FullTextService.swift      # Volltext-Extraktion aus Webseiten
│   │   ├── RuleEngine.swift           # Regelauswertung & Aktionen
│   │   ├── BackgroundRefreshManager.swift
│   │   └── NotificationService.swift
│   ├── Views/
│   │   ├── MainWindow/                # ContentView, Sidebar, Artikelliste, Detail
│   │   ├── MenuBar/                   # MenuBarView
│   │   ├── Rules/                     # RulesView
│   │   ├── Settings/                  # SettingsView (inkl. Import/Export)
│   │   └── About/                     # AboutView
│   └── Shared/
│       ├── ReadingSettings.swift      # Schriftgröße & Theme (UserDefaults)
│       ├── SharedModelContainer.swift # SwiftData Container
│       ├── AppGroup.swift             # App Group Konfiguration
│       └── WidgetDataBridge.swift     # Datenaustausch mit Widget
└── RSSReaderWidget/
    └── RSSReaderWidget.swift          # WidgetKit (Klein, Mittel, Groß)
```

---

## Architektur

**Stack:** SwiftUI + SwiftData + FeedKit, macOS 14+

### UI-Layout

```
┌────────────────────────────────────────────┬──────────────┐
│  NavigationSplitView (3 Spalten)            │ GroupSidebar │
│  Feed-Liste │ Artikel-Liste │ Detail         │ + Smart      │
│             │               │               │   Folders    │
└────────────────────────────────────────────┴──────────────┘
```

Die Gruppen-Sidebar ist **außerhalb** der `NavigationSplitView` platziert — sie kollabiert nie.

### Datenfluss

1. `BackgroundRefreshManager` → `FeedFetchService.fetchAll()` alle X Minuten
2. Feeds werden parallel via `withTaskGroup` abgerufen (nur `PersistentModelID` thread-übergreifend)
3. Neue `FeedItem`s in SwiftData eingefügt (Duplikat-Check via `@Attribute(.unique) guid`)
4. `RuleEngine.evaluate()` prüft Regeln gegen neue Artikel
5. `WidgetDataBridge.write()` schreibt JSON für das Widget

---

## Regeln

| Bedingung | Beschreibung |
|---|---|
| Titel enthält | Einfache Textsuche im Titel |
| Titel passt (Regex) | Regulärer Ausdruck |
| Autor ist | Exakter Autorenvergleich |
| Inhalt enthält | Suche in Titel, Autor, Inhalt oder URL |
| Jeder neue Artikel | Immer auslösen |

| Aktion | Beschreibung |
|---|---|
| Benachrichtigung | macOS Systembenachrichtigung |
| Als Favorit markieren | Artikel wird markiert |
| Sound abspielen | NSSound (z.B. „Basso") |
| Kurzbefehl ausführen | Öffnet `shortcuts://run-shortcut?name=…` |

---

## Import / Export

| Format | Import | Export | Kompatibel mit |
|---|---|---|---|
| `.rssbackup` | ✅ | ✅ | Nur RSS Reader (Feeds + Gruppen + Regeln) |
| `.opml` | ✅ | ✅ | Reeder, NetNewsWire, Feedly, Inoreader, … |

---

## Release bauen

```bash
cd RSSReader
xcodegen generate
xcodebuild -project RSSReader.xcodeproj -scheme RSSReader \
  -configuration Release -allowProvisioningUpdates clean build

# Notarisieren
xcrun notarytool submit RSSReader.zip \
  --keychain-profile "rssreader-notarize" --wait

# Ticket heften
xcrun stapler staple /path/to/RSSReader.app
```

---

## Lizenz

MIT License — siehe [LICENSE](LICENSE)

## Links

- [Issues & Feedback](https://github.com/hansy2/rss-reader-macos/issues)
- [Releases](https://github.com/hansy2/rss-reader-macos/releases)
