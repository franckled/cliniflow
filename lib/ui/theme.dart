import 'package:flutter/material.dart';

import '../engine/engine.dart';

/// Encre profonde et teintes minérales : sobre, lisible au bloc comme au bureau.
const _ink = Color(0xFF12324A);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _ink,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 1,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
  );
}

/// Couleur d'accent par famille de recherche, lisible en clair et en sombre.
Color familyColor(CategoryFamily f, Brightness b) {
  final light = b == Brightness.light;
  return switch (f) {
    CategoryFamily.high => light ? const Color(0xFFB3261E) : const Color(0xFFFFB4AB),
    CategoryFamily.medium => light ? const Color(0xFF9A5B00) : const Color(0xFFFFB95C),
    CategoryFamily.low => light ? const Color(0xFF2E6B3A) : const Color(0xFF95D5A0),
    CategoryFamily.drug => light ? const Color(0xFF6A3FA0) : const Color(0xFFD7BAFF),
    CategoryFamily.device => light ? const Color(0xFF00658E) : const Color(0xFF8BCEFF),
    CategoryFamily.data => light ? const Color(0xFF4A5A6A) : const Color(0xFFB9C8DA),
    CategoryFamily.neutral => light ? const Color(0xFF5F5E62) : const Color(0xFFC8C6CA),
  };
}

IconData familyIcon(CategoryFamily f) => switch (f) {
      CategoryFamily.high => Icons.health_and_safety_outlined,
      CategoryFamily.medium => Icons.biotech_outlined,
      CategoryFamily.low => Icons.visibility_outlined,
      CategoryFamily.drug => Icons.medication_outlined,
      CategoryFamily.device => Icons.memory_outlined,
      CategoryFamily.data => Icons.dataset_outlined,
      CategoryFamily.neutral => Icons.fact_check_outlined,
    };

/// Pastille de catégorie réutilisée dans les listes et les en-têtes.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key, this.dense = false});

  final ResearchCategory category;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = familyColor(category.family, Theme.of(context).brightness);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(familyIcon(category.family), size: dense ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              category.label,
              overflow: TextOverflow.ellipsis,
              style: (dense
                      ? Theme.of(context).textTheme.labelMedium
                      : Theme.of(context).textTheme.labelLarge)
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
