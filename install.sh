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

# 3. Gültiges Signing-Zertifikat prüfen
CERT=$(security find-identity -v -p codesigning 2>/dev/null | grep "Mac Development\|Apple Development" | head -1)
TEAM_ID="${DEVELOPMENT_TEAM:-}"

if [ -z "$CERT" ] || [ -z "$(echo "$CERT" | grep -oE '[A-Z0-9]{10}')" ]; then
    echo ""
    echo "⚠️  Kein gültiges Signing-Zertifikat gefunden."
    echo ""
    echo "   Bitte jetzt in Xcode anmelden (einmalig, kostenlos):"
    echo ""
    echo "   1. Xcode öffnet sich gleich"
    echo "   2. Xcode → Settings (⌘,) → Accounts → + → Apple ID"
    echo "   3. Deine Apple ID eingeben und anmelden"
    echo "   4. Danach dieses Terminal-Fenster wieder aktivieren"
    echo "   5. Enter drücken um weiterzumachen"
    echo ""
    open "$RSSREADER_DIR/RSSReader.xcodeproj"
    read -p "   [Enter drücken wenn du in Xcode angemeldet bist]"
    echo ""

    # Erneut prüfen
    CERT=$(security find-identity -v -p codesigning 2>/dev/null | grep "Mac Development\|Apple Development" | head -1)
    if [ -z "$CERT" ]; then
        echo "❌ Immer noch kein Zertifikat. Bitte in Xcode anmelden und erneut versuchen."
        exit 1
    fi
fi

# Team-ID aus Zertifikat extrahieren
if [ -z "$TEAM_ID" ]; then
    TEAM_ID=$(echo "$CERT" | grep -oE '[A-Z0-9]{10}' | head -1)
fi

echo "✅ Zertifikat: $(echo "$CERT" | sed 's/.*) //')"
echo "✅ Team-ID:    $TEAM_ID"

# 4. Build
echo ""
echo "🔨 Baue App (Release) – das dauert ca. 1-2 Minuten..."
BUILD_DIR=$(mktemp -d)

set +e
BUILD_OUTPUT=$(xcodebuild \
    -project "$RSSREADER_DIR/RSSReader.xcodeproj" \
    -scheme RSSReader \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates \
    build 2>&1)
BUILD_EXIT=$?
set -e

if [ $BUILD_EXIT -ne 0 ]; then
    echo ""
    echo "❌ Build fehlgeschlagen. Fehlerdetails:"
    echo "$BUILD_OUTPUT" | grep "error:" | head -20
    echo ""
    echo "   Tipp: Öffne das Projekt in Xcode und prüfe Signing & Capabilities:"
    echo "   open '$RSSREADER_DIR/RSSReader.xcodeproj'"
    rm -rf "$BUILD_DIR"
    exit 1
fi

# 5. App finden
APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "$APP_NAME" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ App nach Build nicht gefunden."
    rm -rf "$BUILD_DIR"
    exit 1
fi

# 6. In /Applications installieren
echo "📲 Installiere nach /Applications..."
if [ -d "$INSTALL_PATH" ]; then
    echo "   (Alte Version wird ersetzt)"
    rm -rf "$INSTALL_PATH"
fi
cp -R "$APP_PATH" /Applications/
rm -rf "$BUILD_DIR"

# 7. App starten (damit macOS das Widget registriert)
echo "🚀 Starte RSSReader..."
open "$INSTALL_PATH"

echo ""
echo "✅ Fertig! RSSReader wurde nach /Applications installiert."
echo ""
echo "   Widget aktivieren:"
echo "   1. Rechtsklick auf den Desktop → 'Widgets bearbeiten'"
echo "   2. Links 'RSSReader' suchen"
echo "   3. Widget per Klick oder Drag hinzufügen"
echo ""
