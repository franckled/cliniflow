#!/usr/bin/env bash
# Génère le dossier web/ s'il n'existe pas encore, puis applique le nom et les
# couleurs de l'application. Idempotent.
set -euo pipefail

APP_NAME="CliniFlow"
DESCRIPTION="Qualifier une recherche clinique et suivre ses démarches réglementaires."
INK="#12324A"

cd "$(dirname "$0")/.."

if [[ ! -d web ]]; then
  flutter create --platforms=web --org fr.cliniflow \
    --project-name cliniflow --no-pub .
  rm -f test/widget_test.dart
fi

python3 - "$APP_NAME" "$DESCRIPTION" "$INK" <<'PY'
import json, re, sys
name, desc, ink = sys.argv[1:]

path = 'web/index.html'
html = open(path, encoding='utf-8').read()
html = re.sub(r'<title>.*?</title>', f'<title>{name}</title>', html, flags=re.S)
html = re.sub(r'(<meta name="description" content=")[^"]*', rf'\g<1>{desc}', html)
html = re.sub(r'(<meta name="apple-mobile-web-app-title" content=")[^"]*',
              rf'\g<1>{name}', html)
html = html.replace('<html>', '<html lang="fr">')
open(path, 'w', encoding='utf-8').write(html)

path = 'web/manifest.json'
m = json.load(open(path, encoding='utf-8'))
m.update(name=name, short_name=name, description=desc,
         background_color=ink, theme_color=ink, lang='fr')
json.dump(m, open(path, 'w', encoding='utf-8'), ensure_ascii=False, indent=4)
PY

echo "Web prêt : $APP_NAME"
