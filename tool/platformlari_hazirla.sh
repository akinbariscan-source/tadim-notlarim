#!/usr/bin/env bash
# Tadım Notlarım — eksik platform klasörlerini (android/ios/web) oluşturur ve ayarlar.
# Kullanım:
#   bash tool/platformlari_hazirla.sh            → android + ios + web
#   bash tool/platformlari_hazirla.sh android    → yalnızca android
# Var olan dosyalara dokunmaz; yalnızca eksikleri ekler ve izin/ad ayarlarını yapar.
set -euo pipefail
cd "$(dirname "$0")/.."

PLATFORMS="${1:-android,ios,web}"
APP_NAME="Tadım Notlarım"

echo "▶ flutter create ($PLATFORMS)"
flutter create . --platforms="$PLATFORMS" --org com.tadimnotlarim --project-name tadim_notlarim >/dev/null

flutter pub get >/dev/null

# --- Android ---------------------------------------------------------------
MANIFEST=android/app/src/main/AndroidManifest.xml
if [[ -f "$MANIFEST" ]]; then
  echo "▶ Android: uygulama adı"
  sed -i.bak -E "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" "$MANIFEST" && rm -f "$MANIFEST.bak"
fi

# --- iOS (yalnızca Mac'te anlamlı) -----------------------------------------
PLIST=ios/Runner/Info.plist
if [[ -f "$PLIST" ]] && command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
  echo "▶ iOS: kamera/fotoğraf izinleri ve uygulama adı"
  PB=/usr/libexec/PlistBuddy
  set_key() {
    $PB -c "Set :$1 '$2'" "$PLIST" 2>/dev/null || $PB -c "Add :$1 string '$2'" "$PLIST"
  }
  set_key CFBundleDisplayName "$APP_NAME"
  set_key NSCameraUsageDescription "Şarap etiketinin fotoğrafını çekmek için kamera kullanılır."
  set_key NSPhotoLibraryUsageDescription "Etiket fotoğrafını galeriden seçmek için kullanılır."
  # Google ML Kit en az iOS 15.5 ister
  if [[ -f ios/Podfile ]]; then
    sed -i '' -E "s/^#? *platform :ios, .*/platform :ios, '15.5'/" ios/Podfile
  fi
fi

echo "▶ Uygulama simgeleri"
dart run flutter_launcher_icons >/dev/null || echo "  (simge üretilemedi, sonra tekrar deneyebilirsin)"

echo "✔ Hazır."
