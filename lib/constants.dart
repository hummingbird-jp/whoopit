import 'package:flutter/material.dart';

ThemeData kThemeData = ThemeData(
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4642B3),
    secondary: Color(0xFFFFCC4A),
    error: Color(0xFFFF2D34),
    surface: Color(0xFF000030),
    background: Color(0xFF000030),
    onPrimary: Colors.white,
    onSecondary: Color(0xFF4642B3),
    onError: Color(0xFF0D0D0D),
    onSurface: Colors.white,
    onBackground: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF000030),
    shadowColor: Colors.transparent,
  ),
);
