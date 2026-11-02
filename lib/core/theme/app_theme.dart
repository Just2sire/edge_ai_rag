import 'package:flutter/material.dart';

/// Central color palette of the application.
///
/// The identity is built around warm ivory, deep ink and a golden accent
/// that echoes the original brand color while staying readable in both
/// light and dark modes.
abstract final class AppColors {
  static const Color ink = Color(0xFF16181D);
  static const Color inkSoft = Color(0xFF2A2D36);
  static const Color ivory = Color(0xFFFBF8F1);
  static const Color parchment = Color(0xFFFFFDF8);
  static const Color gold = Color(0xFFF2C14E);
  static const Color goldDeep = Color(0xFFB08300);
  static const Color goldSoft = Color(0xFFFFF0C2);
  static const Color night = Color(0xFF0C0D11);
  static const Color nightSurface = Color(0xFF14161C);
  static const Color nightSurfaceHigh = Color(0xFF1D2028);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD873), gold, Color(0xFFE0A21B)],
  );
}

/// Builds the light and dark [ThemeData] used across the application.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme, Brightness.light);

  static ThemeData get dark => _build(_darkScheme, Brightness.dark);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.ink,
    onPrimary: const Color(0xFFFFF8E7),
    primaryContainer: const Color(0xFFFFE9A8),
    onPrimaryContainer: const Color(0xFF2C2300),
    secondary: const Color(0xFF7A5C00),
    onSecondary: Colors.white,
    secondaryContainer: AppColors.goldSoft,
    onSecondaryContainer: const Color(0xFF3A2D00),
    tertiary: const Color(0xFF4C6350),
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFCFE8D1),
    onTertiaryContainer: const Color(0xFF0A2012),
    surface: AppColors.ivory,
    onSurface: AppColors.ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.parchment,
    surfaceContainer: const Color(0xFFF4F0E6),
    surfaceContainerHigh: const Color(0xFFEDE7DA),
    surfaceContainerHighest: const Color(0xFFE6DFCF),
    onSurfaceVariant: const Color(0xFF5D5A52),
    outline: const Color(0xFF8B8678),
    outlineVariant: const Color(0xFFE1DACA),
    inverseSurface: const Color(0xFF23252C),
    onInverseSurface: const Color(0xFFF5F1E8),
    inversePrimary: AppColors.gold,
    error: const Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: const Color(0xFFF9DEDC),
    onErrorContainer: const Color(0xFF410E0B),
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.gold,
    onPrimary: const Color(0xFF241B00),
    primaryContainer: const Color(0xFF3D2F00),
    onPrimaryContainer: const Color(0xFFFFE9A8),
    secondary: const Color(0xFFE7C56A),
    onSecondary: const Color(0xFF3A2D00),
    secondaryContainer: const Color(0xFF4A3A00),
    onSecondaryContainer: const Color(0xFFFFE9A8),
    tertiary: const Color(0xFF9ED3A4),
    onTertiary: const Color(0xFF0A2012),
    tertiaryContainer: const Color(0xFF2C4A32),
    onTertiaryContainer: const Color(0xFFCFE8D1),
    surface: AppColors.night,
    onSurface: const Color(0xFFF4F0E6),
    surfaceContainerLowest: const Color(0xFF08090C),
    surfaceContainerLow: AppColors.nightSurface,
    surfaceContainer: const Color(0xFF191B22),
    surfaceContainerHigh: AppColors.nightSurfaceHigh,
    surfaceContainerHighest: const Color(0xFF262933),
    onSurfaceVariant: const Color(0xFFB9B4A6),
    outline: const Color(0xFF6E6A60),
    outlineVariant: const Color(0xFF2C2F38),
    inverseSurface: const Color(0xFFF4F0E6),
    onInverseSurface: const Color(0xFF23252C),
    inversePrimary: AppColors.ink,
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
  );

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(scheme);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 72,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 19),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
        actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide:
              BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : Colors.white,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? scheme.surfaceContainerHighest : scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? scheme.onSurface : scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 4,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.48),
        showDragHandle: false,
        constraints: const BoxConstraints(maxWidth: 760),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 24,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        overlayColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.04),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? scheme.surfaceContainerHigh : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        collapsedIconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        collapsedTextColor: scheme.onSurface,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.secondaryContainer,
        textColor: scheme.onSecondaryContainer,
        smallSize: 8,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.2),
        selectionHandleColor: scheme.primary,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = Typography.material2021().black.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 15, height: 1.55),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, height: 1.45),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
