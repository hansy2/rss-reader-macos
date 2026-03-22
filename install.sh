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

# 3. Team-ID ermitteln
TEAM_ID="${DEVELOPMENT_TEAM:-}"
if [ -z "$TEAM_ID" ]; then
    # Aus Xcode-Einstellungen lesen (falls schon eingeloggt)
    TEAM_ID=$(defaults read com.apple.dt.Xcode DVTDeveloperAccountManagerLastUsedAccountIdentifier 2>/dev/null || true)
fi
if [ -z "$TEAM_ID" ]; then
    # Aus vorhandenen Zertifikaten lesen
    TEAM_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep -oE '\([A-Z0-9]{10}\)' | head -1 | tr -d '()')
fi

if [ -z "$TEAM_ID" ]; then
    echo ""
    echo "⚠️  Kein Developer-Team gefunden."
    echo ""
    echo "   Bitte einmalig in Xcode anmelden:"
    echo "   1. Öffne: open '$RSSREADER_DIR/RSSReader.xcodeproj'"
    echo "   2. Xcode → Settings → Accounts → Apple ID hinzufügen (kostenlos)"
    echo "   3. Im Projekt: Target 'RSSReader' → Signing & Capabilities"
    echo "      → Team auswählen (dein Name)"
    echo "   4. Danach dieses Skript erneut ausführen"
    echo ""
    echo "   Oder Team-ID direkt übergeben:"
    echo "   DEVELOPMENT_TEAM=XXXXXXXXXX ./install.sh"
    echo ""
    open "$RSSREADER_DIR/RSSReader.xcodeproj"
    exit 1
fi

echo "✅ Team-ID: $TEAM_ID"

# 4. Build
echo "🔨 Baue App (Release)..."
BUILD_DIR=$(mktemp -d)

xcodebuild \
    -project "$RSSREADER_DIR/RSSReader.xcodeproj" \
    -scheme RSSReader \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates \
    build 2>&1 | grep -E "(error:|warning:|Build succeeded|Build FAILED|Compiling|Linking)" | tail -30

# 5. App finden
APP_PATH=$(find "$BUILD_DIR/Build/Products" -name "$APP_NAME" -type d | head -1)
if [ -z "$APP_PATH" ]; then
    echo "❌ Build fehlgeschlagen – App nicht gefunden."
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

# 7. App starten (Widget registrieren)
echo "🚀 Starte RSSReader..."
open "$INSTALL_PATH"

echo ""
echo "✅ Fertig! RSSReader ist installiert."
echo ""
echo "   Widget aktivieren:"
echo "   1. Klicke mit der rechten Maustaste auf den Desktop"
echo "   2. → 'Widgets bearbeiten'"
echo "   3. → 'RSSReader' suchen und Widget hinzufügen"
echo ""
