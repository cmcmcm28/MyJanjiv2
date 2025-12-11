import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Fintech Color Palette (inspired by template)
  static const Color primaryBlue = Color(0xFF0052D4); // Solid blue for buttons
  static const Color primaryStart = Color(0xFF0052D4);
  static const Color primaryMid = Color(0xFF4364F7);
  static const Color primaryEnd = Color(0xFF6FB1FC);
  static const Color backgroundGray = Color(0xFFF5F7FA);
  static const Color headerBlue = Color(0xFF1A237E);
  static const Color bodyGrey = Color(0xFF424242);
  static const Color secondaryColor = Color(0xFF9C27B0); // Purple for gradients
  static const Color lightBlue = Color(0xFFE3F2FD); // Light blue for gradient start
  static const Color lightPurple = Color(0xFFF3E5F5); // Light purple for gradient end

  // Background Gradient (Light Blue to Light Purple)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [lightBlue, lightPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Trust Gradient for Primary UI elements (cards, buttons)
  static const LinearGradient trustGradient = LinearGradient(
    colors: [primaryStart, primaryMid, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Purple Gradient for titles (like "Sign Up" in template)
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get theme {
    final textTheme = GoogleFonts.poppinsTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGray, // Off-White background
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryStart,
        primary: primaryStart,
        secondary: secondaryColor,
        surface: Colors.white, // Pure white for cards
      ),
      textTheme: textTheme.copyWith(
        // Headers: Bold, Dark Blue
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: headerBlue,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: headerBlue,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: headerBlue,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: headerBlue,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: headerBlue,
          fontWeight: FontWeight.w600,
        ),
        // Body Text: Dark Grey
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: bodyGrey,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: bodyGrey,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: bodyGrey,
        ),
      ),
      // AppBar Theme with gradient (will be applied manually via Container)
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: primaryStart,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      // Card Theme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Input Field Theme (Filled style)
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF0F2F5), // Very light grey
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      // Elevated Button Theme (Solid blue, rounded, white text)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue, // Solid blue background
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56), // Full width, height 56
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          elevation: 0, // No elevation for flat design
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // Clean Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Card decoration helper for consistent card styling (white, rounded, subtle shadow)
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16), // Rounded corners
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05), // Subtle shadow
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Input field decoration (white rounded rectangle with light grey fill)
  static BoxDecoration inputFieldDecoration = BoxDecoration(
    color: const Color(0xFFF0F2F5), // Light grey background fill
    borderRadius: BorderRadius.circular(12), // Rounded corners
  );

  // Pulse shadow for CTA buttons
  static List<BoxShadow> pulseShadow(Color color) {
    return [
      BoxShadow(
        color: color.withOpacity(0.3),
        blurRadius: 20,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: color.withOpacity(0.2),
        blurRadius: 10,
        spreadRadius: 1,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

