import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the Material 3 theme from the Sonar tokens (SX-901).
ThemeData buildSonarTheme(SonarTokens tokens, Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: tokens.primary,
    brightness: brightness,
  ).copyWith(
    primary: tokens.primary,
    onPrimary: tokens.onPrimary,
    secondary: tokens.accent,
    onSecondary: tokens.base,
    surface: tokens.base,
    onSurface: tokens.text,
    surfaceContainerHighest: tokens.raised,
    onSurfaceVariant: tokens.secondaryText,
    error: tokens.danger,
    outline: tokens.secondaryText.withValues(alpha: 0.4),
  );

  final TextTheme textTheme = TextTheme(
    displaySmall: SxType.display.copyWith(color: tokens.text),
    headlineSmall: SxType.title.copyWith(color: tokens.text),
    titleLarge: SxType.title.copyWith(color: tokens.text),
    titleMedium: SxType.body.copyWith(
      color: tokens.text,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: SxType.body.copyWith(color: tokens.text),
    bodyMedium: SxType.body.copyWith(color: tokens.text),
    bodySmall: SxType.caption.copyWith(color: tokens.secondaryText),
    labelLarge: SxType.label.copyWith(color: tokens.text),
    labelMedium: SxType.label.copyWith(color: tokens.secondaryText),
    labelSmall: SxType.caption.copyWith(color: tokens.secondaryText),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.base,
    canvasColor: tokens.base,
    fontFamily: 'Readex',
    textTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[tokens],
    dividerColor: tokens.raised,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.base,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: SxType.title.copyWith(color: tokens.text),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        minimumSize: const Size(64, 48),
        textStyle: SxType.label.copyWith(
          color: tokens.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(SxRadius.pill),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.primary,
        minimumSize: const Size(48, 48),
        textStyle: SxType.label,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.raised,
      hintStyle: SxType.body.copyWith(color: tokens.secondaryText),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SxSpace.x4,
        vertical: SxSpace.x3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SxRadius.input),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SxRadius.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(SxRadius.input),
        borderSide: BorderSide(color: tokens.primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.raised,
      surfaceTintColor: Colors.transparent,
      indicatorColor: tokens.primary.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll<TextStyle>(
        SxType.label.copyWith(fontSize: 12, color: tokens.text),
      ),
      iconTheme: WidgetStatePropertyAll<IconThemeData>(
        IconThemeData(color: tokens.text, size: 24),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: tokens.raised,
      indicatorColor: tokens.primary.withValues(alpha: 0.18),
      selectedIconTheme: IconThemeData(color: tokens.primary),
      unselectedIconTheme: IconThemeData(color: tokens.secondaryText),
      selectedLabelTextStyle: SxType.label.copyWith(color: tokens.text),
      unselectedLabelTextStyle: SxType.label.copyWith(
        color: tokens.secondaryText,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.raised,
      contentTextStyle: SxType.body.copyWith(color: tokens.text),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.raised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(SxRadius.sheet)),
      ),
      titleTextStyle: SxType.title.copyWith(color: tokens.text),
      contentTextStyle: SxType.body.copyWith(color: tokens.text),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.raised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SxRadius.sheet),
        ),
      ),
    ),
  );
}
