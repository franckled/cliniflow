import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/project.dart';
import '../data/project_store.dart';
import '../engine/engine.dart';
import '../pdf/summary_pdf.dart';
import 'line.dart';
import 'theme.dart';
import 'wizard_screen.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({
    super.key,
    required this.store,
    required this.projectId,
    this.initialTab = 0,
  });

  final ProjectStore store;
  final String projectId;
  final int initialTab;

  Future<void> _requalify(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WizardScreen(store: store, projectId: projectId),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Project p) async {
    final updated = await showDialog<Project>(
      context: context,
      builder: (_) => _EditProjectDialog(project: p),
    );
    if (updated != null) await store.update(updated);
  }

  Future<void> _delete(BuildContext context, Project p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce projet ?'),
        content: Text('« ${p.displayName} » et son suivi seront effacés de '
            'cet appareil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop();
      await store.delete(p.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.byId(projectId);
        if (p == null) return const Scaffold();
        final c = p.classification;
        return DefaultTabController(
          length: 3,
          initialIndex: initialTab,
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Options',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (v) => switch (v) {
                    'edit' => _edit(context, p),
                    'requalify' => _requalify(context),
                    'delete' => _delete(context, p),
                    _ => null,
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'edit', child: Text('Modifier le titre')),
                    PopupMenuItem(
                        value: 'requalify',
                        child: Text('Revoir les réponses')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
                const SizedBox(width: 4),
              ],
              bottom: const TabBar(
                tabAlignment: TabAlignment.fill,
                tabs: [
                  Tab(text: 'Qualification'),
                  Tab(text: 'Parcours'),
                  Tab(text: 'Synthèse'),
                ],
              ),
            ),
            body: c == null
                ? _Incomplete(onResume: () => _requalify(context))
                : Builder(
                    // Contexte sous le DefaultTabController.
                    builder: (tabContext) => TabBarView(children: [
                      _QualificationTab(
                        classification: c,
                        onRequalify: () => _requalify(context),
                        onShowPathway: () =>
                            DefaultTabController.of(tabContext).animateTo(1),
                      ),
                      _PathwayTab(store: store, project: p),
                      _SummaryTab(project: p, classification: c),
                    ]),
                  ),
          ),
        );
      },
    );
  }
}

class _Incomplete extends StatelessWidget {
  const _Incomplete({required this.onResume});
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('La qualification n\'est pas terminée.',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onResume,
                child: const Text('Reprendre le questionnaire'),
              ),
            ],
          ),
        ),
      );
}

// ─── Onglet Qualification ──────────────────────────────────────────────────

class _QualificationTab extends StatelessWidget {
  const _QualificationTab({
    required this.classification,
    required this.onRequalify,
    required this.onShowPathway,
  });

