import 'package:cliniflow/data/project.dart';
import 'package:cliniflow/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 10, 1);
  Project riph1() => Project(
        id: 'p1',
        title: 'Étude pilote',
        acronym: 'PILOTE',
        createdAt: created,
        updatedAt: created,
        answers: {
          Q.objectif: {'recherche'},
          Q.personnes: {'oui'},
          Q.produit: {'aucun'},
          Q.intervention: {'lourde'},
          Q.contexte: <String>{},
        },
      );

  test('aller-retour JSON sans perte', () {
    final p = riph1().withTracking(
      'assurance',
      StepTracking(
        status: StepStatus.done,
        dueDate: DateTime(2026, 11, 3),
        completedAt: DateTime(2026, 10, 20),
        note: 'Contrat n° 42',
      ),
    );
    final back = Project.fromJson(p.toJson());
    expect(back.acronym, 'PILOTE');
    expect(back.classification?.category, ResearchCategory.riph1);
    final t = back.trackingFor('assurance');
    expect(t.status, StepStatus.done);
    expect(t.dueDate, DateTime(2026, 11, 3));
    expect(t.note, 'Contrat n° 42');
  });

  test('avancement et retards', () {
    final p = riph1()
        .withTracking('promoteur', const StepTracking(status: StepStatus.done))
        .withTracking(
          'cpp_depot',
          StepTracking(dueDate: DateTime(2026, 10, 10)),
        );
    expect(p.progress.done, 1);
    expect(p.progress.total, p.steps.length);
    expect(p.overdueCount(DateTime(2026, 10, 26)), 1);
    expect(p.overdueCount(DateTime(2026, 10, 5)), 0);
    expect(p.nextDeadline()?.step.id, 'cpp_depot');
  });

  test('statut « sans objet » compte comme soldé, jamais en retard', () {
    final t = StepTracking(
      status: StepStatus.notApplicable,
      dueDate: DateTime(2020),
    );
    expect(t.isOverdue(DateTime(2026)), isFalse);
  });

  test('format de date', () {
    expect(formatDate(DateTime(2026, 3, 7)), '07/03/2026');
  });
}
