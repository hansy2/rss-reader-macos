# Widget in Xcode einrichten

Das Widget kann nicht via `swift build` gebaut werden – WidgetKit-Extensions benötigen ein
Xcode-Projekt mit App Group Entitlements und einer Bundle-ID. Die Quelldateien liegen fertig in
`RSSReaderWidget/`.

## Schritt-für-Schritt

### 1. Xcode-Projekt erstellen
```
Xcode → File → Open → RSSReader/Package.swift
```
Xcode öffnet das SPM-Paket als Projekt.

### 2. Widget Extension Target hinzufügen
```
File → New → Target → Widget Extension
```
- **Product Name:** `RSSReaderWidget`
- **Include Live Activity:** Nein
- **Include Configuration App Intent:** Nein

### 3. Quelldateien ersetzen
Xcode erstellt Beispieldateien. Diese durch die fertigen Dateien ersetzen:

```
RSSReaderWidget/RSSReaderWidget.swift  →  Widget Entry + Provider + @main
RSSReaderWidget/RSSWidgetView.swift    →  Small / Medium / Large Views
```

Die `Shared/`-Dateien (`AppGroup.swift`, `WidgetDataBridge.swift`) dem Widget-Target
als **Compile Sources** hinzufügen (Target → Build Phases → Compile Sources → `+`).

### 4. App Group aktivieren

Für **beide Targets** (Haupt-App + Widget):
```
Target → Signing & Capabilities → + → App Groups
```
Gruppe hinzufügen: `group.com.rssreader.shared`

### 5. Bundle IDs setzen

| Target | Bundle ID |
|--------|-----------|
| RSSReader (Haupt-App) | `com.yourname.rssreader` |
| RSSReaderWidget | `com.yourname.rssreader.widget` |

### 6. Widget zur Haupt-App verknüpfen
```
Haupt-App Target → General → Frameworks, Libraries and Embedded Content → +
→ RSSReaderWidget.appex hinzufügen (Embed: Embed Without Signing)
```

### 7. Bauen & testen
```
Xcode → Run (⌘R)
```
Das Widget erscheint danach in der Notification Center Widget-Galerie (macOS Sonoma: auch
direkt auf dem Desktop platzierbar).

## Wie das Widget Daten bekommt

Nach jedem Feed-Abruf schreibt `FeedFetchService.updateWidget()` die 20 neuesten Artikel
als JSON in `UserDefaults(suiteName: "group.com.rssreader.shared")` und ruft
`WidgetCenter.shared.reloadAllTimelines()` auf. Das Widget liest diese Daten in
`ArticleTimelineProvider.getTimeline()`.

## Widget-Größen

| Größe | Artikel |
|-------|---------|
| Small | 1 Artikel (klickbar → öffnet im Browser) |
| Medium | 3 Artikel mit Feed-Titel & Zeitangabe |
| Large | 7 Artikel |
