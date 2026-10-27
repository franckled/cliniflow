import 'package:flutter/material.dart';

import '../data/project.dart';
import '../data/project_store.dart';
import 'about_screen.dart';
import 'credit.dart';
import 'line.dart';
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
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final projects = store.projects;
        final now = DateTime.now();
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: const _Brand(),
            actions: [
              IconButton(
                tooltip: 'À propos',
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: projects.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _newProject(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouvelle recherche'),
                ),
          body: projects.isEmpty
              ? _EmptyState(onStart: () => _newProject(context))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 112),
                  children: [
                    _Header(projects: projects, now: now),
                    const SizedBox(height: 20),
                    for (final p in projects) ...[
                      _ProjectCard(
                        project: p,
                        now: now,
                        onTap: () => _open(context, p),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const CreditLine(padding: EdgeInsets.only(top: 14)),
                  ],
                ),
        );
      },
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset('assets/icon/icon.png', width: 30, height: 30),
        ),
        const SizedBox(width: 10),
        Text('CliniFlow',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.projects, required this.now});

  final List<Project> projects;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);
    final overdue = projects.fold<int>(0, (n, p) => n + p.overdueCount(now));
    final count = projects.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mes recherches', style: t.headlineMedium),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: count == 1 ? '1 projet suivi' : '$count projets suivis'),
            if (overdue > 0) ...[
              const TextSpan(text: ', '),
              TextSpan(
                text: overdue == 1
                    ? '1 démarche en retard'
                    : '$overdue démarches en retard',
                style: TextStyle(
                  color: tones.overdue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ]),
          style: t.bodyMedium?.copyWith(color: tones.muted),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);

    Widget station(String title, String text,
            {Color? incoming, Color? outgoing, bool first = false}) =>
        LineRow(
          node: StationNode(complete: first),
          nodeSize: 26,
          incoming: incoming,
          outgoing: outgoing,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 26, top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                const SizedBox(height: 4),
                Text(text, style: t.bodyMedium?.copyWith(color: tones.muted)),
              ],
            ),
          ),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Du protocole\nà la première inclusion',
              style: t.displaySmall),
          const SizedBox(height: 14),
          Text(
            'Qualifiez votre recherche en quelques questions, puis suivez '
            'chaque démarche jusqu\'à la clôture.',
            style: t.bodyLarge?.copyWith(color: tones.muted),
          ),
          const SizedBox(height: 32),
          station('Qualifier',
              'RIPH 1, 2 ou 3, essai de médicament, dispositif médical, '
              'recherche sur données.',
              outgoing: tones.done, first: true),
          station('Déposer', 'CPP, ANSM, CNIL, assurance : chaque pièce, '
              'dans l\'ordre.',
              incoming: tones.done, outgoing: tones.line),
          station('Conduire et clôturer',
              'Modifications, vigilance, fin de recherche, résultats.',
              incoming: tones.line),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Qualifier une recherche'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: tones.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vos projets restent sur cet appareil. Aucun compte, '
                  'aucun serveur.',
                  style: t.bodySmall?.copyWith(color: tones.muted),
                ),
              ),
            ],
          ),
          const CreditLine(),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
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
    final tones = Tones.of(context);
    final cs = Theme.of(context).colorScheme;
    final c = project.classification;
    final progress = project.progress;
    final overdue = project.overdueCount(now);
    final next = project.nextDeadline();
    final showTitle = project.acronym.isNotEmpty && project.title.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.displayName,
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: tones.muted),
                ],
              ),
              if (showTitle) ...[
                const SizedBox(height: 2),
                Text(
                  project.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(color: tones.muted),
                ),
              ],
              const SizedBox(height: 14),
              if (c == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(Icons.play_arrow_rounded,
                        size: 20, color: cs.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text('Reprendre la qualification',
                        style: t.labelLarge
                            ?.copyWith(color: cs.onPrimaryContainer)),
                  ]),
                )
              else ...[
                CategoryBadge(c.category, dense: true),
                const SizedBox(height: 16),
                MiniLine(stations: stationsOf(project, now)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${progress.done} démarche${progress.done > 1 ? 's' : ''} '
                      'sur ${progress.total}',
                      style: t.labelMedium?.copyWith(color: tones.muted),
                    ),
                    const Spacer(),
                    if (overdue > 0)
                      Text(
                        overdue == 1 ? '1 en retard' : '$overdue en retard',
                        style: t.labelMedium?.copyWith(
                          color: tones.overdue,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (next != null)
                      Text('Échéance le ${formatDate(next.due)}',
                          style: t.labelMedium?.copyWith(color: tones.muted)),
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
  void initState() {
    super.initState();
    // Écoute directe des contrôleurs : fiable aussi avec la saisie prédictive
    // et la dictée des claviers mobiles dans le navigateur.
    _title.addListener(_refresh);
    _acronym.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

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
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);
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
          Text('Nouvelle recherche', style: t.headlineSmall),
          const SizedBox(height: 6),
          Text('L\'acronyme ou le titre suffit pour commencer.',
              style: t.bodyMedium?.copyWith(color: tones.muted)),
          const SizedBox(height: 20),
          TextField(
            controller: _acronym,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            style: t.titleMedium,
            decoration: const InputDecoration(
              labelText: 'Acronyme',
              hintText: 'Ex. CAMPANILE',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Titre de l\'étude'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sponsor,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Promoteur',
              helperText: 'Facultatif : DRCI, établissement, industriel…',
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _valid && !_busy ? _submit : null,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
            label: const Text('Qualifier la recherche'),
          ),
        ],
      ),
    );
  }
}
