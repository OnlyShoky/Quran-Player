import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Defines the full light and dark [ThemeData] for the app.
abstract class AppTheme {
  static ThemeData light() {
    final base = _baseTheme(Brightness.light);
    return base;
  }

  static ThemeData dark() {
    final base = _baseTheme(Brightness.dark);
    return base;
  }

  static ThemeData _baseTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      onPrimary: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      primaryContainer: isDark ? const Color(0xFF2A4039) : const Color(0xFFCCDDD6),
      onPrimaryContainer: isDark ? AppColors.primaryDark : AppColors.primaryLight,
      secondary: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
      onSecondary: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      secondaryContainer: isDark ? const Color(0xFF3A2A18) : const Color(0xFFEEDDCC),
      onSecondaryContainer: isDark ? AppColors.secondaryDark : AppColors.secondaryLight,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
      surfaceContainerHighest: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
      outline: isDark ? AppColors.outlineDark : AppColors.outlineLight,
      error: isDark ? AppColors.errorDark : AppColors.errorLight,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF4A1A1A) : const Color(0xFFFFDAD6),
      onErrorContainer: isDark ? AppColors.errorDark : AppColors.errorLight,
    );

    final textTheme = GoogleFonts.latoTextTheme().copyWith(
      displayLarge: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w500),
    ).apply(
      bodyColor: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
      displayColor: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      dividerColor: isDark ? AppColors.outlineDark : AppColors.outlineLight,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.lato(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.badgeDark : AppColors.badgeLight,
        labelStyle: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        size: 22,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF3A3A34) : const Color(0xFF2C2C28),
        contentTextStyle: GoogleFonts.lato(color: Colors.white, fontSize: 14),
        actionTextColor: isDark ? AppColors.primaryDark : const Color(0xFF9FCFC0),
        showCloseIcon: true,
        closeIconColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: isDark ? AppColors.outlineDark : AppColors.outlineLight,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.1),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
    );
  }
}
