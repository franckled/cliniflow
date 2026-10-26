import 'models.dart';

/// Identifiants des questions (utilisés par le classifieur et les tests).
abstract final class Q {
  static const objectif = 'objectif';
  static const personnes = 'personnes';
  static const source = 'source';
  static const sndsAcces = 'snds_acces';
  static const mr004 = 'mr004';
  static const produit = 'produit';
  static const medAttribution = 'med_attribution';
  static const medFaible = 'med_faible';
  static const dmCe = 'dm_ce';
  static const dmObjectif = 'dm_objectif';
  static const dmUsage = 'dm_usage';
  static const dmProcedures = 'dm_procedures';
  static const divPrelevement = 'div_prelevement';
  static const intervention = 'intervention';
  static const actes = 'actes';
  static const contexte = 'contexte';
  static const contexteDonnees = 'contexte_donnees';
}

bool _prospective(Answers a) =>
    a.single(Q.objectif) == 'recherche' && a.single(Q.personnes) == 'oui';

bool _dataOnly(Answers a) =>
    a.single(Q.objectif) == 'recherche' && a.single(Q.personnes) == 'non';

/// Vrai quand l'étude prospective doit être départagée entre RIPH 1, 2 et 3
/// (stratégie ou procédure, médicament observé sans attribution, DM marqué CE
/// sans procédure supplémentaire).
bool needsInterventionQuestions(Answers a) {
  if (!_prospective(a)) return false;
  return switch (a.single(Q.produit)) {
    'aucun' => true,
    'medicament' => a.single(Q.medAttribution) == 'non',
    'dm' => a.single(Q.dmCe) == 'oui' &&
        a.single(Q.dmUsage) == 'conforme' &&
        a.single(Q.dmProcedures) == 'aucune',
    _ => false,
  };
}

