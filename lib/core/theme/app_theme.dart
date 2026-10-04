import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Material presentation theme. Domain and data code never depend on this.
abstract final class AppTheme {
  static final ThemeData lightTheme = _buildLightTheme();

  static TextStyle get numberStyle =>
      AppTypography.numberMd.copyWith(color: AppPalette.carbon);

  static ThemeData _buildLightTheme() {
    const scheme = ColorScheme.light(
      primary: AppPalette.carbon,
      onPrimary: AppPalette.white,
      primaryContainer: AppPalette.surfaceControl,
      onPrimaryContainer: AppPalette.carbon,
      secondary: AppPalette.greyOlive,
      onSecondary: AppPalette.carbon,
      secondaryContainer: AppPalette.surfaceControl,
      onSecondaryContainer: AppPalette.carbon,
      tertiary: AppPalette.oliveInk,
      onTertiary: AppPalette.white,
      tertiaryContainer: AppPalette.surfaceSunken,
      onTertiaryContainer: AppPalette.carbon,
      surface: AppPalette.white,
      onSurface: AppPalette.carbon,
      onSurfaceVariant: AppPalette.ink70,
      surfaceContainerLowest: AppPalette.white,
      surfaceContainerLow: AppPalette.surfaceSunken,
      surfaceContainer: AppPalette.surfaceControl,
      surfaceContainerHigh: AppPalette.surfaceControl,
      surfaceContainerHighest: AppPalette.surfaceControl,
      surfaceTint: AppPalette.white,
      error: AppPalette.carbon,
      onError: AppPalette.white,
      errorContainer: AppPalette.surfaceSunken,
      onErrorContainer: AppPalette.carbon,
      outline: AppPalette.lineStrong,
      outlineVariant: AppPalette.line,
      inverseSurface: AppPalette.carbon,
      onInverseSurface: AppPalette.white,
      inversePrimary: AppPalette.greyOlive,
      shadow: AppPalette.carbon,
      scrim: AppPalette.carbon,
    );

    final textTheme = TextTheme(
      displayLarge: AppTypography.display,
      displayMedium: AppTypography.display,
      displaySmall: AppTypography.display,
      headlineLarge: AppTypography.display,
      headlineMedium: AppTypography.screenTitle,
      headlineSmall: AppTypography.title,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      titleSmall: AppTypography.support.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.support,
      labelLarge: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
      labelMedium: AppTypography.support,
      labelSmall: AppTypography.micro,
    ).apply(bodyColor: AppPalette.carbon, displayColor: AppPalette.carbon);

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: const BorderSide(color: AppPalette.lineStrong),
    );
    const minControlSize = Size(AppSizing.minHitTarget, AppSizing.minHitTarget);
    final baseButton = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(minControlSize),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      shape: WidgetStatePropertyAll(controlShape),
      textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      animationDuration: AppMotion.selection,
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppPalette.white,
      canvasColor: AppPalette.white,
      disabledColor: AppPalette.ink45,
      focusColor: AppPalette.oliveFill14,
      hoverColor: AppPalette.oliveFill10,
      highlightColor: AppPalette.oliveFill10,
      splashColor: AppPalette.oliveFill14,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.white,
        foregroundColor: AppPalette.carbon,
        surfaceTintColor: AppPalette.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: AppPalette.carbon),
        actionsIconTheme: const IconThemeData(color: AppPalette.carbon),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.white,
        surfaceTintColor: AppPalette.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppPalette.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseButton.copyWith(
          elevation: const WidgetStatePropertyAll(0),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppPalette.surfaceControl
                : AppPalette.carbon,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppPalette.ink45
                : AppPalette.white,
          ),
          overlayColor: const WidgetStatePropertyAll(AppPalette.glassOnCarbon),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: baseButton.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppPalette.ink45
                : AppPalette.carbon,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? AppPalette.carbon
                  : AppPalette.lineStrong,
              width: states.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(AppPalette.oliveFill10),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: baseButton.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppPalette.ink45
                : AppPalette.carbon,
          ),
          overlayColor: const WidgetStatePropertyAll(AppPalette.oliveFill10),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(minControlSize),
          overlayColor: WidgetStatePropertyAll(AppPalette.oliveFill14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        labelStyle: AppTypography.support,
        floatingLabelStyle: AppTypography.support.copyWith(
          color: AppPalette.carbon,
        ),
        hintStyle: AppTypography.support,
        helperStyle: AppTypography.support,
        errorStyle: AppTypography.support.copyWith(color: AppPalette.carbon),
        errorMaxLines: 3,
        prefixIconColor: AppPalette.ink70,
        suffixIconColor: AppPalette.ink70,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppPalette.line),
        ),
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppPalette.carbon, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppPalette.carbon),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppPalette.carbon, width: 2),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppPalette.carbon,
        unselectedLabelColor: AppPalette.ink70,
        indicatorColor: AppPalette.carbon,
        dividerColor: AppPalette.line,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.bodyMedium,
        overlayColor: const WidgetStatePropertyAll(AppPalette.oliveFill10),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.white,
        surfaceTintColor: AppPalette.white,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
          side: const BorderSide(color: AppPalette.line),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.white,
        modalBackgroundColor: AppPalette.white,
        surfaceTintColor: AppPalette.white,
        dragHandleColor: AppPalette.lineStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.carbon,
        contentTextStyle: AppTypography.body.copyWith(color: AppPalette.white),
        actionTextColor: AppPalette.white,
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.carbon,
        foregroundColor: AppPalette.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.control)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppPalette.white,
        selectedItemColor: AppPalette.carbon,
        unselectedItemColor: AppPalette.ink70,
        selectedLabelStyle: AppTypography.support.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.support,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.carbon,
        linearTrackColor: AppPalette.surfaceControl,
        circularTrackColor: AppPalette.surfaceControl,
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.line,
        thickness: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppPalette.carbon,
        selectionColor: AppPalette.oliveFill14,
        selectionHandleColor: AppPalette.carbon,
      ),
    );
  }
}
