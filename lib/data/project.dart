import '../engine/engine.dart';

/// Avancement d'une étape du parcours.
enum StepStatus { todo, inProgress, done, notApplicable }

extension StepStatusLabel on StepStatus {
  String get label => switch (this) {
        StepStatus.todo => 'À faire',
        StepStatus.inProgress => 'En cours',
        StepStatus.done => 'Fait',
        StepStatus.notApplicable => 'Sans objet',
      };

  StepStatus get next => switch (this) {
        StepStatus.todo => StepStatus.inProgress,
        StepStatus.inProgress => StepStatus.done,
        StepStatus.done => StepStatus.todo,
        StepStatus.notApplicable => StepStatus.todo,
      };
}

/// Suivi d'une étape : statut, échéance, note libre.
class StepTracking {
  const StepTracking({
    this.status = StepStatus.todo,
    this.dueDate,
    this.completedAt,
    this.note = '',
  });

  final StepStatus status;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String note;

  StepTracking copyWith({
    StepStatus? status,
    DateTime? Function()? dueDate,
    DateTime? Function()? completedAt,
    String? note,
  }) =>
      StepTracking(
        status: status ?? this.status,
        dueDate: dueDate != null ? dueDate() : this.dueDate,
        completedAt: completedAt != null ? completedAt() : this.completedAt,
        note: note ?? this.note,
      );

  bool isOverdue(DateTime now) =>
      dueDate != null &&
      status != StepStatus.done &&
      status != StepStatus.notApplicable &&
      _day(dueDate!).isBefore(_day(now));

  Map<String, Object?> toJson() => {
        'status': status.name,
        'due': dueDate?.toIso8601String(),
        'done': completedAt?.toIso8601String(),
        'note': note,
      };

  factory StepTracking.fromJson(Map<String, Object?> j) => StepTracking(
        status: StepStatus.values.asNameMap()[j['status']] ?? StepStatus.todo,
        dueDate: DateTime.tryParse(j['due'] as String? ?? ''),
        completedAt: DateTime.tryParse(j['done'] as String? ?? ''),
        note: j['note'] as String? ?? '',
      );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Un projet de recherche suivi dans l'app.
class Project {
  const Project({
    required this.id,
    required this.title,
    this.acronym = '',
    this.sponsor = '',
    required this.createdAt,
    required this.updatedAt,
    this.answers = const {},
    this.tracking = const {},
  });

  final String id;
  final String title;
  final String acronym;

  /// Promoteur (texte libre : DRCI, CH, industriel…).
  final String sponsor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Answers answers;

  /// Suivi par identifiant d'étape. Les étapes absentes sont « à faire ».
  final Map<String, StepTracking> tracking;

  String get displayName => acronym.isNotEmpty ? acronym : title;

  Classification? get classification => classify(answers);

  List<RegulatoryStep> get steps {
    final c = classification;
    return c == null ? const [] : buildPathway(c);
  }

  StepTracking trackingFor(String stepId) =>
      tracking[stepId] ?? const StepTracking();

  /// Avancement : étapes faites ou sans objet / étapes du parcours.
  ({int done, int total}) get progress {
    final s = steps;
    final done = s.where((x) {
      final st = trackingFor(x.id).status;
      return st == StepStatus.done || st == StepStatus.notApplicable;
    }).length;
    return (done: done, total: s.length);
  }

  int overdueCount(DateTime now) =>
      steps.where((s) => trackingFor(s.id).isOverdue(now)).length;

  /// Prochaine échéance non soldée, la plus proche.
  ({RegulatoryStep step, DateTime due})? nextDeadline() {
    ({RegulatoryStep step, DateTime due})? best;
    for (final s in steps) {
      final t = trackingFor(s.id);
      if (t.dueDate == null ||
          t.status == StepStatus.done ||
          t.status == StepStatus.notApplicable) {
        continue;
      }
      if (best == null || t.dueDate!.isBefore(best.due)) {
        best = (step: s, due: t.dueDate!);
      }
    }
    return best;
  }

  Project copyWith({
    String? title,
    String? acronym,
    String? sponsor,
    Answers? answers,
    Map<String, StepTracking>? tracking,
    DateTime? updatedAt,
  }) =>
      Project(
        id: id,
        title: title ?? this.title,
        acronym: acronym ?? this.acronym,
        sponsor: sponsor ?? this.sponsor,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        answers: answers ?? this.answers,
        tracking: tracking ?? this.tracking,
      );

  Project withTracking(String stepId, StepTracking t) =>
      copyWith(tracking: {...tracking, stepId: t});

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'acronym': acronym,
        'sponsor': sponsor,
        'created': createdAt.toIso8601String(),
        'updated': updatedAt.toIso8601String(),
        'answers': {
          for (final e in answers.entries) e.key: e.value.toList(),
        },
        'tracking': {
          for (final e in tracking.entries) e.key: e.value.toJson(),
        },
      };

  factory Project.fromJson(Map<String, Object?> j) {
    final answers = (j['answers'] as Map<String, Object?>?) ?? const {};
    final tracking = (j['tracking'] as Map<String, Object?>?) ?? const {};
    return Project(
      id: j['id']! as String,
      title: j['title'] as String? ?? '',
      acronym: j['acronym'] as String? ?? '',
      sponsor: j['sponsor'] as String? ?? '',
      createdAt: DateTime.tryParse(j['created'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(j['updated'] as String? ?? '') ??
          DateTime.now(),
      answers: {
        for (final e in answers.entries)
          e.key: {...(e.value! as List<Object?>).cast<String>()},
      },
      tracking: {
        for (final e in tracking.entries)
          e.key: StepTracking.fromJson(e.value! as Map<String, Object?>),
      },
    );
  }
}

/// Format court jj/mm/aaaa, sans dépendance à `intl`.
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';
