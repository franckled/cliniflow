import 'models.dart';

typedef _S = RegulatoryStep;

// Sources officielles (pages d'accueil stables plutôt que des liens profonds).
const _legifranceJarde =
    'https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006072665/LEGISCTA000006154978/';
const _ansmMedicament =
    'https://ansm.sante.fr/vos-demarches/chercheur/demander-une-autorisation-pour-un-essai-clinique-pour-des-medicaments-categorie-1';
const _ansmDm =
    'https://ansm.sante.fr/uploads/2025/03/21/annexe1-classification-et-process-evaluation-des-investigations-cliniques-2.pdf';
const _cnilSante = 'https://www.cnil.fr/fr/sante';
const _hdh = 'https://www.health-data-hub.fr';
const _ctis = 'https://euclinicaltrials.eu';
const _clinicalTrials = 'https://clinicaltrials.gov';

/// Construit le parcours réglementaire ordonné d'un projet qualifié.
List<RegulatoryStep> buildPathway(Classification c) {
  final cat = c.category;
  final f = c.flags;
  final steps = <RegulatoryStep>[];
  void add(RegulatoryStep s) => steps.add(s);

  final jarde = {
    ResearchCategory.riph1,
    ResearchCategory.riph2,
    ResearchCategory.riph3,
  }.contains(cat);
  final ctr = cat == ResearchCategory.essaiMedicament ||
      cat == ResearchCategory.essaiMedicamentFaibleIntervention;
  final dm = cat.family == CategoryFamily.device;
  final human = cat.involvesHumanPerson;

  // ─── Hors recherche ──────────────────────────────────────────────────────
  if (cat == ResearchCategory.horsRecherche) {
    add(const _S(
      id: 'hr_registre',
      phase: Phase.conception,
      title: 'Inscrire le traitement au registre RGPD',
      detail: 'Même hors recherche, toute collecte de données personnelles '
          'est inscrite au registre des activités de traitement de '
          'l\'établissement.',
      actor: 'DPO',
      link: _cnilSante,
    ));
    add(const _S(
      id: 'hr_information',
      phase: Phase.demarrage,
      title: 'Informer les personnes concernées',
      detail: 'Finalité, responsable, durée de conservation, droits. Limitez '
          'les données au strict nécessaire.',
      actor: 'Porteur de projet',
    ));
    add(const _S(
      id: 'hr_ethique',
      phase: Phase.conception,
      title: 'Envisager un avis éthique si publication',
      detail: 'Un comité d\'éthique local ou un IRB peut rendre un avis non '
          'réglementaire, souvent demandé par les revues.',
      actor: 'Comité d\'éthique local',
    ));
    return steps;
  }

  // ─── Conception ──────────────────────────────────────────────────────────
  if (human) {
    add(const _S(
      id: 'promoteur',
      phase: Phase.conception,
      title: 'Identifier le promoteur et l\'investigateur coordonnateur',
      detail: 'Le promoteur prend l\'initiative de la recherche, en assure la '
          'gestion et vérifie son financement. Dans un établissement public, '
          'c\'est généralement la DRCI qui porte ce rôle.',
      actor: 'DRCI',
    ));
    add(_S(
      id: 'protocole',
      phase: Phase.conception,
      title: 'Rédiger le protocole et son résumé',
      detail: ctr
          ? 'Utilisez une trame conforme à l\'annexe I du règlement '
              '536/2014 : protocole, brochure investigateur, dossier du '
              'médicament expérimental (IMPD).'
          : 'Justifiez la catégorie retenue dans le protocole : intervention, '
              'actes ajoutés, risques et contraintes.',
      actor: 'Investigateur coordonnateur',
    ));
    add(_S(
      id: 'information',
      phase: Phase.conception,
      title: cat == ResearchCategory.riph3
          ? 'Rédiger la note d\'information (non-opposition)'
          : 'Rédiger la note d\'information et le formulaire de consentement',
      detail: switch (cat) {
        ResearchCategory.riph1 =>
          'Consentement libre, éclairé et recueilli par écrit.',
        ResearchCategory.riph2 =>
          'Consentement libre, éclairé et exprès.',
        ResearchCategory.riph3 =>
          'Information individuelle et recueil de la non-opposition. Un '
              'consentement écrit reste requis pour les examens génétiques.',
        _ when ctr =>
          'Consentement éclairé écrit, daté et signé (art. 29 du règlement).',
        _ => 'Consentement éclairé écrit des participants.',
      },
      actor: 'Investigateur coordonnateur',
    ));
    if (!ctr) {
      add(const _S(
        id: 'idrcb',
        phase: Phase.conception,
        title: 'Obtenir le numéro d\'enregistrement IDRCB',
        detail: 'Numéro national d\'identification de la recherche, demandé '
            'auprès de l\'ANSM avant tout dépôt.',
        actor: 'Promoteur',
        link: 'https://ansm.sante.fr',
      ));
    }
    add(_S(
      id: 'cnil_mr',
      phase: Phase.conception,
      title: (cat == ResearchCategory.riph3 && !f.contains('genetique'))
          ? 'Vérifier la conformité à la MR-003'
          : 'Vérifier la conformité à la MR-001',
      detail: (cat == ResearchCategory.riph3 && !f.contains('genetique'))
          ? 'MR-003 : recherches sans recueil du consentement. Le promoteur '
              'doit avoir déposé une déclaration de conformité ; à défaut, '
              'autorisation CNIL.'
          : 'MR-001 : recherches avec recueil du consentement (obligatoire '
              'en cas d\'examen génétique). Le promoteur doit avoir déposé '
              'une déclaration de conformité ; à défaut, autorisation CNIL.',
      actor: 'DPO du promoteur',
      link: _cnilSante,
    ));
    add(const _S(
      id: 'aipd',
      phase: Phase.conception,
      title: 'Réaliser l\'analyse d\'impact (AIPD)',
      detail: 'Traitement de données de santé à grande échelle ou de '
          'personnes vulnérables : l\'AIPD est en pratique attendue.',
      actor: 'DPO',
    ));
    final insuranceOptional = cat == ResearchCategory.riph3 ||
        cat == ResearchCategory.dmCas1;
    if (!insuranceOptional) {
      add(const _S(
        id: 'assurance',
        phase: Phase.conception,
        title: 'Souscrire l\'assurance responsabilité civile du promoteur',
        detail: 'L\'attestation couvre la durée de la recherche et le nombre '
            'de participants prévus ; elle est jointe au dossier.',
        actor: 'Promoteur',
      ));
    }
    if (cat == ResearchCategory.riph1 ||
        cat == ResearchCategory.riph2 ||
        ctr ||
        dm) {
      add(const _S(
        id: 'registre_public',
        phase: Phase.conception,
        title: 'Enregistrer l\'étude sur un registre public',
        detail: 'Exigé par les revues (ICMJE) pour les études '
            'interventionnelles, avant la première inclusion. Les essais '
            'de médicaments sont publiés automatiquement via CTIS.',
        actor: 'Promoteur',
        link: _clinicalTrials,
      ));
    }
  }

  // ─── Données existantes ─────────────────────────────────────────────────
  switch (cat) {
    case ResearchCategory.etudeInterne:
      add(const _S(
        id: 'int_critere',
        phase: Phase.conception,
        title: 'Vérifier les critères de l\'étude interne',
        detail: 'Données de vos propres patients, traitées par l\'équipe de '
            'soins, pour son usage exclusif, sans transmission externe.',
        actor: 'DPO',
        link: _cnilSante,
      ));
      add(const _S(
        id: 'int_registre',
        phase: Phase.soumission,
        title: 'Inscrire l\'étude au registre des traitements',
        detail: 'Le DPO de l\'établissement inscrit l\'étude ; une AIPD peut '
            'être nécessaire.',
        actor: 'DPO',
      ));
      add(const _S(
        id: 'int_information',
        phase: Phase.demarrage,
        title: 'Informer les patients et respecter leur opposition',
        detail: 'Information générale (affichage, livret, site internet) '
            'mentionnant la réutilisation des données et le droit '
            'd\'opposition.',
        actor: 'Établissement',
      ));
    case ResearchCategory.donneesMr004:
      add(const _S(
        id: 'mr004_conformite',
        phase: Phase.conception,
        title: 'Vérifier la déclaration de conformité MR-004',
        detail: 'Le responsable de traitement dépose une déclaration de '
            'conformité unique auprès de la CNIL, puis documente chaque étude '
            'dans son registre.',
        actor: 'DPO',
        link: _cnilSante,
      ));
      add(const _S(
        id: 'mr004_repertoire',
        phase: Phase.soumission,
        title: 'Enregistrer l\'étude au répertoire public',
        detail: 'Avant la mise en œuvre, l\'étude est inscrite au répertoire '
            'public de la Plateforme des données de santé (Health Data Hub).',
        actor: 'Responsable de traitement',
        link: _hdh,
      ));
      add(const _S(
        id: 'mr004_information',
        phase: Phase.demarrage,
        title: 'Informer individuellement les personnes',
        detail: 'Information individuelle avec droit d\'opposition, ou '
            'renvoi vers un dispositif d\'information consulté avant chaque '
            'nouveau traitement.',
        actor: 'Responsable de traitement',
      ));
      add(const _S(
        id: 'mr004_resultats',
        phase: Phase.cloture,
        title: 'Publier les résultats dans le répertoire public',
        detail: 'Mettez à jour la fiche de l\'étude avec ses résultats.',
        actor: 'Responsable de traitement',
        link: _hdh,
      ));
    case ResearchCategory.donneesSnds:
      add(const _S(
        id: 'snds_mr',
        phase: Phase.conception,
        title: 'Vérifier l\'éligibilité à la MR du SNDS',
        detail: 'MR-005 (PMSI, établissements), MR-006 (PMSI, industriels), '
            'MR-007 ou MR-008 (base principale). Chacune impose une '
            'déclaration de conformité et des conditions d\'accès.',
        actor: 'DPO',
        link: _cnilSante,
      ));
      add(const _S(
        id: 'snds_hdh',
        phase: Phase.soumission,
        title: 'Déposer la demande d\'accès',
        detail: 'Enregistrement au répertoire public et demande d\'accès aux '
            'données via la Plateforme des données de santé.',
        actor: 'Responsable de traitement',
        link: _hdh,
      ));
      add(const _S(
        id: 'snds_securite',
        phase: Phase.demarrage,
        title: 'Respecter le référentiel de sécurité du SNDS',
        detail: 'Accès depuis un environnement habilité, traçabilité, '
            'personnes formées et nommément désignées.',
        actor: 'Responsable de traitement',
      ));
    case ResearchCategory.donneesAutorisation:
      add(const _S(
        id: 'aut_dossier',
        phase: Phase.conception,
        title: 'Préparer le dossier de demande d\'autorisation',
        detail: 'Protocole, justification de l\'intérêt public, description '
            'des données, mesures de sécurité, AIPD.',
        actor: 'Responsable de traitement',
      ));
      add(const _S(
        id: 'aut_cesrees',
        phase: Phase.soumission,
        title: 'Obtenir l\'avis du CESREES',
        detail: 'Dépôt via la Plateforme des données de santé, qui saisit le '
            'Comité éthique et scientifique (CESREES).',
        actor: 'CESREES',
        link: _hdh,
      ));
      add(const _S(
        id: 'aut_cnil',
        phase: Phase.soumission,
        title: 'Obtenir l\'autorisation de la CNIL',
        detail: 'La CNIL se prononce après l\'avis du CESREES. Aucun '
            'traitement avant autorisation.',
        actor: 'CNIL',
        link: _cnilSante,
      ));
      add(const _S(
        id: 'aut_information',
        phase: Phase.demarrage,
        title: 'Informer les personnes concernées',
        detail: 'Information individuelle et droit d\'opposition, sauf '
            'dérogation accordée.',
        actor: 'Responsable de traitement',
      ));
    default:
      break;
  }

  // ─── Soumissions ────────────────────────────────────────────────────────
  if (jarde) {
    add(const _S(
      id: 'cpp_depot',
      phase: Phase.soumission,
      title: 'Déposer le dossier sur le SI RIPH',
      detail: 'Le dossier est attribué à un CPP par tirage au sort. Une '
          'nouvelle soumission après avis défavorable donne lieu à un '
          'nouveau tirage.',
      actor: 'Promoteur',
      link: _legifranceJarde,
    ));
    add(const _S(
      id: 'cpp_avis',
      phase: Phase.soumission,
      title: 'Obtenir l\'avis favorable du CPP',
      detail: 'Le CPP peut demander des compléments, ce qui suspend le délai. '
          'En cas d\'avis défavorable : un mois pour demander un second '
          'examen.',
      actor: 'CPP',
      delay: '45 jours',
    ));
    if (cat == ResearchCategory.riph1) {
      add(const _S(
        id: 'ansm_autorisation',
        phase: Phase.soumission,
        title: 'Obtenir l\'autorisation de l\'ANSM',
        detail: 'Demande d\'autorisation en parallèle du dépôt au CPP. La '
            'recherche ne peut débuter qu\'avec les deux décisions '
            'favorables.',
        actor: 'ANSM',
        link: 'https://ansm.sante.fr',
      ));
    } else {
      add(const _S(
        id: 'ansm_information',
        phase: Phase.soumission,
        title: 'Transmettre l\'avis du CPP et le résumé à l\'ANSM',
        detail: 'Pas d\'autorisation : simple information de l\'ANSM après '
            'l\'avis favorable.',
        actor: 'ANSM',
      ));
    }
  }

  if (ctr) {
    add(const _S(
      id: 'ctis_compte',
      phase: Phase.soumission,
      title: 'Préparer les parties I et II dans CTIS',
      detail: 'Partie I : protocole, brochure investigateur, IMPD. '
          'Partie II : documents nationaux (information, consentement, '
          'assurance, aptitude des sites, recrutement).',
      actor: 'Promoteur',
      link: _ctis,
    ));
    add(const _S(
      id: 'ctis_depot',
      phase: Phase.soumission,
      title: 'Soumettre la demande sur CTIS',
      detail: 'Validation par l\'État membre (10 jours, puis 10 jours pour '
          'répondre si le dossier est incomplet). Le CPP est tiré au sort '
          'et évalue la partie II.',
      actor: 'Promoteur',
      delay: 'Validation : 10 à 25 jours',
      link: _ansmMedicament,
    ));
    add(const _S(
      id: 'ctis_decision',
      phase: Phase.soumission,
      title: 'Obtenir la décision unique',
      detail: 'L\'ANSM évalue la partie I, le CPP la partie II ; l\'ANSM '
          'notifie une décision unique via CTIS.',
      actor: 'ANSM + CPP',
      delay: 'Partie II : 45 jours après validation',
    ));
    if (cat == ResearchCategory.essaiMedicamentFaibleIntervention) {
      add(const _S(
        id: 'ctr_faible',
        phase: Phase.soumission,
        title: 'Argumenter le faible niveau d\'intervention',
        detail: 'Le statut permet un monitoring et une documentation allégés. '
            'Il doit être justifié dans la lettre d\'accompagnement.',
        actor: 'Promoteur',
      ));
    }
  }

  if (dm) {
    final ansm = cat == ResearchCategory.dmConformite ||
        cat == ResearchCategory.dmCas2 ||
        cat == ResearchCategory.dmCas4 ||
        cat == ResearchCategory.diagnosticInVitro;
    add(_S(
      id: 'dm_depot',
      phase: Phase.soumission,
      title: ansm
          ? 'Déposer le dossier au CPP et à l\'ANSM'
          : 'Déposer le dossier au CPP',
      detail: ansm
          ? 'Dépôt le même jour au CPP via le SI RIPH et à l\'ANSM par '
              'courriel, en indiquant le CPP désigné. Classez votre cas selon '
              'le tableau DGS-ANSM.'
          : 'Dépôt au CPP via le SI RIPH. Classez votre cas selon le tableau '
              'DGS-ANSM pour confirmer qu\'aucune autorisation ANSM n\'est '
              'requise.',
      actor: 'Promoteur',
      link: _ansmDm,
    ));
    add(const _S(
      id: 'dm_cpp',
      phase: Phase.soumission,
      title: 'Obtenir l\'avis favorable du CPP',
      detail: 'Validation du dossier sous 10 jours environ, puis évaluation '
          'éthique. Pour les investigations DM, le silence vaut refus.',
      actor: 'CPP',
      delay: 'Environ 45 jours',
    ));
    if (ansm) {
      add(const _S(
        id: 'dm_ansm',
        phase: Phase.soumission,
        title: 'Obtenir l\'autorisation de l\'ANSM',
        detail: 'Évaluation scientifique en parallèle du CPP. Pour '
            'certaines investigations, une procédure de notification '
            's\'applique : vérifiez votre cas.',
        actor: 'ANSM',
        delay: 'Environ 45 jours',
      ));
    }
  }

  // ─── Particularités ─────────────────────────────────────────────────────
  if (human) {
    if (f.contains('mineurs')) {
      add(const _S(
        id: 'mineurs',
        phase: Phase.conception,
        title: 'Prévoir le consentement des titulaires de l\'autorité parentale',
        detail: 'Les deux titulaires de l\'autorité parentale, et l\'adhésion '
            'du mineur avec une information adaptée à son âge.',
        actor: 'Investigateur',
      ));
    }
    if (f.contains('proteges')) {
      add(const _S(
        id: 'proteges',
        phase: Phase.conception,
        title: 'Adapter le consentement des majeurs protégés',
        detail: 'Selon le régime de protection : représentant légal, '
            'personne chargée de la mesure, personne de confiance ou proche.',
        actor: 'Investigateur',
      ));
    }
    if (f.contains('grossesse')) {
      add(const _S(
        id: 'grossesse',
        phase: Phase.conception,
        title: 'Justifier l\'inclusion de femmes enceintes ou allaitantes',
        detail: 'Bénéfice attendu pour elles ou l\'enfant, ou risque '
            'minime ; justification explicite dans le protocole.',
        actor: 'Investigateur coordonnateur',
      ));
    }
    if (f.contains('urgence')) {
      add(const _S(
        id: 'urgence',
        phase: Phase.conception,
        title: 'Décrire la procédure de consentement différé',
        detail: 'Consentement des proches si présents, puis de la personne '
            'dès qu\'elle est en état ; procédure soumise au CPP.',
        actor: 'Investigateur coordonnateur',
      ));
    }
    if (f.contains('genetique')) {
      add(const _S(
        id: 'genetique',
        phase: Phase.conception,
        title: 'Recueillir un consentement écrit spécifique pour la génétique',
        detail: 'L\'examen des caractéristiques génétiques exige un '
            'consentement écrit dédié, même en RIPH 3.',
        actor: 'Investigateur',
      ));
    }
    if (f.contains('volontaires_sains')) {
      add(const _S(
        id: 'vrb',
        phase: Phase.demarrage,
        title: 'Inscrire les volontaires sains au fichier national',
        detail: 'Vérification de la période d\'exclusion et du plafond annuel '
            'd\'indemnisation avant inclusion.',
        actor: 'Promoteur',
      ));
    }
    if (f.contains('industriel')) {
      add(const _S(
        id: 'convention_unique',
        phase: Phase.demarrage,
        title: 'Signer la convention unique avec chaque établissement',
        detail: 'Obligatoire pour une recherche à promotion industrielle dans '
            'un établissement public ou une maison de santé.',
        actor: 'Promoteur + établissements',
      ));
    }
    if (f.contains('multicentrique')) {
      add(const _S(
        id: 'conventions_centres',
        phase: Phase.demarrage,
        title: 'Conclure les conventions avec les centres associés',
        detail: 'Rôle de chaque investigateur principal, surcoûts, circuit '
            'des données et des échantillons.',
        actor: 'DRCI',
      ));
    }
    if (f.contains('international')) {
      add(_S(
        id: 'international',
        phase: Phase.soumission,
        title: 'Engager les démarches dans les autres pays',
        detail: ctr
            ? 'Via CTIS, en ajoutant les États membres concernés. Hors UE : '
                'autorités nationales et transferts de données encadrés.'
            : 'Autorités et comités d\'éthique de chaque pays ; encadrement '
                'des transferts de données hors UE.',
        actor: 'Promoteur',
      ));
    }
    if (f.contains('collection')) {
      add(const _S(
        id: 'collection',
        phase: Phase.cloture,
        title: 'Déclarer la collection d\'échantillons biologiques',
        detail: 'La conservation au-delà de la recherche relève d\'une '
            'déclaration au ministère chargé de la recherche, et d\'une '
            'information des participants sur cette réutilisation.',
        actor: 'Promoteur',
      ));
    }
  } else if (f.contains('industriel')) {
    add(const _S(
      id: 'donnees_industriel',
      phase: Phase.conception,
      title: 'Justifier l\'accès d\'un industriel aux données',
      detail: 'Certaines bases imposent un tiers de confiance ou un '
          'laboratoire de recherche ; vérifiez la MR applicable.',
      actor: 'DPO',
    ));
  }

  // ─── Démarrage, conduite, clôture (recherches impliquant la personne) ──
  if (human) {
    add(_S(
      id: 'debut',
      phase: Phase.demarrage,
      title: 'Déclarer le début de la recherche',
      detail: ctr
          ? 'Dates de début de l\'essai et de première inclusion à notifier '
              'dans CTIS sous 15 jours.'
          : 'Informer le CPP (et l\'ANSM si concernée) de la date de début '
              'effective.',
      actor: 'Promoteur',
      delay: ctr ? '15 jours' : null,
    ));
    add(_S(
      id: 'vigilance',
      phase: Phase.conduite,
      title: 'Organiser la vigilance',
      detail: switch (cat) {
        _ when ctr => 'Déclaration des SUSAR dans EudraVigilance et rapport '
            'annuel de sécurité (DSUR).',
        ResearchCategory.riph1 => 'Déclaration à l\'ANSM des effets '
            'indésirables graves inattendus et des faits nouveaux, rapport '
            'annuel de sécurité.',
        _ when dm => 'Notification des événements indésirables graves selon '
            'le règlement DM ; procédures précisées par l\'ANSM.',
        _ => 'Déclaration des faits nouveaux et des événements indésirables '
            'graves prévus par le protocole.',
      },
      actor: 'Promoteur',
    ));
    add(_S(
      id: 'modifications',
      phase: Phase.conduite,
      title: 'Soumettre les modifications substantielles',
      detail: ctr
          ? 'Via CTIS, avant leur mise en œuvre.'
          : 'Au CPP via le SI RIPH (et à l\'ANSM si elle a autorisé la '
              'recherche), avant leur mise en œuvre.',
      actor: 'Promoteur',
    ));
    if (jarde) {
      add(const _S(
        id: 'prorogation',
        phase: Phase.conduite,
        title: 'Surveiller la validité de l\'avis du CPP',
        detail: 'Sans inclusion dans les deux ans suivant l\'avis, demandez '
            'une prorogation sous forme de modification substantielle.',
        actor: 'Promoteur',
        delay: '2 ans',
      ));
    }
    add(_S(
      id: 'fin',
      phase: Phase.cloture,
      title: 'Déclarer la fin de la recherche',
      detail: ctr
          ? 'Fin de l\'essai notifiée dans CTIS sous 15 jours ; arrêt '
              'temporaire ou anticipé également sous 15 jours.'
          : 'Au CPP et, le cas échéant, à l\'ANSM : dans les 90 jours, ou '
              '15 jours en cas d\'arrêt anticipé.',
      actor: 'Promoteur',
      delay: ctr ? '15 jours' : '90 jours',
    ));
    add(_S(
      id: 'resultats',
      phase: Phase.cloture,
      title: 'Transmettre le résumé des résultats',
      detail: ctr
          ? 'Résumé des résultats publié dans CTIS, avec un résumé '
              'compréhensible par des non-spécialistes.'
          : 'Résumé des résultats transmis au CPP via le SI RIPH ; '
              'information des participants qui le demandent.',
      actor: 'Promoteur',
      delay: '1 an après la fin',
    ));
    add(_S(
      id: 'archivage',
      phase: Phase.cloture,
      title: 'Archiver les documents essentiels',
      detail: ctr
          ? 'Dossier permanent de l\'essai conservé 25 ans (art. 58 du '
              'règlement).'
          : 'Durée fixée selon la catégorie de recherche et le protocole ; '
              'vérifiez la durée applicable avec la DRCI.',
      actor: 'Promoteur + investigateurs',
    ));
  }

  // Ordre chronologique stable : par phase, puis ordre d'insertion.
  final indexed = steps.indexed.toList()
    ..sort((x, y) {
      final p = x.$2.phase.index.compareTo(y.$2.phase.index);
      return p != 0 ? p : x.$1.compareTo(y.$1);
    });
  return [for (final e in indexed) e.$2];
}
