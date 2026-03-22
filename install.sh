#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RSSREADER_DIR="$SCRIPT_DIR/RSSReader"
APP_NAME="RSSReader.app"
INSTALL_PATH="/Applications/$APP_NAME"

echo "🔧 RSSReader Installer"
echo "======================"

# 1. xcodegen prüfen
if ! command -v xcodegen &>/dev/null; then
    echo "📦 xcodegen nicht gefunden – wird via Homebrew installiert..."
    if ! command -v brew &>/dev/null; then
        echo "❌ Homebrew nicht gefunden. Bitte installieren: https://brew.sh"
        exit 1
    fi
    brew install xcodegen
fi

# 2. Xcode-Projekt generieren
echo "⚙️  Generiere Xcode-Projekt..."
cd "$RSSREADER_DIR"
xcodegen generate

# 3. In Xcode bauen lassen
echo ""
echo "📂 Öffne Xcode..."
open "$RSSREADER_DIR/RSSReader.xcodeproj"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Bitte jetzt in Xcode:"
echo ""
echo "  1. Falls noch kein Account: Xcode → Settings (⌘,)"
echo "     → Accounts → + → Apple ID eingeben"
echo ""
echo "  2. Im Projekt-Navigator oben 'RSSReader' anklicken"
echo "     → Signing & Capabilities → Team auswählen"
echo "     (für RSSReader UND RSSReaderWidget)"
echo ""
echo "  3. Scheme oben auf 'RSSReader' + 'My Mac' stellen"
echo ""
echo "  4. ⌘B drücken (Build) – warten bis 'Build Succeeded'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "  [Enter drücken wenn 'Build Succeeded' erschienen ist]"
echo ""

# 4. App aus DerivedData suchen und installieren
echo "🔍 Suche gebaute App..."
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA" -name "$APP_NAME" -path "*/Build/Products/Release/*" -type d 2>/dev/null | \
    grep -i "RSSReader" | sort -t/ -k1,1 | tail -1)

# Fallback: Debug-Build
if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find "$DERIVED_DATA" -name "$APP_NAME" -path "*/Build/Products/Debug/*" -type d 2>/dev/null | \
        grep -i "RSSReader" | sort | tail -1)
fi

if [ -z "$APP_PATH" ]; then
    echo "❌ App nicht gefunden. Wurde der Build in Xcode erfolgreich abgeschlossen?"
    echo "   Suche in: $DERIVED_DATA"
    exit 1
fi

echo "   Gefunden: $APP_PATH"

# 5. Installieren
echo "📲 Installiere nach /Applications..."
if [ -d "$INSTALL_PATH" ]; then
    echo "   (Alte Version wird ersetzt)"
    rm -rf "$INSTALL_PATH"
fi
cp -R "$APP_PATH" /Applications/

# 6. App starten
echo "🚀 Starte RSSReader..."
open "$INSTALL_PATH"

echo ""
echo "✅ Fertig! RSSReader ist in /Applications installiert."
echo ""
echo "   Widget aktivieren:"
echo "   1. Rechtsklick auf den Desktop → 'Widgets bearbeiten'"
echo "   2. Links 'RSSReader' suchen"
echo "   3. Widget hinzufügen"
echo ""
