"""Neutralise les caches de la version web après `flutter build web`.

- désinscrit tout service worker installé par une version précédente ;
- interdit la mise en cache de index.html ;
- ajoute un paramètre de version aux scripts d'amorçage et au code compilé,
  pour que le navigateur télécharge la nouvelle version immédiatement.
"""
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
version = sys.argv[2]

index = root / 'index.html'
html = index.read_text(encoding='utf-8')

head_extra = (
    '<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">\n'
    '  <meta http-equiv="Pragma" content="no-cache">\n'
    '  <meta http-equiv="Expires" content="0">\n'
    '  <script>\n'
    '    if ("serviceWorker" in navigator) {\n'
    '      navigator.serviceWorker.getRegistrations()\n'
    '        .then(rs => rs.forEach(r => r.unregister())).catch(() => {});\n'
    '    }\n'
    '    if (window.caches) {\n'
    '      caches.keys().then(ks => ks.forEach(k => caches.delete(k))).catch(() => {});\n'
    '    }\n'
    '  </script>\n'
)
if 'serviceWorker.getRegistrations' not in html:
    html = html.replace('<head>', '<head>\n  ' + head_extra, 1)
html = re.sub(r'flutter_bootstrap\.js(\?v=[^"\']*)?',
              f'flutter_bootstrap.js?v={version}', html)
index.write_text(html, encoding='utf-8')

boot = root / 'flutter_bootstrap.js'
if boot.exists():
    js = boot.read_text(encoding='utf-8')
    # Pas de service worker : chaque chargement prend la version publiée.
    js = re.sub(r'serviceWorkerSettings\s*:\s*\{[^}]*\}\s*,?', '', js)
    js = js.replace('"main.dart.js"', f'"main.dart.js?v={version}"')
    boot.write_text(js, encoding='utf-8')

# Le service worker éventuel est remplacé par un script qui se désinstalle.
(root / 'flutter_service_worker.js').write_text(
    "self.addEventListener('install', () => self.skipWaiting());\n"
    "self.addEventListener('activate', e => e.waitUntil(\n"
    "  caches.keys().then(ks => Promise.all(ks.map(k => caches.delete(k))))\n"
    "    .then(() => self.registration.unregister())));\n",
    encoding='utf-8',
)
print(f'Cache neutralisé pour la version {version}')
