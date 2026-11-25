import 'package:flutter/material.dart';

/// AutoIntel visual system: a dark instrument-panel surface with amber
/// highlights. Amber is reserved for actions and live status so it stays rare.
class AppColors {
  static const ink = Color(0xFF0E1114);
  static const panel = Color(0xFF171C21);
  static const raised = Color(0xFF20272E);
  static const line = Color(0xFF2C353E);
  static const amber = Color(0xFFE8A23A);
  static const amberDeep = Color(0xFFB87414);
  static const onAmber = Color(0xFF1A1204);
  static const text = Color(0xFFF4F1EA);
  static const muted = Color(0xFF9AA3AD);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.amber,
    onPrimary: AppColors.onAmber,
    primaryContainer: Color(0xFF3A2A10),
    onPrimaryContainer: Color(0xFFF6D7A4),
    secondary: Color(0xFF8FB4C8),
    onSecondary: Color(0xFF0B1A22),
    surface: AppColors.ink,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.muted,
    surfaceContainerHighest: AppColors.raised,
    surfaceContainerHigh: AppColors.panel,
    outline: AppColors.line,
    outlineVariant: Color(0xFF3A444E),
    error: Color(0xFFE06A5A),
    onError: Color(0xFF2A0C08),
    errorContainer: Color(0xFF3D1B16),
    onErrorContainer: Color(0xFFF6C8C2),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.panel,
      indicatorColor: AppColors.amber.withOpacity(0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.amber : AppColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.amber : AppColors.muted,
          size: 22,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.onAmber,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.amber,
      foregroundColor: AppColors.onAmber,
      elevation: 0,
    ),
  );
}
