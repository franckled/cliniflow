import 'package:cliniflow/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

Answers _a(Map<String, Object> m) => {
      for (final e in m.entries)
        e.key: switch (e.value) {
          final String s => {s},
          final Set<String> s => s,
          _ => throw ArgumentError(e.value),
        },
    };

/// Réponses prospectives de base (stratégie, sans produit de santé).
Map<String, Object> _prospective({
  String intervention = 'aucune',
  Set<String> actes = const {},
  Set<String> contexte = const {},
}) =>
    {
      Q.objectif: 'recherche',
      Q.personnes: 'oui',
      Q.produit: 'aucun',
      Q.intervention: intervention,
      if (intervention != 'lourde') Q.actes: actes,
      Q.contexte: contexte,
    };

ResearchCategory? _cat(Map<String, Object> m) => classify(_a(m))?.category;

void main() {
  group('questionnaire', () {
    test('incomplet tant qu\'une question visible est sans réponse', () {
      expect(classify(_a({Q.objectif: 'recherche'})), isNull);
      expect(
        classify(_a({Q.objectif: 'recherche', Q.personnes: 'oui'})),
        isNull,
      );
    });

    test('les réponses d\'une branche abandonnée sont élaguées', () {
      final pruned = pruneAnswers(_a({
        Q.objectif: 'recherche',
        Q.personnes: 'non',
        Q.produit: 'medicament',
        Q.source: 'interne',
      }));
      expect(pruned.containsKey(Q.produit), isFalse);
      expect(pruned.containsKey(Q.source), isTrue);
    });

    test('chaque identifiant de question est unique', () {
      final ids = questionnaire.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('hors recherche', () {
    test('évaluation des pratiques', () {
      expect(_cat({Q.objectif: 'pratiques'}), ResearchCategory.horsRecherche);
    });
    test('enquête auprès de professionnels', () {
      expect(
        _cat({Q.objectif: 'professionnels'}),
        ResearchCategory.horsRecherche,
      );
    });
  });

  group('loi Jardé', () {
    test('intervention lourde → RIPH 1', () {
      expect(_cat(_prospective(intervention: 'lourde')), ResearchCategory.riph1);
    });
    test('prise sanguine supplémentaire → RIPH 2', () {
      expect(
        _cat(_prospective(intervention: 'minime', actes: {'sang'})),
        ResearchCategory.riph2,
      );
    });
    test('randomisation entre soins courants → RIPH 2, jamais RIPH 3', () {
      final c = classify(_a(_prospective(actes: {'randomisation'})))!;
      expect(c.category, ResearchCategory.riph2);
      expect(c.toConfirm.isNotEmpty, isTrue);
    });
    test('questionnaire sans impact → RIPH 3', () {
      expect(
        _cat(_prospective(actes: {'questionnaire_simple'})),
        ResearchCategory.riph3,
      );
    });
    test('aucun acte ajouté → RIPH 3', () {
      expect(_cat(_prospective()), ResearchCategory.riph3);
    });
    test('médicament prescrit en soins courants → loi Jardé', () {
      expect(
        _cat({
          ..._prospective(),
          Q.produit: 'medicament',
          Q.medAttribution: 'non',
        }),
        ResearchCategory.riph3,
      );
    });
  });

  group('médicament', () {
    Map<String, Object> med(String faible) => {
          Q.objectif: 'recherche',
          Q.personnes: 'oui',
          Q.produit: 'medicament',
          Q.medAttribution: 'oui',
          Q.medFaible: faible,
          Q.contexte: <String>{},
        };
    test('attribution par le protocole → essai CTR', () {
      expect(_cat(med('non')), ResearchCategory.essaiMedicament);
    });
    test('faible niveau d\'intervention', () {
      expect(
        _cat(med('oui')),
        ResearchCategory.essaiMedicamentFaibleIntervention,
      );
    });
  });

  group('dispositifs médicaux', () {
    Map<String, Object> dm(Map<String, Object> extra) => {
          Q.objectif: 'recherche',
          Q.personnes: 'oui',
          Q.produit: 'dm',
          Q.contexte: <String>{},
          ...extra,
        };
    test('non marqué CE, objectif de marquage → conformité', () {
      expect(
        _cat(dm({Q.dmCe: 'non', Q.dmObjectif: 'conformite'})),
        ResearchCategory.dmConformite,
      );
    });
    test('non marqué CE, autre objectif → cas 4', () {
      expect(
        _cat(dm({Q.dmCe: 'non', Q.dmObjectif: 'autre'})),
        ResearchCategory.dmCas4,
      );
    });
    test('marqué CE hors destination → cas 3', () {
      expect(
        _cat(dm({Q.dmCe: 'oui', Q.dmUsage: 'hors', Q.dmObjectif: 'autre'})),
        ResearchCategory.dmCas3,
      );
    });
    test('marqué CE, procédures légères → cas 1', () {
      expect(
        _cat(dm({Q.dmCe: 'oui', Q.dmUsage: 'conforme', Q.dmProcedures: 'legeres'})),
        ResearchCategory.dmCas1,
      );
    });
    test('marqué CE, procédures lourdes → cas 2', () {
      expect(
        _cat(dm({Q.dmCe: 'oui', Q.dmUsage: 'conforme', Q.dmProcedures: 'lourdes'})),
        ResearchCategory.dmCas2,
      );
    });
    test('marqué CE sans procédure → retour à la loi Jardé', () {
      expect(
        _cat(dm({
          Q.dmCe: 'oui',
          Q.dmUsage: 'conforme',
          Q.dmProcedures: 'aucune',
          Q.intervention: 'aucune',
          Q.actes: <String>{},
        })),
        ResearchCategory.riph3,
      );
    });
  });

  group('données existantes', () {
    Map<String, Object> data(Map<String, Object> extra) => {
          Q.objectif: 'recherche',
          Q.personnes: 'non',
          Q.contexteDonnees: <String>{},
          ...extra,
        };
    test('étude interne', () {
      expect(_cat(data({Q.source: 'interne'})), ResearchCategory.etudeInterne);
    });
    test('multisource conforme → MR-004', () {
      expect(
        _cat(data({Q.source: 'multi', Q.mr004: 'oui'})),
        ResearchCategory.donneesMr004,
      );
    });
    test('hors MR-004 → autorisation', () {
      expect(
        _cat(data({Q.source: 'eds', Q.mr004: 'non'})),
        ResearchCategory.donneesAutorisation,
      );
    });
    test('SNDS', () {
      expect(
        _cat(data({Q.source: 'snds', Q.sndsAcces: 'principale'})),
        ResearchCategory.donneesSnds,
      );
    });
  });

  group('parcours', () {
    List<String> ids(Map<String, Object> m) =>
        buildPathway(classify(_a(m))!).map((s) => s.id).toList();

    test('RIPH 1 : autorisation ANSM et assurance', () {
      final s = ids(_prospective(intervention: 'lourde'));
      expect(s, contains('ansm_autorisation'));
      expect(s, contains('assurance'));
      expect(s.contains('ansm_information'), isFalse);
    });
    test('RIPH 3 : pas d\'assurance, MR-003, information de l\'ANSM', () {
      final s = ids(_prospective());
      expect(s.contains('assurance'), isFalse);
      expect(s, contains('ansm_information'));
      final mr = buildPathway(classify(_a(_prospective()))!)
          .firstWhere((x) => x.id == 'cnil_mr');
      expect(mr.title.contains('MR-003'), isTrue);
    });
    test('RIPH 3 avec génétique : MR-001 et consentement écrit', () {
      final steps =
          buildPathway(classify(_a(_prospective(contexte: {'genetique'})))!);
      expect(
        steps.firstWhere((x) => x.id == 'cnil_mr').title.contains('MR-001'),
        isTrue,
      );
      expect(steps.map((x) => x.id), contains('genetique'));
    });
    test('essai CTR : CTIS, pas d\'IDRCB ni de SI RIPH', () {
      final s = ids({
        Q.objectif: 'recherche',
        Q.personnes: 'oui',
        Q.produit: 'medicament',
        Q.medAttribution: 'oui',
        Q.medFaible: 'non',
        Q.contexte: <String>{},
      });
      expect(s, contains('ctis_depot'));
      expect(s.contains('idrcb'), isFalse);
      expect(s.contains('cpp_depot'), isFalse);
    });
    test('les étapes sont triées par phase et sans doublon', () {
      for (final m in [
        _prospective(intervention: 'lourde', contexte: {
          'mineurs',
          'industriel',
          'international',
          'collection',
        }),
        {
          Q.objectif: 'recherche',
          Q.personnes: 'non',
          Q.source: 'multi',
          Q.mr004: 'oui',
          Q.contexteDonnees: {'industriel'},
        },
      ]) {
        final steps = buildPathway(classify(_a(m))!);
        final phases = steps.map((s) => s.phase.index).toList();
        expect(phases, equals([...phases]..sort()));
        final idList = steps.map((s) => s.id).toList();
        expect(idList.toSet().length, idList.length);
      }
    });
    test('toutes les catégories atteignables produisent un parcours', () {
      final reached = <ResearchCategory>{};
      for (final m in _allPaths()) {
        final c = classify(_a(m));
        if (c == null) continue;
        reached.add(c.category);
        expect(buildPathway(c).isNotEmpty, isTrue);
      }
      expect(reached, equals(ResearchCategory.values.toSet()));
    });
  });
}

/// Énumère toutes les combinaisons de réponses à choix unique (contextes
/// vides), pour vérifier que chaque catégorie est atteignable.
Iterable<Map<String, Object>> _allPaths() sync* {
  Iterable<Answers> walk(Answers a) sync* {
    final next = visibleQuestions(a).where((q) => !a.containsKey(q.id));
    if (next.isEmpty) {
      yield a;
      return;
    }
    final q = next.first;
    if (q.multiple) {
      yield* walk({...a, q.id: <String>{}});
      for (final c in q.choices) {
        yield* walk({...a, q.id: {c.id}});
      }
    } else {
      for (final c in q.choices) {
        yield* walk({...a, q.id: {c.id}});
      }
    }
  }

  for (final a in walk({})) {
    yield {for (final e in a.entries) e.key: e.value};
  }
}