/// Le questionnaire complet. L'ordre de la liste est l'ordre de présentation ;
/// chaque question n'apparaît que si son prédicat `isVisible` est vrai.
final List<Question> questionnaire = [
  Question(
    id: Q.objectif,
    title: 'Quel est l\'objectif principal du projet ?',
    help: 'La loi Jardé et les méthodologies CNIL ne s\'appliquent qu\'aux '
        'recherches visant à développer les connaissances biologiques ou '
        'médicales.',
    choices: const [
      Choice('recherche', 'Produire des connaissances biologiques ou médicales',
          hint: 'Hypothèse, critère de jugement, résultats généralisables'),
      Choice('pratiques', 'Évaluer nos pratiques ou la qualité des soins',
          hint: 'Audit, EPP, indicateurs, retour d\'expérience'),
      Choice('professionnels',
          'Interroger uniquement des professionnels sur leurs pratiques',
          hint: 'Enquête d\'opinion, sans donnée de santé de patients'),
    ],
    isVisible: (_) => true,
  ),
  Question(
    id: Q.personnes,
    title: 'Des personnes sont-elles incluses et suivies pour la recherche ?',
    help: 'Répondez « oui » dès que des participants sont sollicités, examinés, '
        'interrogés ou suivis spécifiquement pour l\'étude, même sans acte '
        'supplémentaire.',
    choices: const [
      Choice('oui', 'Oui, inclusion prospective de participants'),
      Choice('non', 'Non, uniquement des données déjà existantes',
          hint: 'Dossiers médicaux, registres, entrepôt, bases médico-administratives'),
    ],
    isVisible: (a) => a.single(Q.objectif) == 'recherche',
  ),

  // ─── Branche « données existantes » ────────────────────────────────────
  Question(
    id: Q.source,
    title: 'D\'où proviennent les données ?',
    choices: const [
      Choice('interne', 'Dossiers de mon établissement, exploités par l\'équipe '
          'qui soigne ces patients',
          hint: 'Pour un usage exclusivement interne'),
      Choice('multi', 'Plusieurs établissements, partenaires ou registres'),
      Choice('eds', 'Un entrepôt de données de santé (EDS)'),
      Choice('snds', 'Le SNDS (PMSI ou base principale)'),
    ],
    isVisible: _dataOnly,
  ),
  Question(
    id: Q.sndsAcces,
    title: 'Quel accès au SNDS est envisagé ?',
    choices: const [
      Choice('pmsi_es', 'PMSI par un établissement ou une fédération',
          hint: 'Cadre MR-005'),
      Choice('pmsi_industriel', 'PMSI par un industriel de santé',
          hint: 'Cadre MR-006'),
      Choice('principale', 'Base principale du SNDS',
          hint: 'Cadres MR-007 ou MR-008'),
    ],
    isVisible: (a) => _dataOnly(a) && a.single(Q.source) == 'snds',
  ),
  Question(
    id: Q.mr004,
    title: 'Le traitement peut-il respecter le cadre de la MR-004 ?',
    help: 'Données pseudonymisées et strictement nécessaires, information '
        'individuelle des personnes avec droit d\'opposition, pas de NIR, '
        'accès limité aux personnes habilitées, durée de conservation définie.',
    choices: const [
      Choice('oui', 'Oui'),
      Choice('non', 'Non, au moins un point s\'en écarte'),
      Choice('nsp', 'Je ne sais pas encore'),
    ],
    isVisible: (a) =>
        _dataOnly(a) &&
        (a.single(Q.source) == 'multi' || a.single(Q.source) == 'eds'),
  ),
  Question(
    id: Q.contexteDonnees,
    title: 'Quelles particularités s\'appliquent ?',
    help: 'Plusieurs réponses possibles, ou aucune.',
    multiple: true,
    choices: const [
      Choice('appariement', 'Appariement avec une autre base de données'),
      Choice('hors_ue', 'Transfert de données hors de l\'Union européenne'),
      Choice('mineurs', 'Données de mineurs'),
      Choice('industriel', 'Responsable de traitement industriel'),
    ],
    isVisible: _dataOnly,
  ),

  // ─── Branche prospective ───────────────────────────────────────────────
  Question(
    id: Q.produit,
    title: 'La recherche porte-t-elle sur un produit de santé ?',
    choices: const [
      Choice('medicament', 'Un médicament',
          hint: 'Efficacité, sécurité, pharmacocinétique, stratégie médicamenteuse'),
      Choice('dm', 'Un dispositif médical'),
      Choice('div', 'Un dispositif médical de diagnostic in vitro'),
      Choice('aucun', 'Non : une stratégie, une procédure, un comportement',
          hint: 'Chirurgie, rééducation, éducation thérapeutique, physiologie…'),
    ],
    isVisible: _prospective,
  ),
  Question(
    id: Q.medAttribution,
    title: 'Le protocole décide-t-il du traitement médicamenteux reçu ?',
    help: 'Attribution prospective, randomisation, dose ou schéma imposés par '
        'le protocole. Si la prescription relève de la pratique courante et '
        'précède la décision d\'inclure, répondez « non ».',
    choices: const [
      Choice('oui', 'Oui, c\'est le protocole qui attribue le traitement'),
      Choice('non', 'Non, on observe des traitements prescrits en soins courants'),
    ],
    isVisible: (a) => _prospective(a) && a.single(Q.produit) == 'medicament',
  ),
  Question(
    id: Q.medFaible,
    title: 'L\'essai peut-il être à faible niveau d\'intervention ?',
    help: 'Médicaments déjà autorisés, utilisés selon leur AMM ou selon un usage '
        'étayé par des données publiées, et procédures supplémentaires '
        'n\'entraînant qu\'un risque ou une contrainte minime.',
    choices: const [
      Choice('oui', 'Oui, les trois conditions sont réunies'),
      Choice('non', 'Non'),
    ],
    isVisible: (a) =>
        _prospective(a) &&
        a.single(Q.produit) == 'medicament' &&
        a.single(Q.medAttribution) == 'oui',
  ),
  Question(
    id: Q.dmCe,
    title: 'Le dispositif porte-t-il déjà le marquage CE ?',
    choices: const [
      Choice('oui', 'Oui'),
      Choice('non', 'Non (y compris sur mesure ou fabrication interne)'),
    ],
    isVisible: (a) => _prospective(a) && a.single(Q.produit) == 'dm',
  ),
  Question(
    id: Q.dmUsage,
    title: 'Le dispositif est-il utilisé dans sa destination ?',
    help: 'Indication, population et mode d\'emploi prévus par le fabricant.',
    choices: const [
      Choice('conforme', 'Oui, conformément à sa destination'),
      Choice('hors', 'Non, en dehors de sa destination'),
    ],
    isVisible: (a) =>
        _prospective(a) &&
        a.single(Q.produit) == 'dm' &&
        a.single(Q.dmCe) == 'oui',
  ),
  Question(
    id: Q.dmObjectif,
    title: 'L\'investigation vise-t-elle à obtenir ou étendre le marquage CE ?',
    choices: const [
      Choice('conformite', 'Oui, démontrer la conformité du dispositif'),
      Choice('autre', 'Non, autre objectif scientifique'),
    ],
    isVisible: (a) =>
        _prospective(a) &&
        a.single(Q.produit) == 'dm' &&
        (a.single(Q.dmCe) == 'non' || a.single(Q.dmUsage) == 'hors'),
  ),
  Question(
    id: Q.dmProcedures,
    title: 'Le protocole ajoute-t-il des procédures aux soins habituels ?',
    choices: const [
      Choice('aucune', 'Aucune procédure supplémentaire',
          hint: 'Recueil de données issues de la pratique courante'),
      Choice('legeres', 'Oui, non invasives et non lourdes',
          hint: 'Questionnaires, examens cliniques simples'),
      Choice('lourdes', 'Oui, invasives ou lourdes',
          hint: 'Prélèvements, imagerie irradiante, visites contraignantes'),
    ],
    isVisible: (a) =>
        _prospective(a) &&
        a.single(Q.produit) == 'dm' &&
        a.single(Q.dmCe) == 'oui' &&
        a.single(Q.dmUsage) == 'conforme',
  ),
  Question(
    id: Q.divPrelevement,
    title: 'Des prélèvements sont-ils réalisés spécifiquement pour l\'étude ?',
    choices: const [
      Choice('oui', 'Oui, prélèvements chirurgicaux invasifs ou procédures '
          'supplémentaires'),
      Choice('non', 'Non, uniquement des échantillons résiduels'),
    ],
    isVisible: (a) => _prospective(a) && a.single(Q.produit) == 'div',
  ),
  Question(
    id: Q.intervention,
    title: 'La prise en charge des participants est-elle modifiée ?',
    help: 'Comparez avec ce que le patient aurait reçu sans la recherche.',
    choices: const [
      Choice('lourde', 'Oui : intervention non justifiée par la prise en '
          'charge habituelle',
          hint: 'Nouvelle technique, acte à risque, traitement imposé'),
      Choice('minime', 'Oui, mais par des actes à risques et contraintes '
          'minimes',
          hint: 'Actes figurant sur la liste fixée par arrêté'),
      Choice('aucune', 'Non : prise en charge strictement habituelle'),
    ],
    isVisible: needsInterventionQuestions,
  ),
  Question(
    id: Q.actes,
    title: 'Quels actes sont ajoutés pour la recherche ?',
    help: 'Plusieurs réponses possibles.',
    multiple: true,
    choices: const [
      Choice('randomisation', 'Randomisation entre stratégies de soins courants'),
      Choice('sang', 'Prélèvement sanguin supplémentaire de volume limité'),
      Choice('non_invasif', 'Prélèvement non invasif (salive, urines, selles…)'),
      Choice('imagerie', 'Imagerie non irradiante ou examen fonctionnel'),
      Choice('questionnaire_impact',
          'Questionnaire ou entretien pouvant avoir un impact sur la personne'),
      Choice('questionnaire_simple',
          'Questionnaire sans impact, ou simple recueil de données'),
    ],
    isVisible: (a) =>
        needsInterventionQuestions(a) && a.single(Q.intervention) != 'lourde',
  ),
  Question(
    id: Q.contexte,
    title: 'Quelles particularités s\'appliquent à votre recherche ?',
    help: 'Plusieurs réponses possibles, ou aucune.',
    multiple: true,
    choices: const [
      Choice('mineurs', 'Inclusion de mineurs'),
      Choice('proteges', 'Majeurs protégés ou hors d\'état de consentir'),
      Choice('grossesse', 'Femmes enceintes, parturientes ou allaitantes'),
      Choice('urgence', 'Situation d\'urgence (consentement différé)'),
      Choice('genetique', 'Examen des caractéristiques génétiques'),
      Choice('collection', 'Échantillons conservés après la recherche'),
      Choice('volontaires_sains', 'Volontaires sains'),
      Choice('industriel', 'Promoteur industriel'),
      Choice('multicentrique', 'Plusieurs centres'),
      Choice('international', 'Centres hors de France'),
    ],
    isVisible: _prospective,
  ),
];

/// Les questions visibles pour un jeu de réponses, dans l'ordre.
List<Question> visibleQuestions(Answers answers) =>
    questionnaire.where((q) => q.isVisible(answers)).toList();

/// Supprime les réponses aux questions devenues invisibles (après un retour
/// en arrière qui change de branche).
Answers pruneAnswers(Answers answers) {
  var current = Map<String, Set<String>>.of(answers);
  while (true) {
    final visible = visibleQuestions(current).map((q) => q.id).toSet();
    final next = {
      for (final e in current.entries)
        if (visible.contains(e.key)) e.key: e.value,
    };
    if (next.length == current.length) return next;
    current = next;
  }
}

/// Vrai quand toutes les questions visibles à choix unique ont une réponse.
/// Les questions à choix multiples peuvent rester vides (« aucune »).
bool isComplete(Answers answers) => visibleQuestions(answers).every(
      (q) => q.multiple ? answers.containsKey(q.id) : answers.single(q.id) != null,
    );
