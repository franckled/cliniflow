import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/project.dart';
import '../data/project_store.dart';
import '../engine/engine.dart';
import '../pdf/summary_pdf.dart';
import 'theme.dart';
import 'wizard_screen.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key, required this.store, required this.projectId});

  final ProjectStore store;
  final String projectId;

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
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.displayName),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (v) => switch (v) {
                    'edit' => _edit(context, p),
                    'requalify' => _requalify(context),
                    'delete' => _delete(context, p),
                    _ => null,
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier le titre')),
                    PopupMenuItem(
                        value: 'requalify', child: Text('Revoir les réponses')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
              bottom: const TabBar(tabs: [
                Tab(text: 'Qualification'),
                Tab(text: 'Parcours'),
                Tab(text: 'Synthèse'),
              ]),
            ),
            body: c == null
                ? _Incomplete(onResume: () => _requalify(context))
                : TabBarView(children: [
                    _QualificationTab(
                      project: p,
                      classification: c,
                      onRequalify: () => _requalify(context),
                    ),
                    _PathwayTab(store: store, project: p),
                    _SummaryTab(project: p, classification: c),
                  ]),
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
              const Text('La qualification n\'est pas terminée.'),
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
    required this.project,
    required this.classification,
    required this.onRequalify,
  });

  final Project project;
  final Classification classification;
  final VoidCallback onRequalify;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final cat = classification.category;
    final color = familyColor(cat.family, Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: color.withValues(alpha: 0.10),
            border: Border.all(color: color.withValues(alpha: 0.40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(familyIcon(cat.family), color: color, size: 32),
              const SizedBox(height: 12),
              Text(cat.label,
                  style: t.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 4),
              Text(cat.framework, style: t.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle('Pourquoi cette catégorie'),
        for (final r in classification.reasons)
          _Bullet(text: r, icon: Icons.check_circle_outline, color: cs.primary),
        if (classification.toConfirm.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('À confirmer avec la DRCI, le DPO ou le CPP'),
          for (final r in classification.toConfirm)
            _Bullet(text: r, icon: Icons.flag_outlined, color: cs.tertiary),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: onRequalify,
          icon: const Icon(Icons.tune),
          label: const Text('Revoir les réponses'),
        ),
        const SizedBox(height: 16),
        Text(
          'CliniFlow est une aide à la décision. La qualification définitive '
          'relève du promoteur, et le cas échéant du CPP saisi.',
          style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.4)),
            ),
          ],
        ),
      );
}

// ─── Onglet Parcours ───────────────────────────────────────────────────────

class _PathwayTab extends StatelessWidget {
  const _PathwayTab({required this.store, required this.project});

  final ProjectStore store;
  final Project project;

