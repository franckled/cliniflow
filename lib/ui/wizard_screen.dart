import 'package:flutter/material.dart';

import '../data/project_store.dart';
import '../engine/engine.dart';

/// Questionnaire de qualification, une question par écran.
/// Retourne `true` au `pop` si la qualification est terminée.
class WizardScreen extends StatefulWidget {
  const WizardScreen({super.key, required this.store, required this.projectId});

  final ProjectStore store;
  final String projectId;

  @override
  State<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends State<WizardScreen> {
  late Answers _answers;
  int _index = 0;

  /// Sélection en cours pour une question à choix multiples.
  Set<String> _draft = {};

  @override
  void initState() {
    super.initState();
    final p = widget.store.byId(widget.projectId);
    _answers = {
      for (final e in (p?.answers ?? const <String, Set<String>>{}).entries)
        e.key: {...e.value},
    };
    // Reprend à la première question sans réponse.
    final visible = visibleQuestions(_answers);
    final firstOpen = visible.indexWhere((q) => !_answers.containsKey(q.id));
    _index = firstOpen < 0 ? 0 : firstOpen;
    _loadDraft();
  }

  List<Question> get _visible => visibleQuestions(_answers);
  Question get _current => _visible[_index];

  void _loadDraft() {
    final q = _visible[_index];
    _draft = {...?_answers[q.id]};
  }

  Future<void> _persist() async {
    final p = widget.store.byId(widget.projectId);
    if (p != null) await widget.store.update(p.copyWith(answers: _answers));
  }

  Future<void> _answer(Set<String> value) async {
    final q = _current;
    setState(() {
      _answers = pruneAnswers({..._answers, q.id: value});
    });
    await _persist();
    if (!mounted) return;
    final visible = _visible;
    final pos = visible.indexWhere((x) => x.id == q.id);
    final nextOpen = visible.indexWhere(
      (x) => !_answers.containsKey(x.id),
      pos + 1,
    );
    if (nextOpen >= 0) {
      setState(() {
        _index = nextOpen;
        _loadDraft();
      });
    } else if (pos + 1 < visible.length) {
      setState(() {
        _index = pos + 1;
        _loadDraft();
      });
    } else if (isComplete(_answers)) {
      Navigator.of(context).pop(true);
    }
  }

  void _back() {
    if (_index == 0) {
      Navigator.of(context).pop(isComplete(_answers));
      return;
    }
    setState(() {
      _index--;
      _loadDraft();
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _current;
    final visible = _visible;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final selected = _answers[q.id];
    final complete = isComplete(_answers);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(complete);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(complete),
          ),
          title: const Text('Qualification'),
          actions: [
            if (complete)
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Résultat'),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: (_index + 1) / visible.length,
              minHeight: 4,
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: ListView(
              key: ValueKey(q.id),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Text(
                  'Question ${_index + 1} sur ${visible.length}',
                  style: t.labelLarge?.copyWith(color: cs.primary),
                ),
                const SizedBox(height: 8),
                Text(q.title,
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    )),
                if (q.help != null) ...[
                  const SizedBox(height: 12),
                  Text(q.help!,
                      style: t.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      )),
                ],
                const SizedBox(height: 20),
                for (final c in q.choices) ...[
                  _ChoiceTile(
                    choice: c,
                    multiple: q.multiple,
                    selected: q.multiple
                        ? _draft.contains(c.id)
                        : (selected?.contains(c.id) ?? false),
                    onTap: () {
                      if (q.multiple) {
                        setState(() {
                          _draft.contains(c.id)
                              ? _draft.remove(c.id)
                              : _draft.add(c.id);
                        });
                      } else {
                        _answer({c.id});
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
              ),
              const Spacer(),
              if (q.multiple)
                FilledButton(
                  onPressed: () => _answer({..._draft}),
                  child: Text(_draft.isEmpty ? 'Aucune, continuer' : 'Continuer'),
                )
              else if (selected != null)
                FilledButton.tonal(
                  onPressed: () => _answer(selected),
                  child: const Text('Suivant'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.choice,
    required this.multiple,
    required this.selected,
    required this.onTap,
  });

  final Choice choice;
  final bool multiple;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  multiple
                      ? (selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)
                      : (selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(choice.label,
                          style: t.bodyLarge?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? cs.onPrimaryContainer
                                : cs.onSurface,
                          )),
                      if (choice.hint != null) ...[
                        const SizedBox(height: 4),
                        Text(choice.hint!,
                            style: t.bodySmall?.copyWith(
                              color: selected
                                  ? cs.onPrimaryContainer
                                  : cs.onSurfaceVariant,
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
