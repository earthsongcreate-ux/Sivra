import 'package:flutter/material.dart';

import 'sivra_colors.dart';

class SivraTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SivraColors.bronze,
      brightness: Brightness.light,
      surface: SivraColors.warmIvory,
      onSurface: SivraColors.deepInk,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SivraColors.warmIvory,
      appBarTheme: const AppBarTheme(
        backgroundColor: SivraColors.warmIvory,
        foregroundColor: SivraColors.deepInk,
        centerTitle: false,
      ),
      textTheme: Typography.material2021().black,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SivraColors.bronze,
      brightness: Brightness.dark,
      surface: SivraColors.deepInk,
      onSurface: SivraColors.warmIvory,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        primary: SivraColors.bronze,
        secondary: SivraColors.softSage,
        surface: SivraColors.deepInk,
        onSurface: SivraColors.warmIvory,
      ),
      scaffoldBackgroundColor: SivraColors.deepInk,
      appBarTheme: const AppBarTheme(
        backgroundColor: SivraColors.deepInk,
        foregroundColor: SivraColors.warmIvory,
        centerTitle: false,
      ),
      textTheme: Typography.material2021().white,
      cardTheme: const CardThemeData(
        color: SivraColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