  @override
  Widget build(BuildContext context) {
    final steps = project.steps;
    final byPhase = <Phase, List<RegulatoryStep>>{};
    for (final s in steps) {
      (byPhase[s.phase] ??= []).add(s);
    }
    final progress = project.progress;
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.total == 0
                      ? 0
                      : progress.done / progress.total,
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${progress.done}/${progress.total}', style: t.labelLarge),
          ],
        ),
        const SizedBox(height: 8),
        Text('Touchez la pastille d\'une étape pour changer son statut.',
            style: t.bodySmall),
        for (final phase in Phase.values)
          if (byPhase[phase] case final list?) ...[
            const SizedBox(height: 20),
            Text(phase.label.toUpperCase(),
                style: t.labelMedium?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                )),
            const SizedBox(height: 8),
            for (final s in list) ...[
              _StepTile(
                step: s,
                tracking: project.trackingFor(s.id),
                now: now,
                onChanged: (tr) => store.update(project.withTracking(s.id, tr)),
              ),
              const SizedBox(height: 8),
            ],
          ],
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.tracking,
    required this.now,
    required this.onChanged,
  });

  final RegulatoryStep step;
  final StepTracking tracking;
  final DateTime now;
  final ValueChanged<StepTracking> onChanged;

  void _setStatus(StepStatus s) => onChanged(tracking.copyWith(
        status: s,
        completedAt: () => s == StepStatus.done ? DateTime.now() : null,
      ));

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: tracking.dueDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
      helpText: 'Échéance',
    );
    if (picked != null) onChanged(tracking.copyWith(dueDate: () => picked));
  }

  Future<void> _editNote(BuildContext context) async {
    final ctrl = TextEditingController(text: tracking.note);
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Numéro de dossier, contact, pièce manquante…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (note != null) onChanged(tracking.copyWith(note: note));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final status = tracking.status;
    final overdue = tracking.isOverdue(now);
    final faded =
        status == StepStatus.done || status == StepStatus.notApplicable;

    final (IconData icon, Color color) = switch (status) {
      StepStatus.todo => (Icons.radio_button_unchecked, cs.outline),
      StepStatus.inProgress => (Icons.timelapse, cs.tertiary),
      StepStatus.done => (Icons.check_circle, cs.primary),
      StepStatus.notApplicable => (Icons.remove_circle_outline, cs.outline),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: IconButton(
            tooltip: '${status.label} – changer le statut',
            icon: Icon(icon, color: color),
            onPressed: () => _setStatus(status.next),
          ),
          title: Text(
            step.title,
            style: t.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: status == StepStatus.done
                  ? TextDecoration.lineThrough
                  : null,
              color: faded ? cs.onSurfaceVariant : cs.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (step.actor != null) _Tag(step.actor!),
                if (step.delay != null)
                  _Tag(step.delay!, icon: Icons.schedule),
                if (tracking.dueDate != null)
                  _Tag(
                    formatDate(tracking.dueDate!),
                    icon: Icons.event,
                    color: overdue ? cs.error : null,
                  ),
                if (tracking.note.isNotEmpty)
                  const _Tag('Note', icon: Icons.sticky_note_2_outlined),
              ],
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(step.detail,
                  style: t.bodyMedium?.copyWith(height: 1.45)),
            ),
            if (tracking.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(tracking.note, style: t.bodyMedium),
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<StepStatus>(
              showSelectedIcon: false,
              segments: [
                for (final s in StepStatus.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {status},
              onSelectionChanged: (v) => _setStatus(v.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.event),
                  label: Text(tracking.dueDate == null
                      ? 'Fixer une échéance'
                      : 'Modifier l\'échéance'),
                ),
                if (tracking.dueDate != null)
                  TextButton(
                    onPressed: () =>
                        onChanged(tracking.copyWith(dueDate: () => null)),
                    child: const Text('Retirer'),
                  ),
                TextButton.icon(
                  onPressed: () => _editNote(context),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Note'),
                ),
                if (step.link != null)
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(step.link!),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Source'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.icon, this.color});
  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? cs.surfaceContainerHighest).withValues(
          alpha: color == null ? 1 : 0.12,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: fg)),
        ],
      ),
    );
  }
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
    final cs = Theme.of(context).colorScheme;
    final p = widget.project;
    final progress = p.progress;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Text('Fiche de synthèse', style: t.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Un PDF qui reprend la qualification argumentée, les points à '
          'confirmer et l\'état du parcours réglementaire. À joindre au '
          'dossier ou à transmettre à la DRCI.',
          style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryBadge(widget.classification.category),
                const SizedBox(height: 12),
                Text(p.title.isEmpty ? p.displayName : p.title,
                    style: t.titleMedium),
                if (p.sponsor.isNotEmpty)
                  Text('Promoteur : ${p.sponsor}', style: t.bodyMedium),
                const SizedBox(height: 8),
                Text('${progress.done} étape(s) sur ${progress.total} '
                    'soldée(s)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : () => _run(() => sharePdf(p)),
          icon: const Icon(Icons.ios_share),
          label: const Text('Partager le PDF'),
        ),
        const SizedBox(height: 8),
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