  final Classification classification;
  final VoidCallback onRequalify;
  final VoidCallback onShowPathway;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);
    final cat = classification.category;
    final color = familyColor(cat.family, Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // Le verdict : la catégorie, dans la couleur de sa famille.
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(familyIcon(cat.family),
                        color: Theme.of(context).colorScheme.surface),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Votre recherche relève de',
                        style: t.labelLarge?.copyWith(color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(cat.label, style: t.displaySmall?.copyWith(color: color)),
              const SizedBox(height: 8),
              Text(cat.framework, style: t.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Pourquoi', style: t.titleLarge),
        const SizedBox(height: 10),
        for (final r in classification.reasons)
          _Reason(text: r, icon: Icons.check_rounded, color: tones.done),
        if (classification.toConfirm.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: tones.pending.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À faire confirmer',
                    style: t.titleMedium?.copyWith(color: tones.pending)),
                const SizedBox(height: 2),
                Text('Par la DRCI, le DPO ou le CPP selon le point.',
                    style: t.bodySmall?.copyWith(color: tones.muted)),
                const SizedBox(height: 10),
                for (final r in classification.toConfirm)
                  _Reason(
                    text: r,
                    icon: Icons.flag_rounded,
                    color: tones.pending,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: onShowPathway,
          icon: const Icon(Icons.route_rounded),
          label: const Text('Voir le parcours'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRequalify,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Revoir les réponses'),
        ),
        const SizedBox(height: 20),
        Text(
          'CliniFlow est une aide à la décision. La qualification définitive '
          'relève du promoteur et, le cas échéant, du CPP saisi.',
          style: t.bodySmall?.copyWith(color: tones.muted),
        ),
      ],
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.text, required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
}

// ─── Onglet Parcours : la ligne ────────────────────────────────────────────

class _PathwayTab extends StatelessWidget {
  const _PathwayTab({required this.store, required this.project});

  final ProjectStore store;
  final Project project;

  void _cycle(StopItem s) => store.update(project.withTracking(
        s.step.id,
        s.tracking.copyWith(
          status: s.tracking.status.next,
          completedAt: () =>
              s.tracking.status.next == StepStatus.done ? DateTime.now() : null,
        ),
      ));

  void _open(BuildContext context, String stepId) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _StepSheet(
          store: store,
          projectId: project.id,
          stepId: stepId,
        ),
      );

  Widget _row(
    BuildContext context,
    List<LineItem> items,
    int i,
    Color Function(LineItem) seg,
  ) {
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);
    final item = items[i];
    final last = i == items.length - 1;
    if (item is StationItem) {
      return LineRow(
        key: ValueKey('station-${item.phase.name}'),
        node: StationNode(complete: item.complete),
        nodeSize: 26,
        incoming: i == 0 ? null : seg(items[i - 1]),
        outgoing: last ? null : seg(item),
        child: Padding(
          padding: const EdgeInsets.only(top: 1, bottom: 14, left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(item.phase.label, style: t.titleLarge)),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${item.passedCount}/${item.stops.length}',
                    style: t.labelMedium?.copyWith(
                      color: item.complete ? tones.done : tones.muted,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
        ),
      );
    }
    final s = item as StopItem;
    return LineRow(
      key: ValueKey('stop-${s.step.id}'),
      node: StopNode(s.state),
      nodeSize: 18,
      nodeTop: 3,
      incoming: seg(items[i - 1]),
      outgoing: last ? null : seg(s),
      onNodeTap: () => _cycle(s),
      nodeTooltip: '${s.tracking.status.label} – toucher pour passer à '
          '« ${s.tracking.status.next.label} »',
      child: _StopLabel(
        stop: s,
        onTap: () => _open(context, s.step.id),
        lastOfStation: last || items[i + 1] is StationItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stations = stationsOf(project, now);
    final tones = Tones.of(context);
    final t = Theme.of(context).textTheme;
    final progress = project.progress;
    final next = project.nextDeadline();
    final overdue = project.overdueCount(now);

    // Liste à plat : station, arrêts, station, arrêts…
    final items = <LineItem>[
      for (final st in stations) ...[st, ...st.stops],
    ];
    bool passed(LineItem i) => switch (i) {
          StationItem s => s.complete,
          StopItem s => s.passed,
        };
    Color seg(LineItem i) => passed(i) ? tones.done : tones.line;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 48),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${progress.done}',
                  style: t.displaySmall?.copyWith(color: tones.done)),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 6),
                child: Text('sur ${progress.total} démarches soldées',
                    style: t.bodyMedium?.copyWith(color: tones.muted)),
              ),
            ],
          ),
        ),
        if (overdue > 0 || next != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6),
            child: Text(
              overdue > 0
                  ? (overdue == 1
                      ? '1 démarche a dépassé son échéance'
                      : '$overdue démarches ont dépassé leur échéance')
                  : 'Prochaine échéance le ${formatDate(next!.due)} : '
                      '${next.step.title.toLowerCase()}',
              style: t.bodyMedium?.copyWith(
                color: overdue > 0 ? tones.overdue : tones.muted,
                fontWeight: overdue > 0 ? FontWeight.w700 : null,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 20),
          child: Text(
            'Touchez un rond pour avancer une démarche, son intitulé pour '
            'le détail.',
            style: t.bodySmall?.copyWith(color: tones.muted),
          ),
        ),
        for (var i = 0; i < items.length; i++)
          _row(context, items, i, seg),
      ],
    );
  }
}

class _StopLabel extends StatelessWidget {
  const _StopLabel({
    required this.stop,
    required this.onTap,
    required this.lastOfStation,
  });

