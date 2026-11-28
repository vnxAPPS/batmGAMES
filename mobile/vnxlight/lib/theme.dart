import 'package:flutter/material.dart';

/// Палитра vnxLIGHT: та же, что у vnxMATRIX и vnxMATH — тёмно-синий и мята.
abstract final class Palette {
  static const bgTop = Color(0xFF0B1836);
  static const bgBottom = Color(0xFF02060F);
  static const mint = Color(0xFF3BE08C);
  static const mintLight = Color(0xFF9AF7CB);
  static const teal = Color(0xFF19B6A6);
  static const blue = Color(0xFF5B8CFF);
  static const text = Color(0xFFEAF1FF);
  static const textDim = Color(0xFF8D9BC0);

  /// Цвет луча: тёплый белый с лёгкой мятой.
  static const beam = Color(0xFFF2FFF8);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Palette.mint,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: Palette.bgBottom,
);
