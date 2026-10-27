#!/usr/bin/env python3
"""Configure la signature « release » Android à partir de android/key.properties.

À lancer après tool/bootstrap_platforms.sh. Idempotent. Sans key.properties,
le build release reste signé avec la clé de débogage (APK de test).
"""
import pathlib
import sys

root = pathlib.Path(__file__).resolve().parent.parent
gradle = root / 'android' / 'app' / 'build.gradle.kts'
if not gradle.exists():
    sys.exit('android/app/build.gradle.kts introuvable : lancez bootstrap_platforms.sh')

s = gradle.read_text(encoding='utf-8')
if 'keystoreProperties' in s:
    print('Signature release déjà configurée')
    sys.exit(0)

imports = '''import java.io.FileInputStream
import java.util.Properties

'''

props = '''
// Clé d'envoi Google Play, fournie par la CI (android/key.properties).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
'''

signing = '''    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {'''

# Kotlin DSL : seuls les imports peuvent précéder le bloc plugins { } ; les
# propriétés sont déclarées juste après sa fermeture.
start = s.find('plugins {')
end = s.find('\n}\n', start)
if start < 0 or end < 0:
    sys.exit('Bloc plugins introuvable dans build.gradle.kts')
end += len('\n}\n')
s = imports + s[:end] + props + s[end:]
if '    buildTypes {' not in s:
    sys.exit('Bloc buildTypes introuvable dans build.gradle.kts')
s = s.replace('    buildTypes {', signing, 1)

old = 'signingConfig = signingConfigs.getByName("debug")'
new = ('signingConfig = if (keystorePropertiesFile.exists()) '
       'signingConfigs.getByName("release") else signingConfigs.getByName("debug")')
if old not in s:
    sys.exit('Configuration de signature release introuvable')
s = s.replace(old, new, 1)

gradle.write_text(s, encoding='utf-8')
print('Signature release configurée')
