# CliniFlow

Application Flutter (Android et iOS) pour le chercheur clinicien, promoteur ou
investigateur principal : **qualifier sa recherche** en quelques questions,
puis **suivre pas à pas les démarches réglementaires** jusqu'à la clôture.

## Fonctionnalités (v0.1)

- **Qualification argumentée** : questionnaire à embranchements qui aboutit à
  l'une des 16 catégories couvertes, avec les raisons retenues et les points
  à faire confirmer (DRCI, DPO, CPP).
  - Loi Jardé : RIPH 1, RIPH 2, RIPH 3
  - Médicament (règlement UE 536/2014, CTIS), dont essais à faible niveau
    d'intervention
  - Dispositifs médicaux (règlement 2017/745 et classification DGS-ANSM :
    conformité, cas 1 à 4) et diagnostic in vitro (2017/746)
  - Recherches sur données : étude interne, MR-004, SNDS (MR-005 à MR-008),
    CESREES + autorisation CNIL
  - Projets hors recherche (évaluation des pratiques, enquêtes)
- **Parcours réglementaire** : checklist ordonnée par phase (conception,
  soumissions, démarrage, conduite, clôture), adaptée aux particularités
  (mineurs, majeurs protégés, urgence, génétique, collection, promoteur
  industriel, multicentrique, international, volontaires sains).
- **Suivi multi-projets** : statut de chaque étape, échéances, retards,
  notes ; stockage **uniquement local**, sans compte ni serveur.
- **Fiche de synthèse PDF** à partager ou imprimer.

## Architecture

```
lib/
  engine/   moteur de qualification en Dart pur (aucune dépendance Flutter)
    questions.dart   questionnaire et règles de visibilité
    classifier.dart  qualification argumentée
    pathways.dart    parcours réglementaire par catégorie
  data/     modèle Project et stockage local (shared_preferences)
  pdf/      fiche de synthèse (pdf + printing, police DejaVu embarquée)
  ui/       écrans Material 3
test/       tests du moteur et du modèle
tool/       bootstrap_platforms.sh : génère android/ et ios/ en CI
```

Le contenu réglementaire vit dans `lib/engine/`. Pour le mettre à jour,
modifier `classifier.dart` ou `pathways.dart`, puis lancer `flutter test` :
un test vérifie que chaque catégorie reste atteignable et produit un parcours.

## Développement

```bash
flutter pub get
bash tool/bootstrap_platforms.sh   # première fois : crée android/ et ios/
dart run flutter_launcher_icons
flutter run
```

Identifiant d'application : `fr.cliniflow.app`.

## Intégration continue

`.github/workflows/ci.yml` : analyse, tests, APK Android de release
(téléchargeable dans les artefacts de l'exécution), build iOS sans
signature, et version web publiée sur GitHub Pages
(https://franckled.github.io/cliniflow/). La publication App Store / Google Play nécessitera d'ajouter les
secrets de signature.

## Avertissement

CliniFlow est une aide à la décision. La qualification définitive d'une
recherche relève de son promoteur et, le cas échéant, du CPP saisi. Les délais
affichés sont indicatifs. Contenu réglementaire vérifié en octobre 2026.

Polices DejaVu : licence libre, voir `assets/fonts/DejaVu-LICENSE.txt`.
