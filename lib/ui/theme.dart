import 'package:flutter/material.dart';

import '../engine/engine.dart';

/// Identité visuelle CliniFlow.
///
/// Un seul parti pris : le parcours réglementaire se lit comme une ligne de
/// transport (stations = phases, arrêts = démarches). Tout le reste reste
/// sobre — encre, papier froid, une couleur « menthe » pour ce qui est fait.
/// Police : Atkinson Hyperlegible Next, dessinée pour la lisibilité.
abstract final class Palette {
  // Clair
  static const ink = Color(0xFF12324A);
  static const paper = Color(0xFFF2F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const slate = Color(0xFF5B6B78);
  static const rule = Color(0xFFD6DEE4);
  static const mint = Color(0xFF1F8F78);
  static const mintSoft = Color(0xFFD7F1EB);
  static const amber = Color(0xFFB86E00);
  static const alert = Color(0xFFB3261E);

  // Sombre
  static const night = Color(0xFF0D1C27);
  static const nightSurface = Color(0xFF13283A);
  static const nightRaised = Color(0xFF1A3348);
  static const mist = Color(0xFFE4ECF1);
  static const nightSlate = Color(0xFF9CB0BF);
  static const nightRule = Color(0xFF2A4458);
  static const mintBright = Color(0xFF7ED6C5);
  static const amberBright = Color(0xFFFFB95C);
  static const alertBright = Color(0xFFFFB4AB);
}

const fontFamily = 'Atkinson';

/// Couleurs sémantiques non couvertes par le ColorScheme Material.
@immutable
class Tones extends ThemeExtension<Tones> {
  const Tones({
    required this.done,
    required this.doneSoft,
    required this.pending,
    required this.overdue,
    required this.line,
    required this.muted,
    required this.raised,
  });

  /// Démarche faite, ligne parcourue.
  final Color done;
  final Color doneSoft;

  /// Démarche en cours.
  final Color pending;
  final Color overdue;

  /// Ligne non encore parcourue, filets.
  final Color line;

  /// Texte secondaire.
  final Color muted;

  /// Surface légèrement en relief.
  final Color raised;

  static Tones of(BuildContext context) =>
      Theme.of(context).extension<Tones>()!;

  @override
  Tones copyWith() => this;

  @override
  Tones lerp(Tones? other, double t) {
    if (other == null) return this;
    return Tones(
      done: Color.lerp(done, other.done, t)!,
      doneSoft: Color.lerp(doneSoft, other.doneSoft, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      line: Color.lerp(line, other.line, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: light ? Palette.ink : Palette.mintBright,
    onPrimary: light ? Colors.white : Palette.night,
    primaryContainer: light ? const Color(0xFFDDE7EF) : Palette.nightRaised,
    onPrimaryContainer: light ? Palette.ink : Palette.mist,
    secondary: light ? Palette.mint : Palette.mintBright,
    onSecondary: light ? Colors.white : Palette.night,
    secondaryContainer: light ? Palette.mintSoft : const Color(0xFF1C4A44),
    onSecondaryContainer: light ? const Color(0xFF0B4A3E) : Palette.mist,
    tertiary: light ? Palette.amber : Palette.amberBright,
    onTertiary: light ? Colors.white : Palette.night,
    error: light ? Palette.alert : Palette.alertBright,
    onError: light ? Colors.white : Palette.night,
    surface: light ? Palette.paper : Palette.night,
    onSurface: light ? Palette.ink : Palette.mist,
    onSurfaceVariant: light ? Palette.slate : Palette.nightSlate,
    surfaceContainerLowest: light ? Palette.surface : Palette.night,
    surfaceContainerLow: light ? Palette.surface : Palette.nightSurface,
    surfaceContainer: light ? Palette.surface : Palette.nightSurface,
    surfaceContainerHigh: light ? const Color(0xFFE9EEF2) : Palette.nightRaised,
    surfaceContainerHighest:
        light ? const Color(0xFFE1E8ED) : const Color(0xFF223D53),
    outline: light ? const Color(0xFF9AAAB6) : const Color(0xFF5C768A),
    outlineVariant: light ? Palette.rule : Palette.nightRule,
    inverseSurface: light ? Palette.ink : Palette.mist,
    onInverseSurface: light ? Colors.white : Palette.night,
  );

  final tones = Tones(
    done: light ? Palette.mint : Palette.mintBright,
    doneSoft: light ? Palette.mintSoft : const Color(0xFF1C4A44),
    pending: light ? Palette.amber : Palette.amberBright,
    overdue: light ? Palette.alert : Palette.alertBright,
    line: light ? Palette.rule : Palette.nightRule,
    muted: light ? Palette.slate : Palette.nightSlate,
    raised: light ? Palette.surface : Palette.nightSurface,
  );

  final text = _textTheme(scheme.onSurface);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: fontFamily,
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [tones],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: tones.raised,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tones.raised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: text.titleSmall,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: scheme.outline),
        textStyle: text.titleSmall,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: text.labelLarge),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      highlightElevation: 4,
      extendedTextStyle: text.titleSmall,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: text.titleSmall,
      unselectedLabelStyle: text.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: tones.done,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: scheme.outlineVariant,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tones.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(text.labelMedium),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tones.done,
      linearTrackColor: tones.line,
    ),
  );
}

