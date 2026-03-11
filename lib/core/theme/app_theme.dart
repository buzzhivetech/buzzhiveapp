import 'package:flutter/material.dart';

/// App theme (dashboard parity: primary amber, neutrals).
class AppTheme {
  AppTheme._();

  static const Color primaryAmber = Color(0xFFF59E0B);
  static const Color primaryAmberLight = Color(0xFFFBBF24);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAmber,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAmber,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
