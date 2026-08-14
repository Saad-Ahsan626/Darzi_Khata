import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design Tokens (Colors)
  static const Color charcoalThread = Color(0xFF2B2E33);
  static const Color tailorChalk = Color(0xFFF7F5F0);
  static const Color chalkDeep = Color(0xFFF2EFE8);
  static const Color brassTape = Color(0xFFB8863B);
  static const Color stitchNavy = Color(0xFF1F3B4D);
  static const Color seamRed = Color(0xFFA63D40);
  static const Color fabricGrey = Color(0xFFD8D3C9);
  static const Color inkMuted = Color(0xFF8A8578);
  static const Color inkSoft = Color(0xFF5A5C60);
  static const Color ghost = Color(0xFFA8A49A);
  static const Color greenOk = Color(0xFF1A7A3F);
  static const Color whatsapp = Color(0xFF25D366);

  // Status Background Tints (~12% opacity)
  static const Color navyStatusBg = Color(0xFFE7EDF1);
  static const Color brassStatusBg = Color(0xFFF3E9D6);
  static const Color greenStatusBg = Color(0xFFDFF0E4);
  static const Color greyStatusBg = Color(0xFFECECEA);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: tailorChalk,
      primaryColor: charcoalThread,
      colorScheme: const ColorScheme.light(
        primary: charcoalThread,
        secondary: brassTape,
        error: seamRed,
        surface: Colors.white,
      ),
      textTheme: TextTheme(
        // Display / headers (Zilla Slab)
        displayLarge: GoogleFonts.zillaSlab(
          color: charcoalThread,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.zillaSlab(
          color: charcoalThread,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.zillaSlab(
          color: charcoalThread,
          fontWeight: FontWeight.w500,
        ),
        headlineMedium: GoogleFonts.zillaSlab(
          color: charcoalThread,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.zillaSlab(
          color: charcoalThread,
          fontWeight: FontWeight.w600,
        ),

        // Body / UI (Noto Sans)
        bodyLarge: GoogleFonts.notoSans(
          color: charcoalThread,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.notoSans(
          color: charcoalThread,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.notoSans(
          color: charcoalThread,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: GoogleFonts.notoSans(
          color: inkMuted,
          fontWeight: FontWeight.w400,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: charcoalThread,
        foregroundColor: tailorChalk,
        titleTextStyle: GoogleFonts.zillaSlab(
          color: tailorChalk,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: brassTape),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: fabricGrey, width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brassTape,
        foregroundColor: charcoalThread,
        elevation: 8, // ~ 0 8px 20px rgba(184,134,59,.45)
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: brassTape,
        unselectedItemColor: inkMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: fabricGrey, thickness: 1),
    );
  }

  // Helper text styles that are specific (Roboto Mono for data/numbers)
  static TextStyle get numberStyle => GoogleFonts.robotoMono(
    color: charcoalThread,
    fontWeight: FontWeight.w500,
  );

  // Helper text style for Urdu (Noto Nastaliq Urdu)
  static TextStyle get urduStyle => GoogleFonts.notoNastaliqUrdu(
    color: charcoalThread,
    fontWeight: FontWeight.w400,
  );
}
