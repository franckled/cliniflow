/// Modèles du moteur de qualification CliniFlow.
///
/// Ce dossier `lib/engine/` n'importe jamais Flutter : il reste testable en
/// Dart pur et peut être réutilisé (web, CLI, serveur) sans modification.
library;

/// Grandes familles de recherche, telles que l'app les présente.
enum ResearchCategory {
  horsRecherche,
  riph1,
  riph2,
  riph3,
  essaiMedicament,
  essaiMedicamentFaibleIntervention,
  dmConformite,
  dmCas1,
  dmCas2,
  dmCas3,
  dmCas4,
  diagnosticInVitro,
  etudeInterne,
  donneesMr004,
  donneesSnds,
  donneesAutorisation,
}

extension ResearchCategoryInfo on ResearchCategory {
  /// Libellé court affiché sur les cartes et dans le PDF.
  String get label => switch (this) {
        ResearchCategory.horsRecherche => 'Hors recherche',
        ResearchCategory.riph1 => 'RIPH 1',
        ResearchCategory.riph2 => 'RIPH 2',
        ResearchCategory.riph3 => 'RIPH 3',
        ResearchCategory.essaiMedicament => 'Essai clinique de médicament',
        ResearchCategory.essaiMedicamentFaibleIntervention =>
          'Essai de médicament à faible niveau d\'intervention',
        ResearchCategory.dmConformite =>
          'Investigation clinique DM de conformité',
        ResearchCategory.dmCas1 => 'Investigation DM – cas 1',
        ResearchCategory.dmCas2 => 'Investigation DM – cas 2',
        ResearchCategory.dmCas3 => 'Investigation DM – cas 3',
        ResearchCategory.dmCas4 => 'Investigation DM – cas 4',
        ResearchCategory.diagnosticInVitro =>
          'Étude de performance DIV',
        ResearchCategory.etudeInterne => 'Étude interne sur données',
        ResearchCategory.donneesMr004 => 'Recherche sur données (MR-004)',
        ResearchCategory.donneesSnds => 'Recherche sur données du SNDS',
        ResearchCategory.donneesAutorisation =>
          'Recherche sur données – autorisation CNIL',
      };

  /// Cadre juridique principal, en une ligne.
  String get framework => switch (this) {
        ResearchCategory.horsRecherche =>
          'RGPD – pas de formalité « recherche »',
        ResearchCategory.riph1 ||
        ResearchCategory.riph2 ||
        ResearchCategory.riph3 =>
          'Loi Jardé – art. L. 1121-1 CSP',
        ResearchCategory.essaiMedicament ||
        ResearchCategory.essaiMedicamentFaibleIntervention =>
          'Règlement (UE) 536/2014 – portail CTIS',
        ResearchCategory.dmConformite ||
        ResearchCategory.dmCas1 ||
        ResearchCategory.dmCas2 ||
        ResearchCategory.dmCas3 ||
        ResearchCategory.dmCas4 =>
          'Règlement (UE) 2017/745 + adaptations nationales',
        ResearchCategory.diagnosticInVitro => 'Règlement (UE) 2017/746',
        ResearchCategory.etudeInterne => 'RGPD – registre du responsable',
        ResearchCategory.donneesMr004 => 'Loi Informatique et Libertés – MR-004',
        ResearchCategory.donneesSnds =>
          'Loi Informatique et Libertés – MR-005 à MR-008',
        ResearchCategory.donneesAutorisation =>
          'CESREES + autorisation CNIL',
      };

  /// Famille utilisée pour la couleur et le regroupement visuel.
  CategoryFamily get family => switch (this) {
        ResearchCategory.horsRecherche => CategoryFamily.neutral,
        ResearchCategory.riph1 => CategoryFamily.high,
        ResearchCategory.riph2 => CategoryFamily.medium,
        ResearchCategory.riph3 => CategoryFamily.low,
        ResearchCategory.essaiMedicament ||
        ResearchCategory.essaiMedicamentFaibleIntervention =>
          CategoryFamily.drug,
        ResearchCategory.dmConformite ||
        ResearchCategory.dmCas1 ||
        ResearchCategory.dmCas2 ||
        ResearchCategory.dmCas3 ||
        ResearchCategory.dmCas4 ||
        ResearchCategory.diagnosticInVitro =>
          CategoryFamily.device,
        ResearchCategory.etudeInterne ||
        ResearchCategory.donneesMr004 ||
        ResearchCategory.donneesSnds ||
        ResearchCategory.donneesAutorisation =>
          CategoryFamily.data,
      };

  /// Vrai si la recherche relève d'un CPP (loi Jardé, CTR, DM, DIV).
  bool get involvesHumanPerson => switch (family) {
        CategoryFamily.high ||
        CategoryFamily.medium ||
        CategoryFamily.low ||
        CategoryFamily.drug ||
        CategoryFamily.device =>
          true,
        CategoryFamily.data || CategoryFamily.neutral => false,
      };
}

enum CategoryFamily { high, medium, low, drug, device, data, neutral }

/// Une option de réponse.
class Choice {
  const Choice(this.id, this.label, {this.hint});
  final String id;
  final String label;
  final String? hint;
}

/// Réponses saisies : identifiant de question → identifiants d'options
/// (une seule pour une question à choix unique).
typedef Answers = Map<String, Set<String>>;

extension AnswersRead on Answers {
  String? single(String questionId) {
    final v = this[questionId];
    return (v == null || v.isEmpty) ? null : v.first;
  }

  bool has(String questionId, String choiceId) =>
      this[questionId]?.contains(choiceId) ?? false;
}

/// Une question du parcours de qualification.
class Question {
  const Question({
    required this.id,
    required this.title,
    required this.choices,
    this.help,
    this.multiple = false,
    required this.isVisible,
  });

  final String id;
  final String title;
  final String? help;
  final List<Choice> choices;
  final bool multiple;

  /// La question n'est posée que si ce prédicat est vrai pour les réponses
  /// déjà données.
  final bool Function(Answers answers) isVisible;

  Choice choice(String id) => choices.firstWhere((c) => c.id == id);
}

/// Résultat argumenté de la qualification.
class Classification {
  const Classification({
    required this.category,
    required this.reasons,
    required this.toConfirm,
    required this.flags,
  });

  final ResearchCategory category;

  /// Pourquoi l'app aboutit à cette catégorie (une phrase par critère).
  final List<String> reasons;

  /// Points de vigilance à valider avec la DRCI, le DPO ou le CPP.
  final List<String> toConfirm;

  /// Caractéristiques complémentaires (populations, génétique…).
  final Set<String> flags;
}

/// Phases d'un parcours réglementaire, dans l'ordre chronologique.
enum Phase { conception, soumission, demarrage, conduite, cloture }

extension PhaseLabel on Phase {
  String get label => switch (this) {
        Phase.conception => 'Conception',
        Phase.soumission => 'Soumissions & avis',
        Phase.demarrage => 'Avant la première inclusion',
        Phase.conduite => 'Pendant la recherche',
        Phase.cloture => 'Fin de recherche',
      };
}

/// Une étape réglementaire ou administrative à accomplir.
class RegulatoryStep {
  const RegulatoryStep({
    required this.id,
    required this.phase,
    required this.title,
    required this.detail,
    this.actor,
    this.delay,
    this.link,
  });

  final String id;
  final Phase phase;
  final String title;
  final String detail;

  /// Instance ou interlocuteur (CPP, ANSM, CNIL, DPO, DRCI…).
  final String? actor;

  /// Délai indicatif, en clair.
  final String? delay;

  /// Lien vers une source officielle.
  final String? link;
}
