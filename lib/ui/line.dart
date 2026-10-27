import 'package:flutter/material.dart';

import '../data/project.dart';
import '../engine/engine.dart';
import 'theme.dart';

/// État visuel d'un arrêt sur la ligne.
enum StopState { todo, pending, done, skipped, overdue }

StopState stopStateOf(StepTracking t, DateTime now) {
  if (t.isOverdue(now)) return StopState.overdue;
  return switch (t.status) {
    StepStatus.todo => StopState.todo,
    StepStatus.inProgress => StopState.pending,
    StepStatus.done => StopState.done,
    StepStatus.notApplicable => StopState.skipped,
  };
}

bool _passed(StopState s) => s == StopState.done || s == StopState.skipped;

// ─── Nœuds ─────────────────────────────────────────────────────────────────

/// Un arrêt (démarche) : anneau, point, ou pastille cochée.
class StopNode extends StatelessWidget {
  const StopNode(this.state, {super.key, this.size = 18});

  final StopState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tones = Tones.of(context);
    final surface = Theme.of(context).colorScheme.surface;
    final s = size;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: s,
      height: s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (state) {
          StopState.done => tones.done,
          StopState.skipped => tones.line,
          _ => surface,
        },
        border: switch (state) {
          StopState.todo => Border.all(color: tones.muted, width: 2),
          StopState.pending => Border.all(color: tones.pending, width: 3),
          StopState.overdue => Border.all(color: tones.overdue, width: 3),
          StopState.done || StopState.skipped => null,
        },
      ),
      child: switch (state) {
        StopState.done =>
          Icon(Icons.check_rounded, size: s * 0.7, color: surface),
        StopState.skipped =>
          Icon(Icons.remove_rounded, size: s * 0.7, color: tones.muted),
        StopState.pending => Center(
            child: Container(
              width: s * 0.3,
              height: s * 0.3,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: tones.pending),
            ),
          ),
        StopState.overdue => Icon(Icons.priority_high_rounded,
            size: s * 0.6, color: tones.overdue),
        StopState.todo => null,
      },
    );
  }
}

/// Une station (phase) : gros anneau, plein quand la phase est soldée.
class StationNode extends StatelessWidget {
  const StationNode({super.key, required this.complete, this.size = 26});

  final bool complete;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tones = Tones.of(context);
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: complete ? tones.done : cs.surface,
        border: Border.all(
          color: complete ? tones.done : cs.onSurface,
          width: 4,
        ),
      ),
      child: complete
          ? Icon(Icons.check_rounded, size: size * 0.6, color: cs.surface)
          : null,
    );
  }
}

// ─── Ligne verticale ───────────────────────────────────────────────────────

const _gutter = 48.0;
const _lineWidth = 4.0;

/// Une rangée de la ligne : la gouttière dessine le tronçon entrant (au-dessus
/// du nœud) et sortant (en dessous), puis le nœud, aligné sur la première ligne
/// de texte.
class LineRow extends StatelessWidget {
  const LineRow({
    super.key,
    required this.node,
    required this.nodeSize,
    required this.child,
    this.incoming,
    this.outgoing,
    this.nodeTop = 2,
    this.onNodeTap,
    this.nodeTooltip,
  });

  final Widget node;
  final double nodeSize;
  final Widget child;

  /// Couleur des tronçons ; `null` = pas de tronçon (extrémité).
  final Color? incoming;
  final Color? outgoing;
  final double nodeTop;
  final VoidCallback? onNodeTap;
  final String? nodeTooltip;

