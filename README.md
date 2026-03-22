# RSSReader für macOS

Ein nativer macOS RSS-Reader mit unbegrenzten Feeds, Gruppen-Organisation, Menüleisten-Integration, Widget und Regelautomatisierung.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.10-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-%E2%9C%93-brightgreen)

---

## Features

- **Unbegrenzte Feeds** — RSS, Atom und JSON Feed werden alle unterstützt
- **Gruppen-Sidebar (rechts, immer sichtbar)** — Feeds per Drag & Drop in Gruppen sortieren, umbenennen, löschen
- **3-spaltige Ansicht** — Feeds · Artikel · Detail nebeneinander
- **Menüleisten-Icon** — App immer per Klick oben rechts erreichbar
- **macOS Widget** — Neueste Artikel als Ticker im macOS Widget-Center
- **Regelautomatisierung** — Bedingungen (Titel enthält, Regex, Autor, Inhalt) → Aktionen (Benachrichtigung, Favorit setzen, Sound, Kurzbefehl)
- **Hintergrund-Refresh** — Konfigurierbares Intervall, läuft automatisch
- **Light & Dark Mode** — Vollständig unterstützt, inkl. WebView-Artikelansicht

---

## Voraussetzungen

- macOS 14 (Sonoma) oder neuer
- Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (für das Xcode-Projekt)

```bash
brew install xcodegen
```

---

## Projekt aufsetzen

```bash
# Repository klonen
git clone https://github.com/hansy2/rss-reader-macos.git
cd rss-reader-macos/RSSReader

# Xcode-Projekt generieren
xcodegen generate

# In Xcode öffnen
open RSSReader.xcodeproj
```

Dann in Xcode **⌘R** drücken — keine Code-Signing-Konfiguration nötig (läuft unsigned lokal).

---

## Projektstruktur

```
RSSReader/
├── project.yml                        # xcodegen Konfiguration
├── Package.swift                      # SPM (FeedKit dependency)
├── RSSReader/
│   ├── App/
│   │   └── RSSReaderApp.swift         # @main, Menüleiste, SwiftData-Setup
│   ├── Models/                        # SwiftData Models
│   │   ├── Feed.swift
│   │   ├── FeedGroup.swift
│   │   ├── FeedItem.swift
│   │   └── Rule.swift
│   ├── Services/
│   │   ├── FeedFetchService.swift     # Concurrent Feed-Abruf via TaskGroup
│   │   ├── RuleEngine.swift           # Regelauswertung & Aktionen
│   │   ├── BackgroundRefreshManager.swift
│   │   └── NotificationService.swift
│   ├── Views/
│   │   ├── MainWindow/                # ContentView, Sidebar, Artikelliste, Detail
│   │   ├── MenuBar/                   # MenuBarView
│   │   ├── Rules/                     # RulesView
│   │   ├── Settings/                  # SettingsView
│   │   └── Components/                # AssignGroupView, etc.
│   └── Shared/
│       ├── SharedModelContainer.swift # SwiftData Container
│       ├── AppGroup.swift             # App Group / Pfad-Konfiguration
│       └── WidgetDataBridge.swift     # Datenaustausch mit Widget
└── RSSReaderWidget/
    ├── RSSReaderWidget.swift          # WidgetKit Entry Point
    └── RSSWidgetView.swift            # Widget UI (Ticker)
```

---

## Architektur

**Stack:** SwiftUI + SwiftData + FeedKit, macOS 14+

### UI-Layout

```
┌─────────────────────────────────────────┬──────────────┐
│  NavigationSplitView (3 Spalten)         │ GroupSidebar │
│  Feed-Liste │ Artikel-Liste │ Detail     │ (immer       │
│             │               │           │  sichtbar)   │
└─────────────────────────────────────────┴──────────────┘
```

Die Gruppen-Sidebar ist **außerhalb** der `NavigationSplitView` platziert, damit sie auf keiner Fenstergröße kollabiert.

### Datenfluss

1. `BackgroundRefreshManager` ruft alle X Minuten `FeedFetchService.fetchAll()` auf
2. `FeedFetchService` holt Feeds parallel via `withTaskGroup` (nur `PersistentModelID` wird thread-übergreifend übergeben)
3. Neue `FeedItem`s werden in SwiftData eingefügt
4. `RuleEngine.evaluate()` prüft alle aktiven Regeln gegen neue Artikel
5. `WidgetDataBridge.write()` schreibt die neuesten Artikel als JSON für das Widget

### Widget

Das Widget liest `widget.json` aus `~/Library/Application Support/` und zeigt die letzten Artikel als Ticker an. Kein App Group / kein Developer Account nötig.

---

## Regeln

Regeln bestehen aus einer **Bedingung** und einer **Aktion**:

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
| Als Favorit markieren | Artikel wird gestern |
| Sound abspielen | NSSound (z.B. „Basso") |
| Kurzbefehl ausführen | Öffnet `shortcuts://run-shortcut?name=…` |

---

## Build-Befehle

```bash
# Nur bauen (ohne Xcode)
cd RSSReader && swift build

# Release-Build
cd RSSReader && swift build -c release

# Tests
cd RSSReader && swift test
```