  final StopItem stop;
  final VoidCallback onTap;
  final bool lastOfStation;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);
    final s = stop.step;
    final tr = stop.tracking;
    final faded = stop.passed;

    final meta = <String>[
      if (s.actor != null) s.actor!,
      if (tr.dueDate != null)
        'échéance ${formatDate(tr.dueDate!)}'
      else if (s.delay != null)
        s.delay!,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: lastOfStation ? 26 : 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: t.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: faded ? tones.muted : null,
                        decoration: stop.state == StopState.done
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: tones.muted,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta.join(', '),
                        style: t.bodySmall?.copyWith(
                          color: stop.state == StopState.overdue
                              ? tones.overdue
                              : tones.muted,
                          fontWeight: stop.state == StopState.overdue
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tr.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Icon(Icons.sticky_note_2_outlined,
                      size: 18, color: tones.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fiche d'une démarche : détail, statut, échéance, note, source.
class _StepSheet extends StatelessWidget {
  const _StepSheet({
    required this.store,
    required this.projectId,
    required this.stepId,
  });

  final ProjectStore store;
  final String projectId;
  final String stepId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final p = store.byId(projectId);
        final step = p?.steps.where((s) => s.id == stepId).firstOrNull;
        if (p == null || step == null) return const SizedBox.shrink();
        final tr = p.trackingFor(stepId);
        final t = Theme.of(context).textTheme;
        final tones = Tones.of(context);
        final now = DateTime.now();

        void save(StepTracking next) =>
            store.update(p.withTracking(stepId, next));

        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: tr.dueDate ?? now,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 10),
            helpText: 'Échéance',
          );
          if (picked != null) save(tr.copyWith(dueDate: () => picked));
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(
              24,
              0,
              24,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Text(step.phase.label,
                  style: t.labelLarge?.copyWith(color: tones.done)),
              const SizedBox(height: 6),
              Text(step.title, style: t.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (step.actor != null)
                    _Fact(
                      icon: Icons.account_balance_outlined,
                      text: step.actor!,
                    ),
                  if (step.delay != null)
                    _Fact(icon: Icons.schedule_rounded, text: step.delay!),
                ],
              ),
              const SizedBox(height: 16),
              Text(step.detail, style: t.bodyLarge),
              if (step.link != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => launchUrl(
                      Uri.parse(step.link!),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Consulter la source officielle'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Statut', style: t.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in StepStatus.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: tr.status == s,
                      showCheckmark: false,
                      avatar: SizedBox.square(
                        dimension: 16,
                        child: StopNode(
                          stopStateOf(StepTracking(status: s), now),
                          size: 16,
                        ),
                      ),
                      onSelected: (_) => save(tr.copyWith(
                        status: s,
                        completedAt: () =>
                            s == StepStatus.done ? DateTime.now() : null,
                      )),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Échéance', style: t.titleSmall),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr.dueDate == null
                          ? 'Aucune échéance fixée'
                          : formatDate(tr.dueDate!),
                      style: t.bodyLarge?.copyWith(
                        color: tr.isOverdue(now) ? tones.overdue : null,
                        fontWeight: tr.isOverdue(now) ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                  if (tr.dueDate != null)
                    TextButton(
                      onPressed: () => save(tr.copyWith(dueDate: () => null)),
                      child: const Text('Retirer'),
                    ),
                  TextButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: Text(tr.dueDate == null ? 'Fixer' : 'Modifier'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Note', style: t.titleSmall),
              const SizedBox(height: 8),
              _NoteField(
                key: ValueKey(stepId),
                initial: tr.note,
                onSaved: (v) => save(tr.copyWith(note: v)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tones = Tones.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tones.muted),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Note libre, enregistrée au fil de la saisie.
class _NoteField extends StatefulWidget {
  const _NoteField({super.key, required this.initial, required this.onSaved});
  final String initial;
  final ValueChanged<String> onSaved;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _ctrl,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (v) => widget.onSaved(v.trim()),
        decoration: const InputDecoration(
          hintText: 'Numéro de dossier, contact, pièce manquante…',
        ),
      );
}

// ─── Onglet Synthèse ───────────────────────────────────────────────────────

class _SummaryTab extends StatefulWidget {
  const _SummaryTab({required this.project, required this.classification});

  final Project project;
  final Classification classification;

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export impossible : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);
    final p = widget.project;
    final progress = p.progress;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        Text('Fiche de synthèse', style: t.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Un PDF avec la qualification argumentée, les points à confirmer '
          'et l\'état du parcours. À joindre au dossier ou à transmettre à la '
          'DRCI.',
          style: t.bodyMedium?.copyWith(color: tones.muted),
        ),
        const SizedBox(height: 24),
        // Aperçu de la fiche, à la façon d'une page.
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.displayName, style: t.titleLarge),
                if (p.acronym.isNotEmpty && p.title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.title,
                        style: t.bodyMedium?.copyWith(color: tones.muted)),
                  ),
                if (p.sponsor.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Promoteur : ${p.sponsor}',
                        style: t.bodyMedium),
                  ),
                const SizedBox(height: 16),
                CategoryBadge(widget.classification.category),
                const SizedBox(height: 18),
                MiniLine(stations: stationsOf(p, now)),
                const SizedBox(height: 10),
                Text(
                  '${progress.done} démarche${progress.done > 1 ? 's' : ''} '
                  'soldée${progress.done > 1 ? 's' : ''} sur ${progress.total}',
                  style: t.labelMedium?.copyWith(color: tones.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : () => _run(() => sharePdf(p)),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Partager le PDF'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _run(() => printPdf(p)),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Aperçu et impression'),
        ),
      ],
    );
  }
}

// ─── Modification du titre ─────────────────────────────────────────────────

class _EditProjectDialog extends StatefulWidget {
  const _EditProjectDialog({required this.project});
  final Project project;

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  late final _acronym = TextEditingController(text: widget.project.acronym);
  late final _title = TextEditingController(text: widget.project.title);
  late final _sponsor = TextEditingController(text: widget.project.sponsor);

  @override
  void dispose() {
    _acronym.dispose();
    _title.dispose();
    _sponsor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Projet'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _acronym,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Acronyme'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sponsor,
                decoration: const InputDecoration(labelText: 'Promoteur'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              if (_acronym.text.trim().isEmpty && _title.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(
                context,
                widget.project.copyWith(
                  acronym: _acronym.text.trim(),
                  title: _title.text.trim(),
                  sponsor: _sponsor.text.trim(),
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      );
}
