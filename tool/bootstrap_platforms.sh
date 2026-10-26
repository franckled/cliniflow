#!/usr/bin/env bash
# Génère les dossiers natifs android/ et ios/ s'ils n'existent pas encore,
# puis applique l'identité de l'application (nom affiché, identifiant).
# Idempotent : sans effet si les dossiers sont déjà présents et configurés.
set -euo pipefail

APP_ID="fr.cliniflow.app"
APP_NAME="CliniFlow"

cd "$(dirname "$0")/.."

if [[ ! -d android || ! -d ios ]]; then
  flutter create --platforms=android,ios --org fr.cliniflow \
    --project-name cliniflow --no-pub .
  # `flutter create` ajoute un test d'exemple qui ne correspond pas à l'app.
  rm -f test/widget_test.dart
fi

# Android : identifiant et nom affiché.
GRADLE=android/app/build.gradle.kts
[[ -f $GRADLE ]] || GRADLE=android/app/build.gradle
sed -i.bak -E "s/applicationId[ =]+\"[^\"]+\"/applicationId = \"$APP_ID\"/" "$GRADLE"
sed -i.bak -E "s/namespace[ =]+\"[^\"]+\"/namespace = \"$APP_ID\"/" "$GRADLE"
if [[ $GRADLE == *.gradle ]]; then
  # Syntaxe Groovy : pas de signe égal.
  sed -i.bak -E "s/applicationId = \"/applicationId \"/; s/namespace = \"/namespace \"/" "$GRADLE"
fi
rm -f "$GRADLE.bak"

# Le package Kotlin de MainActivity doit suivre le namespace.
MAIN=$(find android/app/src/main -name 'MainActivity.kt' | head -n1)
if [[ -n $MAIN ]]; then
  DEST="android/app/src/main/kotlin/${APP_ID//.//}"
  mkdir -p "$DEST"
  sed -E "s/^package .*/package $APP_ID/" "$MAIN" > "$DEST/MainActivity.kt.tmp"
  [[ "$MAIN" != "$DEST/MainActivity.kt" ]] && rm -f "$MAIN"
  mv "$DEST/MainActivity.kt.tmp" "$DEST/MainActivity.kt"
  find android/app/src/main/kotlin -type d -empty -delete
fi

MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i.bak -E "s/android:label=\"[^\"]*\"/android:label=\"$APP_NAME\"/" "$MANIFEST"
rm -f "$MANIFEST.bak"

# iOS : identifiant de bundle et nom affiché.
PBX=ios/Runner.xcodeproj/project.pbxproj
sed -i.bak -E "s/PRODUCT_BUNDLE_IDENTIFIER = fr\.cliniflow\.cliniflow;/PRODUCT_BUNDLE_IDENTIFIER = $APP_ID;/; s/PRODUCT_BUNDLE_IDENTIFIER = fr\.cliniflow\.cliniflow\.RunnerTests;/PRODUCT_BUNDLE_IDENTIFIER = $APP_ID.RunnerTests;/" "$PBX"
rm -f "$PBX.bak"

PLIST=ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $APP_NAME" "$PLIST" 2>/dev/null \
  || python3 - "$PLIST" "$APP_NAME" <<'PY'
import plistlib, sys
path, name = sys.argv[1], sys.argv[2]
with open(path, 'rb') as f:
    data = plistlib.load(f)
data['CFBundleDisplayName'] = name
data['CFBundleName'] = name
data['ITSAppUsesNonExemptEncryption'] = False
with open(path, 'wb') as f:
    plistlib.dump(data, f)
PY

# Pas de chiffrement propriétaire : évite la question export à chaque envoi.
/usr/libexec/PlistBuddy -c "Add :ITSAppUsesNonExemptEncryption bool false" "$PLIST" 2>/dev/null || true

echo "Plateformes prêtes : $APP_NAME ($APP_ID)"
