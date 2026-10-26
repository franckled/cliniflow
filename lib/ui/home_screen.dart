import 'package:flutter/material.dart';

import '../data/project.dart';
import '../data/project_store.dart';
import 'about_screen.dart';
import 'project_screen.dart';
import 'theme.dart';
import 'wizard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final ProjectStore store;

  Future<void> _newProject(BuildContext context) async {
    final created = await showModalBottomSheet<Project>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NewProjectSheet(store: store),
    );
    if (created == null || !context.mounted) return;
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WizardScreen(store: store, projectId: created.id),
      ),
    );
    if (done == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectScreen(store: store, projectId: created.id),
        ),
      );
    }
  }

  /// Ouvre un projet ; reprend d'abord le questionnaire s'il est inachevé.
  Future<void> _open(BuildContext context, Project p) async {
    final nav = Navigator.of(context);
    if (p.classification == null) {
      final done = await nav.push<bool>(
        MaterialPageRoute(
          builder: (_) => WizardScreen(store: store, projectId: p.id),
        ),
      );
      if (done != true) return;
    }
    await nav.push(
      MaterialPageRoute(
        builder: (_) => ProjectScreen(store: store, projectId: p.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CliniFlow'),
        actions: [
          IconButton(
            tooltip: 'À propos',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newProject(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau projet'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final projects = store.projects;
          if (projects.isEmpty) return const _EmptyState();
          final now = DateTime.now();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ProjectCard(
              project: projects[i],
              now: now,
              onTap: () => _open(context, projects[i]),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text('Du protocole à la première inclusion',
                style: t.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Qualifiez votre recherche en quelques questions, puis suivez '
              'pas à pas les démarches : CPP, ANSM, CNIL, assurance, '
              'déclarations.',
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos projets restent sur cet appareil.',
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.now,
    required this.onTap,
  });

  final Project project;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final c = project.classification;
    final progress = project.progress;
    final overdue = project.overdueCount(now);
    final next = project.nextDeadline();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.displayName,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (project.acronym.isNotEmpty && project.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 12),
              if (c == null)
                Row(children: [
                  Icon(Icons.edit_note, size: 18, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('Qualification à terminer',
                      style: t.labelLarge?.copyWith(color: cs.primary)),
                ])
              else ...[
                CategoryBadge(c.category, dense: true),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.total == 0
                        ? 0
                        : progress.done / progress.total,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${progress.done}/${progress.total} étapes',
                        style: t.bodySmall),
                    const Spacer(),
                    if (overdue > 0)
                      Text(
                        overdue == 1 ? '1 en retard' : '$overdue en retard',
                        style: t.bodySmall?.copyWith(
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (next != null)
                      Text('Échéance ${formatDate(next.due)}',
                          style: t.bodySmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewProjectSheet extends StatefulWidget {
  const _NewProjectSheet({required this.store});

  final ProjectStore store;

  @override
  State<_NewProjectSheet> createState() => _NewProjectSheetState();
}

class _NewProjectSheetState extends State<_NewProjectSheet> {
  final _title = TextEditingController();
  final _acronym = TextEditingController();
  final _sponsor = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _acronym.dispose();
    _sponsor.dispose();
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty || _acronym.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    try {
      final p = await widget.store.create(
        title: _title.text,
        acronym: _acronym.text,
        sponsor: _sponsor.text,
      );
      if (mounted) Navigator.of(context).pop(p);
    } on Object catch (e) {
      // Jamais d'échec silencieux : l'utilisateur doit voir le problème.
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Création impossible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouveau projet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _acronym,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Acronyme'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Titre de l\'étude'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sponsor,
            decoration: const InputDecoration(
              labelText: 'Promoteur (facultatif)',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _valid && !_busy ? _submit : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Qualifier la recherche'),
          ),
        ],
      ),
    );
  }
}
