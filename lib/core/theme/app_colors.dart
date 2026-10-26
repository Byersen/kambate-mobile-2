import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEEF1F6);
  static const Color border = Color(0xFFE2E7EF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Compatibilidad durante la migración de las pantallas existentes.
  static const Color backgroundDark = background;
  static const Color surfaceDark = surface;
  static const Color cardDark = surface;
  static const Color cardBorderDark = border;

  static const Color primary = Color(0xFF245BFF);
  static const Color primaryDark = Color(0xFF1645CC);
  static const Color secondary = primary;
  static const Color liveRed = Color(0xFFC62828);

  static const Color soccer = Color(0xFF15803D);
  static const Color basketball = Color(0xFFC05612);
  static const Color nba = basketball;
  static const Color ufc = Color(0xFFC62828);
  static const Color ufcRed = ufc;
  static const Color borderDark = border;
  static const Color lol = primary;
  static const Color valorant = Color(0xFFC62848);

  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF52627A);
  static const Color textMuted = Color(0xFF626F83);

  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFF9A6500);
  static const Color error = liveRed;
}
