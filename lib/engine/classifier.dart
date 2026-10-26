import 'models.dart';
import 'questions.dart';

/// Actes qui, à eux seuls, font sortir de la RIPH 3.
const _actesRiph2 = {
  'randomisation',
  'sang',
  'non_invasif',
  'imagerie',
  'questionnaire_impact',
};

/// Qualifie un projet à partir des réponses. Retourne `null` tant que le
/// questionnaire n'est pas complet.
Classification? classify(Answers raw) {
  final a = pruneAnswers(raw);
  if (!isComplete(a)) return null;

  final reasons = <String>[];
  final toConfirm = <String>[];
  final flags = <String>{
    ...?a[Q.contexte],
    ...?a[Q.contexteDonnees],
  };

  Classification done(ResearchCategory c) => Classification(
        category: c,
        reasons: List.unmodifiable(reasons),
        toConfirm: List.unmodifiable(toConfirm),
        flags: Set.unmodifiable(flags),
      );

  // 1. Est-ce une recherche ?
  switch (a.single(Q.objectif)) {
    case 'pratiques':
      reasons.add('L\'objectif est d\'évaluer des pratiques ou la qualité des '
          'soins, pas de produire des connaissances généralisables.');
      toConfirm.add('Si des résultats doivent être publiés comme une '
          'recherche, faites confirmer la qualification par la DRCI : une '
          'revue peut exiger un avis éthique.');
      return done(ResearchCategory.horsRecherche);
    case 'professionnels':
      reasons.add('Seuls des professionnels sont interrogés, sans donnée de '
          'santé de patients.');
      toConfirm.add('Le RGPD reste applicable aux réponses des '
          'professionnels : information, registre, minimisation.');
      return done(ResearchCategory.horsRecherche);
  }
  reasons.add('Le projet vise à développer les connaissances biologiques ou '
      'médicales.');

  // 2. Recherche sur données existantes.
  if (a.single(Q.personnes) == 'non') {
    reasons.add('Aucune personne n\'est incluse ni suivie : il s\'agit d\'une '
        'recherche n\'impliquant pas la personne humaine.');
    if (flags.contains('appariement') || flags.contains('hors_ue')) {
      toConfirm.add('Appariement de bases ou transfert hors UE : vérifiez avec '
          'le DPO que la méthodologie de référence les autorise, sinon une '
          'autorisation CNIL est nécessaire.');
    }
    switch (a.single(Q.source)) {
      case 'interne':
        reasons.add('Les données sont celles de vos patients, exploitées par '
            'l\'équipe qui les soigne, pour un usage interne.');
        toConfirm.add('Le statut d\'étude interne suppose qu\'aucune donnée '
            'ne sorte de l\'équipe de soins. Un partenaire externe ou un '
            'promoteur tiers fait basculer vers la MR-004.');
        return done(ResearchCategory.etudeInterne);
      case 'snds':
        reasons.add(switch (a.single(Q.sndsAcces)) {
          'pmsi_es' => 'Accès au PMSI par un établissement : cadre MR-005.',
          'pmsi_industriel' =>
            'Accès au PMSI par un industriel de santé : cadre MR-006.',
          _ => 'Accès à la base principale du SNDS : cadres MR-007 ou '
              'MR-008 selon l\'organisme.',
        });
        toConfirm.add('Hors du cadre de la MR applicable, le dossier passe '
            'par la Plateforme des données de santé, le CESREES et une '
            'autorisation CNIL.');
        return done(ResearchCategory.donneesSnds);
      default:
        if (a.single(Q.source) == 'eds') {
          reasons.add('Les données proviennent d\'un entrepôt de données de '
              'santé.');
          toConfirm.add('Vérifiez que l\'entrepôt est lui-même déclaré '
              'conforme au référentiel CNIL des entrepôts ou autorisé.');
        } else {
          reasons.add('Les données proviennent de plusieurs sources ou '
              'partenaires.');
        }
        final mr = a.single(Q.mr004);
        if (mr == 'non') {
          reasons.add('Le traitement s\'écarte de la MR-004.');
          return done(ResearchCategory.donneesAutorisation);
        }
        if (mr == 'nsp') {
          toConfirm.add('La conformité à la MR-004 reste à établir avec le '
              'DPO. À défaut : CESREES et autorisation CNIL.');
        } else {
          reasons.add('Le traitement respecte le cadre de la MR-004.');
        }
        return done(ResearchCategory.donneesMr004);
    }
  }

  reasons.add('Des personnes sont incluses et suivies pour la recherche : '
      'elle implique la personne humaine.');

  // 3. Produits de santé soumis à un règlement européen.
  switch (a.single(Q.produit)) {
    case 'medicament' when a.single(Q.medAttribution) == 'oui':
      reasons.add('Le protocole attribue le médicament : c\'est un essai '
          'clinique au sens du règlement (UE) 536/2014.');
      if (a.single(Q.medFaible) == 'oui') {
        reasons.add('Médicament autorisé, utilisé selon l\'AMM ou un usage '
            'étayé, avec des procédures à risque minime.');
        toConfirm.add('Le statut « faible niveau d\'intervention » est '
            'apprécié lors de l\'évaluation : argumentez-le dans la lettre '
            'd\'accompagnement.');
        return done(ResearchCategory.essaiMedicamentFaibleIntervention);
      }
      return done(ResearchCategory.essaiMedicament);
    case 'medicament':
      reasons.add('Le médicament est prescrit en soins courants, '
          'indépendamment de la recherche : ce n\'est pas un essai clinique.');
    case 'dm':
      final ce = a.single(Q.dmCe) == 'oui';
      final usage = a.single(Q.dmUsage);
      if (!ce || usage == 'hors') {
        if (a.single(Q.dmObjectif) == 'conformite') {
          reasons.add('L\'investigation vise à démontrer la conformité du '
              'dispositif en vue du marquage CE.');
          return done(ResearchCategory.dmConformite);
        }
        if (!ce) {
          reasons.add('Dispositif non marqué CE, sans objectif de marquage.');
          return done(ResearchCategory.dmCas4);
        }
        reasons.add('Dispositif marqué CE utilisé hors de sa destination, '
            'sans objectif de marquage.');
        return done(ResearchCategory.dmCas3);
      }
      switch (a.single(Q.dmProcedures)) {
        case 'legeres':
          reasons.add('Dispositif marqué CE utilisé dans sa destination, avec '
              'des procédures supplémentaires non invasives et non lourdes.');
          toConfirm.add('Rapprochez votre cas du tableau de classification '
              'DGS-ANSM des investigations DM.');
          return done(ResearchCategory.dmCas1);
        case 'lourdes':
          reasons.add('Dispositif marqué CE utilisé dans sa destination, avec '
              'des procédures supplémentaires invasives ou lourdes.');
          toConfirm.add('Rapprochez votre cas du tableau de classification '
              'DGS-ANSM des investigations DM.');
          return done(ResearchCategory.dmCas2);
      }
      reasons.add('Le dispositif marqué CE est utilisé dans sa destination '
          'sans procédure supplémentaire : ce n\'est pas une investigation '
          'clinique du règlement DM.');
    case 'div':
      reasons.add('L\'étude évalue les performances d\'un dispositif de '
          'diagnostic in vitro.');
      if (a.single(Q.divPrelevement) == 'non') {
        toConfirm.add('Une étude sur échantillons résiduels sans procédure '
            'supplémentaire peut relever d\'un circuit allégé : faites '
            'confirmer par l\'ANSM ou la DRCI.');
      } else {
        toConfirm.add('Prélèvements spécifiques : l\'étude de performance '
            'interventionnelle requiert l\'avis du CPP et l\'autorisation de '
            'l\'ANSM.');
      }
      return done(ResearchCategory.diagnosticInVitro);
  }

  // 4. Loi Jardé : RIPH 1, 2 ou 3.
  final intervention = a.single(Q.intervention);
  final actes = a[Q.actes] ?? const <String>{};
  if (intervention == 'lourde') {
    reasons.add('Le protocole impose une intervention non justifiée par la '
        'prise en charge habituelle.');
    return done(ResearchCategory.riph1);
  }

  final ajoutes = actes.intersection(_actesRiph2);
  if (ajoutes.isNotEmpty || intervention == 'minime') {
    if (actes.contains('randomisation')) {
      reasons.add('La randomisation entre stratégies exclut la RIPH 3, même '
          'si chaque stratégie relève des soins courants.');
    }
    if (ajoutes.difference({'randomisation'}).isNotEmpty) {
      reasons.add('Des actes à risques et contraintes minimes sont ajoutés '
          'pour la recherche.');
    }
    if (intervention == 'aucune') {
      toConfirm.add('Vous indiquez une prise en charge habituelle, mais des '
          'actes sont ajoutés : la recherche est au minimum une RIPH 2.');
    }
    if (ajoutes.isEmpty) {
      toConfirm.add('Précisez quels actes à risque minime sont ajoutés : sans '
          'acte ajouté, la recherche pourrait relever de la RIPH 3.');
    }
    toConfirm.add('Chaque acte ajouté doit figurer sur la liste de l\'arrêté '
        'fixant les interventions à risques et contraintes minimes. Un acte '
        'hors liste fait basculer en RIPH 1.');
    return done(ResearchCategory.riph2);
  }

  reasons.add('Les actes et produits sont utilisés de manière habituelle, '
      'sans procédure supplémentaire ou inhabituelle.');
  if (actes.contains('questionnaire_simple')) {
    reasons.add('Les questionnaires ajoutés n\'ont pas d\'impact sur la '
        'personne.');
  }
  return done(ResearchCategory.riph3);
}
