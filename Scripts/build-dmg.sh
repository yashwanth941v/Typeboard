#!/bin/zsh
#
# build-dmg.sh — Builds Typeboard in Release and packages it as a DMG.
#
#   ./Scripts/build-dmg.sh                      # sign with best available cert, no notarize
#   TYPEBOARD_NOTARIZE=1 TYPEBOARD_APPLE_ID=you@email.com \
#   TYPEBOARD_APP_PASSWORD=xxxx TYPEBOARD_TEAM_ID=97K8B6FK57 \
#   ./Scripts/build-dmg.sh                       # also notarize + staple (needs Developer ID cert)
#
# Notarization requires a Developer ID Application certificate. Create it at
# developer.apple.com -> Certificates -> + -> "Developer ID Application", then
# the script picks it up automatically.

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────
APP_NAME="Typeboard"
SCHEME="Typeboard"
CONFIG="Release"
TEAM_ID="${TYPEBOARD_TEAM_ID:-97K8B6FK57}"
DEVELOPER_DIR="/Applications/Xcode-beta.app/Contents/Developer"
OUTPUT_DMG="${1:-$HOME/Desktop/$APP_NAME.dmg}"
BUNDLE_ID="yashwanth941v.Typeboard"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Typeboard.xcodeproj"
WORK="$(mktemp -d -t typeboard-dmg)"
trap 'rm -rf "$WORK"' EXIT

# ── Signing identity (Developer ID wins, else Apple Development) ──────────
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
  | grep -E "Developer ID Application" | head -1 \
  | sed -E 's/.*"([^"]+)".*/\1/' || true)
USING_DEV_ID=0
if [[ -n "$IDENTITY" ]]; then
  USING_DEV_ID=1
  echo "== Using Developer ID identity: $IDENTITY"
else
  IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
    | grep -E "Apple Development" | head -1 \
    | sed -E 's/.*"([^"]+)".*/\1/' || true)
  echo "== No Developer ID cert — falling back to: $IDENTITY"
  echo "   Users will see a Gatekeeper warning until you add a Developer ID cert."
fi

# ── Build ─────────────────────────────────────────────────────────────────
echo "== Building ($CONFIG)..."
DEVELOPER_DIR="$DEVELOPER_DIR" xcrun xcodebuild \
  -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" \
  -derivedDataPath "$WORK/build" \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$TEAM_ID" \
  build 2>&1 | tail -3

APP="$WORK/build/Build/Products/$CONFIG/$APP_NAME.app"

# ── Sign / verify ──────────────────────────────────────────────────────────
if [[ $USING_DEV_ID -eq 1 ]]; then
  echo "== Re-signing with hardened runtime (required for notarization)..."
  codesign --force --deep --options runtime --sign "$IDENTITY" \
    --entitlements "$ROOT/Typeboard/Typeboard.entitlements" "$APP"
fi
codesign --verify --deep --strict "$APP" && echo "== Signature verified"
spctl --assess --type execute --verbose=2 "$APP" 2>&1 | tail -1 || true

# ── Notarize ───────────────────────────────────────────────────────────────
if [[ "${TYPEBOARD_NOTARIZE:-0}" == "1" ]]; then
  if [[ $USING_DEV_ID -ne 1 ]]; then
    echo "ERROR: Notarization requires a Developer ID Application cert." >&2
    exit 1
  fi
  : "${TYPEBOARD_APPLE_ID:?set TYPEBOARD_APPLE_ID}"
  : "${TYPEBOARD_APP_PASSWORD:?set TYPEBOARD_APP_PASSWORD}"
  echo "== Submitting for notarization..."
  ZIP="$WORK/$APP_NAME.zip"
  ditto -c -k --keepParent "$APP" "$ZIP"
  xcrun notarytool submit "$ZIP" \
    --apple-id "$TYPEBOARD_APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$TYPEBOARD_APP_PASSWORD" \
    --wait
  echo "== Stapling..."
  xcrun stapler staple "$APP"
fi

# ── Package DMG ────────────────────────────────────────────────────────────
echo "== Creating DMG..."
STAGE="$WORK/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

rm -f "$OUTPUT_DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" \
  -ov -format UDZO "$OUTPUT_DMG" >/dev/null

echo ""
echo "== Done: $OUTPUT_DMG"
echo "   Size: $(du -h "$OUTPUT_DMG" | cut -f1)"
