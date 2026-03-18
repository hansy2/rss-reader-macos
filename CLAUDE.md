# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is a Swift Package Manager project targeting macOS 14+.

```bash
# Build
cd RSSReader && swift build

# Run
cd RSSReader && swift run

# Build for release
cd RSSReader && swift build -c release

# Run tests (if added)
cd RSSReader && swift test

# Open in Xcode
cd RSSReader && open Package.swift
```

## Architecture

**Stack:** SwiftUI + SwiftData + FeedKit (RSS/Atom/JSON parsing), macOS 14+, Swift Package Manager.

### Data Model (SwiftData)
All models live in `RSSReader/RSSReader/Models/` and are registered in `Shared/SharedModelContainer.swift`:

- **`Feed`** – A single RSS/Atom/JSON subscription. Belongs to an optional `FeedGroup`. Has many `FeedItem`s (cascade delete).
- **`FeedGroup`** – Named group with `sortOrder` for drag-to-reorder. Deleting a group nullifies `feed.group` (feeds are kept).
- **`FeedItem`** – Individual article. `guid` has `@Attribute(.unique)` to prevent duplicates on re-fetch. `contentHTML` uses `@Attribute(.externalStorage)`.
- **`Rule`** – Automation rule: condition (titleContains, titleMatches regex, authorEquals, contentContains, anyNewArticle) → action (notification, markAsStarred, playSound, runShortcut via `shortcuts://` URL). Optional `scopeFeedURL` limits rule to a specific feed.

Persistence uses an App Group container (`group.com.rssreader.shared`) via `AppGroupConfig` so data can be shared with a future widget extension. The store file is `RSSReader.store` in that container.

### Services
- **`FeedFetchService`** – `@Observable`. Fetches all enabled feeds concurrently using `TaskGroup`. Inserts new items, updates `lastFetchedAt`, then triggers `RuleEngine.evaluate()`. Also supports single-feed refresh.
- **`RuleEngine`** – `@Observable`. Evaluates all enabled rules against newly fetched items. Dispatches actions synchronously (notifications via `NotificationService`, starring items directly, `NSSound`, opening Shortcuts via `NSWorkspace`).
- **`BackgroundRefreshManager`** – `@Observable`. Runs a looping `Task` that calls `FeedFetchService.fetchAll` every `refreshIntervalMinutes` minutes. Restarts when the interval changes.
- **`NotificationService`** – Wraps `UNUserNotificationCenter`. Call `requestPermission()` at app startup.

### UI Layout
`ContentView` uses a custom side-by-side layout (not a single NavigationSplitView):

```
[  NavigationSplitView (3 columns)  ] | [ GroupSidebarView ]
  FeedSidebar | ArticleList | Detail       (always visible, right side)
```

The **Groups sidebar is pinned to the right** outside the NavigationSplitView so it never collapses. It supports drag-to-reorder (`onMove`), rename (sheet), and delete (feeds stay, group reference is nullified).

**FeedSidebarView** filters `@Query(sort: \Feed.title)` client-side based on the selected group. Add-feed flow goes through `AddFeedView` sheet (TODO: not yet in repo).

**ArticleListView** has three filter modes (All / Unread / Starred) implemented as a `Picker(.segmented)`. Selecting an item auto-marks it as read.

**ArticleDetailView** renders HTML content using `WKWebView` wrapped in `NSViewRepresentable` (`WebContentView`). Injects a `<style>` block that adapts to light/dark mode via `-apple-system` color tokens and `color-scheme: light dark`.

### Localization
UI strings are currently in German (app targets German-speaking users). Rule condition/action `rawValue`s are also German (used as display labels).
