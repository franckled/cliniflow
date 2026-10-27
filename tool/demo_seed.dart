// Génère des projets de démonstration (JSON) pour les captures d'écran.
// Usage : dart run tool/demo_seed.dart > seed.json
import 'dart:convert';
import 'dart:io';

import 'package:cliniflow/data/project.dart';
import 'package:cliniflow/engine/engine.dart';

void main() {
  final now = DateTime.now();
  DateTime d(int days) => DateTime(now.year, now.month, now.day + days);

  var campanile = Project(
    id: 'demo-campanile',
    title: 'Phlébites non infectieuses sur cathéter périphérique',
    acronym: 'CAMPANILE',
    sponsor: 'CH de Bastia',
    createdAt: d(-40),
    updatedAt: d(0),
    answers: {
      Q.objectif: {'recherche'},
      Q.personnes: {'oui'},
      Q.produit: {'aucun'},
      Q.intervention: {'aucune'},
      Q.actes: {'questionnaire_simple'},
      Q.contexte: {'multicentrique'},
    },
  );
  final steps = campanile.steps;
  for (final s in steps.take(5)) {
    campanile = campanile.withTracking(
        s.id, StepTracking(status: StepStatus.done, completedAt: d(-10)));
  }
  campanile = campanile
      .withTracking(steps[5].id,
          StepTracking(status: StepStatus.inProgress, dueDate: d(-2)))
      .withTracking(steps[6].id, StepTracking(dueDate: d(12)));

  var maquis = Project(
    id: 'demo-maquis',
    title: 'Cytométrie en flux et syndrome inflammatoire',
    acronym: 'MAQUIS',
    sponsor: 'DRCI',
    createdAt: d(-20),
    updatedAt: d(-1),
    answers: {
      Q.objectif: {'recherche'},
      Q.personnes: {'oui'},
      Q.produit: {'aucun'},
      Q.intervention: {'minime'},
      Q.actes: {'sang'},
      Q.contexte: {'collection'},
    },
  );
  for (final s in maquis.steps.take(2)) {
    maquis = maquis.withTracking(
        s.id, const StepTracking(status: StepStatus.done));
  }

  final draft = Project(
    id: 'demo-draft',
    title: 'Registre régional des cancers héréditaires',
    acronym: 'ONCOREG',
    createdAt: d(-1),
    updatedAt: d(-3),
    answers: {Q.objectif: {'recherche'}},
  );

  stdout.write(jsonEncode([campanile.toJson(), maquis.toJson(), draft.toJson()]));
}
