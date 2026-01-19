import 'package:flutter/material.dart';

class SpotifyColors {
  static const Color black = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF181818);
  static const Color lightGrey = Color(0xFF282828);
  static const Color green = Color(0xFF1DB954);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFFB3B3B3);
}

class SpotifyTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Poppins', 
      scaffoldBackgroundColor: SpotifyColors.black,
      primaryColor: SpotifyColors.green,
      colorScheme: const ColorScheme.dark(
        primary: SpotifyColors.green,
        secondary: SpotifyColors.green,
        surface: SpotifyColors.darkGrey,
        background: SpotifyColors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SpotifyColors.black,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SpotifyColors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: SpotifyColors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: SpotifyColors.grey,
          fontSize: 14,
        ),
      ),
    );
  }
}
