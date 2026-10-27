import 'package:flutter/material.dart';

import 'theme.dart';

/// Auteur et structure de rattachement, affichés sur les pages principales
/// et en pied de page de la fiche PDF.
abstract final class Credit {
  static const author = 'Dr Franck LE DUFF';
  static const structure =
      'Centre Hospitalier de Bastia – Unité de Recherche Clinique';
  static const oneLine = '$author – $structure';
}

/// Mention d'auteur, discrète, en bas de page.
class CreditLine extends StatelessWidget {
  const CreditLine({super.key, this.padding = const EdgeInsets.only(top: 28)});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tones = Tones.of(context);
    return Padding(
      padding: padding,
      child: Semantics(
        label: Credit.oneLine,
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 34,
              margin: const EdgeInsets.only(top: 2, right: 12),
              decoration: BoxDecoration(
                color: tones.done,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Credit.author,
                      style: t.labelLarge?.copyWith(color: tones.muted)),
                  const SizedBox(height: 2),
                  Text(Credit.structure,
                      style: t.bodySmall?.copyWith(color: tones.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