/// Échelle typographique (ratio ≈ 1,2), interlignage généreux pour le corps.
TextTheme _textTheme(Color ink) {
  TextStyle s(double size, FontWeight w, {double h = 1.25, double ls = 0}) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: w,
        height: h,
        letterSpacing: ls,
        color: ink,
      );
  return TextTheme(
    displaySmall: s(34, FontWeight.w800, h: 1.1, ls: -0.6),
    headlineMedium: s(28, FontWeight.w800, h: 1.15, ls: -0.4),
    headlineSmall: s(24, FontWeight.w700, h: 1.2, ls: -0.3),
    titleLarge: s(20, FontWeight.w700, ls: -0.2),
    titleMedium: s(17, FontWeight.w700),
    titleSmall: s(15, FontWeight.w700),
    bodyLarge: s(16.5, FontWeight.w400, h: 1.45),
    bodyMedium: s(15, FontWeight.w400, h: 1.45),
    bodySmall: s(13, FontWeight.w400, h: 1.4),
    labelLarge: s(14.5, FontWeight.w700),
    labelMedium: s(13, FontWeight.w500),
    labelSmall: s(12, FontWeight.w500, ls: 0.1),
  );
}

/// Couleur d'une famille de recherche, lisible en clair et en sombre.
Color familyColor(CategoryFamily f, Brightness b) {
  final light = b == Brightness.light;
  return switch (f) {
    CategoryFamily.high =>
      light ? const Color(0xFFB3261E) : const Color(0xFFFFB4AB),
    CategoryFamily.medium =>
      light ? const Color(0xFF9A5B00) : const Color(0xFFFFB95C),
    CategoryFamily.low =>
      light ? const Color(0xFF2E6B3A) : const Color(0xFF95D5A0),
    CategoryFamily.drug =>
      light ? const Color(0xFF6A3FA0) : const Color(0xFFD7BAFF),
    CategoryFamily.device =>
      light ? const Color(0xFF00658E) : const Color(0xFF8BCEFF),
    CategoryFamily.data =>
      light ? const Color(0xFF3F5568) : const Color(0xFFB9C8DA),
    CategoryFamily.neutral =>
      light ? const Color(0xFF5F5E62) : const Color(0xFFC8C6CA),
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

/// Pastille de catégorie : couleur de la famille, sans bordure.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key, this.dense = false});

  final ResearchCategory category;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = familyColor(category.family, Theme.of(context).brightness);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(dense ? 8 : 10, 4, dense ? 10 : 12, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(familyIcon(category.family), size: dense ? 15 : 17, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              category.label,
              overflow: TextOverflow.ellipsis,
              style: (dense ? t.labelMedium : t.labelLarge)
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