  @override
  Widget build(BuildContext context) {
    final center = nodeTop + nodeSize / 2;
    Widget n = SizedBox.square(dimension: nodeSize, child: node);
    if (onNodeTap != null) {
      n = Tooltip(
        message: nodeTooltip ?? '',
        child: InkResponse(
          onTap: onNodeTap,
          radius: 26,
          child: Padding(padding: const EdgeInsets.all(2), child: n),
        ),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _gutter,
            child: CustomPaint(
              painter: _SegmentPainter(
                incoming: incoming,
                outgoing: outgoing,
                center: center + (onNodeTap != null ? 2 : 0),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(padding: EdgeInsets.only(top: nodeTop), child: n),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  _SegmentPainter({this.incoming, this.outgoing, required this.center});

  final Color? incoming;
  final Color? outgoing;
  final double center;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final p = Paint()
      ..strokeWidth = _lineWidth
      ..strokeCap = StrokeCap.butt;
    if (incoming != null) {
      canvas.drawLine(Offset(x, 0), Offset(x, center), p..color = incoming!);
    }
    if (outgoing != null) {
      canvas.drawLine(
          Offset(x, center), Offset(x, size.height), p..color = outgoing!);
    }
  }

  @override
  bool shouldRepaint(_SegmentPainter old) =>
      old.incoming != incoming ||
      old.outgoing != outgoing ||
      old.center != center;
}

/// Modèle d'affichage d'une ligne complète : stations et arrêts, à plat.
sealed class LineItem {}

class StationItem extends LineItem {
  StationItem(this.phase, this.stops);
  final Phase phase;
  final List<StopItem> stops;
  bool get complete => stops.every((s) => _passed(s.state));
  int get passedCount => stops.where((s) => _passed(s.state)).length;
}

class StopItem extends LineItem {
  StopItem(this.step, this.tracking, this.state);
  final RegulatoryStep step;
  final StepTracking tracking;
  final StopState state;
  bool get passed => _passed(state);
}

/// Regroupe les étapes d'un projet en stations, dans l'ordre des phases.
List<StationItem> stationsOf(Project p, DateTime now) {
  final by = <Phase, List<StopItem>>{};
  for (final s in p.steps) {
    final t = p.trackingFor(s.id);
    (by[s.phase] ??= []).add(StopItem(s, t, stopStateOf(t, now)));
  }
  return [
    for (final ph in Phase.values)
      if (by[ph] case final stops?) StationItem(ph, stops),
  ];
}

// ─── Miniatures ────────────────────────────────────────────────────────────

/// La ligne en miniature, horizontale : une station par phase, remplie à
/// mesure de l'avancement. Sert sur les cartes de l'accueil.
class MiniLine extends StatelessWidget {
  const MiniLine({super.key, required this.stations});

  final List<StationItem> stations;

  @override
  Widget build(BuildContext context) {
    final tones = Tones.of(context);
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 16,
      child: CustomPaint(
        painter: _MiniLinePainter(
          ratios: [
            for (final s in stations)
              s.stops.isEmpty ? 1.0 : s.passedCount / s.stops.length,
          ],
          done: tones.done,
          line: tones.line,
          ring: cs.onSurface,
          surface: Tones.of(context).raised,
        ),
        size: const Size(double.infinity, 16),
      ),
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  _MiniLinePainter({
    required this.ratios,
    required this.done,
    required this.line,
    required this.ring,
    required this.surface,
  });

  final List<double> ratios;
  final Color done, line, ring, surface;

  @override
  void paint(Canvas canvas, Size size) {
    if (ratios.isEmpty) return;
    const r = 6.0;
    final y = size.height / 2;
    final n = ratios.length;
    final step = n == 1 ? 0.0 : (size.width - 2 * r) / (n - 1);
    final xs = [for (var i = 0; i < n; i++) r + i * step];
    final stroke = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Tronçons : parcourus si la station de départ est soldée ; sinon, la
    // part déjà faite de la station suivante colore le début du tronçon.
    for (var i = 0; i < n - 1; i++) {
      final a = xs[i] + r, b = xs[i + 1] - r;
      canvas.drawLine(Offset(a, y), Offset(b, y), stroke..color = line);
      final fill = ratios[i] >= 1 ? 1.0 : 0.0;
      if (fill > 0) {
        canvas.drawLine(Offset(a, y), Offset(b, y), stroke..color = done);
      }
    }
    for (var i = 0; i < n; i++) {
      final c = Offset(xs[i], y);
      final ratio = ratios[i];
      canvas.drawCircle(c, r, Paint()..color = surface);
      if (ratio >= 1) {
        canvas.drawCircle(c, r, Paint()..color = done);
      } else {
        if (ratio > 0) {
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: r),
            -1.5708,
            6.2832 * ratio,
            true,
            Paint()..color = done,
          );
        }
        canvas.drawCircle(
          c,
          r - 1,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = ratio > 0 ? done : ring.withValues(alpha: 0.55),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MiniLinePainter old) =>
      old.done != done ||
      old.line != line ||
      old.ratios.length != ratios.length ||
      [for (var i = 0; i < ratios.length; i++) old.ratios[i] != ratios[i]]
          .contains(true);
}

/// Fil d'avancement du questionnaire : un point par question visible.
class QuestionTrail extends StatelessWidget {
  const QuestionTrail({super.key, required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final tones = Tones.of(context);
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Question ${current + 1} sur $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 3,
                  color: i <= current ? cs.onSurface : tones.line,
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              width: i == current ? 16 : 9,
              height: i == current ? 16 : 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < current
                    ? cs.onSurface
                    : (i == current ? cs.surface : tones.line),
                border: i == current
                    ? Border.all(color: tones.done, width: 4)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
