import 'package:flutter/material.dart';

/// Палитра vnxMATH: тёмно-синий фон, мятные акценты, лёгкие градиенты.
abstract final class Palette {
  static const bgTop = Color(0xFF0B1836);
  static const bgBottom = Color(0xFF040A1A);
  static const surface = Color(0x14FFFFFF);
  static const surfaceStrong = Color(0x22FFFFFF);
  static const stroke = Color(0x26FFFFFF);
  static const mint = Color(0xFF3BE08C);
  static const mintLight = Color(0xFF9AF7CB);
  static const teal = Color(0xFF19B6A6);
  static const blue = Color(0xFF5B8CFF);
  static const violet = Color(0xFFA27BFF);
  static const amber = Color(0xFFFFC857);
  static const text = Color(0xFFEAF1FF);
  static const textDim = Color(0xFF8D9BC0);
  static const error = Color(0xFFFF6B81);

  static const mintGradient = LinearGradient(
    colors: [mint, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

const fontFamily = 'Manrope';

/// Manrope — вариативный шрифт: толщину задаём и весом, и осью wght, чтобы
/// она применялась на любом движке отрисовки.
TextStyle font(double size, int weight, {Color color = Palette.text}) =>
    TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      color: color,
      height: 1.2,
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.mint,
    brightness: Brightness.dark,
    primary: Palette.mint,
    surface: Palette.bgBottom,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: Palette.bgBottom,
    splashFactory: InkSparkle.splashFactory,
  );
}
