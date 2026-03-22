# RSSReader für macOS

Ein nativer macOS RSS-Reader mit unbegrenzten Feeds, Gruppen-Organisation, Menüleisten-Integration, Widget, Regelautomatisierung und vollständigem Export/Import.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.10](https://img.shields.io/badge/Swift-5.10-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-%E2%9C%93-brightgreen)
![Version](https://img.shields.io/badge/Version-1.0.1-informational)

---

## Features

| Feature | Beschreibung |
|---|---|
| **Unbegrenzte Feeds** | RSS, Atom und JSON Feed |
| **Gruppen-Sidebar** | Immer sichtbar (rechts), Drag & Drop Reihenfolge, umbenennen, löschen |
| **3-spaltige Ansicht** | Feeds · Artikel · Detail nebeneinander |
| **Menüleisten-Icon** | App immer per Klick erreichbar, zeigt ungelesene Artikel |
| **macOS Widget** | Klein, Mittel, Groß — Neueste Artikel im Notification Center |
| **Deep Links** | Widget-Klick öffnet direkt den Artikel in der App |
| **Regelautomatisierung** | Bedingungen → Aktionen (Benachrichtigung, Favorit, Sound, Kurzbefehl) |
| **Export & Import** | Backup als `.rssbackup` oder OPML für andere RSS-Reader |
| **Hintergrund-Refresh** | Konfigurierbares Intervall (5 min – 2 Std.) |
| **Light & Dark Mode** | Vollständig unterstützt, inkl. WebView-Artikelansicht |
| **Über RSSReader** | Eigenes About-Fenster mit GitHub-Links und Tech-Stack |

---

## Installation

### Einfach (empfohlen)

1. Neuestes DMG von [GitHub Releases](https://github.com/hansy2/rss-reader-macos/releases) herunterladen
2. DMG öffnen → **RSSReader.app** in den Programme-Ordner ziehen
3. App starten

> **Hinweis:** Da die App außerhalb des Mac App Store vertrieben wird, muss beim ersten Start `Ctrl + Klick → Öffnen` verwendet werden.

### Aus dem Quellcode

**Voraussetzungen:**
- macOS 14 (Sonoma) oder neuer
- Xcode 16+
- Apple Developer Account (für App Groups / Widget)
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

```bash
# Repository klonen
git clone https://github.com/hansy2/rss-reader-macos.git
cd rss-reader-macos/RSSReader

# Xcode-Projekt generieren
xcodegen generate

# In Xcode öffnen und mit dem eigenen Developer Team bauen
open RSSReader.xcodeproj
```

In `project.yml` und `Shared/AppGroup.swift` die Team-ID (`DCF47747Q6`) durch die eigene ersetzen.

---

## Export & Import

### Exportieren

**Einstellungen → Datensicherung → Exportieren** oder **Datei-Menü `⇧⌘E`**

| Format | Inhalt | Kompatibilität |
|---|---|---|
| **RSS Reader Backup (.rssbackup)** | Feeds, Gruppen, Regeln, Einstellungen | Nur RSS Reader |
| **OPML (.opml)** | Feeds & Gruppen | Reeder, NetNewsWire, Feedly, Inoreader u.v.m. |

### Importieren

**Einstellungen → Datensicherung → Importieren** oder **Datei-Menü `⇧⌘I`**

- Automatische Format-Erkennung (`.rssbackup` oder `.opml`)
- Vorschau: Anzahl Feeds, Gruppen und Regeln vor dem Import
- **Zusammenführen:** Neue Einträge hinzufügen, Duplikate überspringen
- **Alles ersetzen:** Vorhandene Daten löschen und komplett ersetzen

---

## Regelautomatisierung

Regeln bestehen aus einer **Bedingung** und einer **Aktion** und können optional auf einen einzelnen Feed beschränkt werden.

**Bedingungen:**

| Bedingung | Beschreibung |
|---|---|
| Titel enthält | Einfache Textsuche im Titel |
| Titel passt (Regex) | Regulärer Ausdruck |
| Autor ist | Exakter Autorenvergleich |
| Inhalt enthält | Suche in Titel, Autor, Inhalt oder URL |
| Jeder neue Artikel | Wird bei jedem neuen Artikel ausgelöst |

**Aktionen:**

| Aktion | Beschreibung |
|---|---|
| Benachrichtigung | macOS Systembenachrichtigung |
| Als Favorit markieren | Artikel wird mit Stern markiert |
| Sound abspielen | NSSound (z.B. „Basso", „Glass") |
| Kurzbefehl ausführen | Öffnet `shortcuts://run-shortcut?name=…` |

---

## Projektstruktur

```
rss-reader-macos/
└── RSSReader/
    ├── project.yml                          # xcodegen Konfiguration
    ├── RSSReader/
    │   ├── App/
    │   │   ├── RSSReaderApp.swift           # @main, Scenes, Menüs, Deep-Link
    │   │   └── AppRouter.swift              # Singleton für Widget → Artikel Navigation
    │   ├── Models/                          # SwiftData Models
    │   │   ├── Feed.swift
    │   │   ├── FeedGroup.swift
    │   │   ├── FeedItem.swift
    │   │   ├── Rule.swift
    │   │   └── BackupDocument.swift         # Codable Structs für Export/Import
    │   ├── Services/
    │   │   ├── FeedFetchService.swift        # Concurrent Feed-Abruf via TaskGroup
    │   │   ├── RuleEngine.swift             # Regelauswertung & Aktionen
    │   │   ├── BackgroundRefreshManager.swift
    │   │   ├── NotificationService.swift
    │   │   ├── BackupService.swift          # .rssbackup Export/Import
    │   │   └── OPMLService.swift            # OPML Export/Import (XMLParser)
    │   └── Views/
    │       ├── MainWindow/                  # ContentView, Sidebar, Artikelliste, Detail
    │       ├── MenuBar/                     # MenuBarView (mit ungelesenen Artikeln)
    │       ├── Rules/                       # RulesView (NavigationSplitView)
    │       ├── Settings/                    # SettingsView, ExportSheet, ImportSheet
    │       └── About/                       # AboutView
    ├── RSSReaderWidget/
    │   └── RSSReaderWidget.swift            # WidgetKit (Klein, Mittel, Groß)
    └── Shared/
        ├── SharedModelContainer.swift       # SwiftData Container (App Group)
        ├── AppGroup.swift                   # App Group ID Konfiguration
        └── WidgetDataBridge.swift           # JSON-Datenaustausch mit Widget
```

---

## Architektur

**Stack:** SwiftUI + SwiftData + [FeedKit](https://github.com/nmdias/FeedKit), macOS 14+

### UI-Layout

```
┌─────────────────────────────────────────┬──────────────┐
│  NavigationSplitView (3 Spalten)        │ GroupSidebar │
│  Feed-Liste │ Artikel-Liste │ Detail    │ (immer       │
│             │               │           │  sichtbar)   │
└─────────────────────────────────────────┴──────────────┘
```

Die Gruppen-Sidebar ist **außerhalb** der `NavigationSplitView` platziert, damit sie auf keiner Fenstergröße kollabiert.

### Datenfluss

1. `BackgroundRefreshManager` ruft alle X Minuten `FeedFetchService.fetchAll()` auf
2. `FeedFetchService` holt Feeds parallel via `withTaskGroup` (nur `PersistentModelID` wird thread-übergreifend übergeben, Swift 6 Sendable-konform)
3. Neue `FeedItem`s werden geprüft (GUID-Deduplizierung via `@Attribute(.unique)`) und in SwiftData eingefügt
4. `RuleEngine.evaluate()` prüft alle aktiven Regeln gegen neue Artikel
5. `WidgetDataBridge.write()` schreibt die neuesten Artikel als JSON in den App Group Container

### Widget Deep Links

Artikellinks im Widget verwenden das Schema `rssreader://article?id=<GUID>` (URL-encoded via `URLComponents`). `AppRouter.shared.pendingArticleGUID` koordiniert die Navigation wenn die App noch nicht läuft.

---

## Tastenkürzel

| Kürzel | Funktion |
|---|---|
| `⌘R` | Alle Feeds aktualisieren |
| `⇧⌘E` | Backup exportieren |
| `⇧⌘I` | Importieren |

---

## Lizenz

MIT — siehe [LICENSE](LICENSE)

---

## Links

- [Releases & Download](https://github.com/hansy2/rss-reader-macos/releases)
- [Issues & Feedback](https://github.com/hansy2/rss-reader-macos/issues)
- [FeedKit](https://github.com/nmdias/FeedKit) — RSS/Atom/JSON Parsing
