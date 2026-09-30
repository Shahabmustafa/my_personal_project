import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Leather & Ink" palette for the Safi Shoes customer website.
class WColors {
  WColors._();

  static const ink = Color(0xFF17130F);
  static const inkSoft = Color(0xFF231C16);
  static const inkElev = Color(0xFF342A20);
  static const tan = Color(0xFFB27B45);
  static const tanLight = Color(0xFFDDA969);
  static const tanPale = Color(0xFFF2DFC3);
  static const red = Color(0xFFB0322A);
  static const redDeep = Color(0xFF7D1F19);
  static const olive = Color(0xFF55613C);
  static const cream = Color(0xFFF8F3EA);
  static const cream2 = Color(0xFFEFE4D0);
  static const paper = Color(0xFFFFFDF9);
  static const text = Color(0xFF241C15);
  static const muted = Color(0xFF8A7B69);
  static const mutedLight = Color(0xFFB4A690);
  static const line = Color(0xFFE8DCC6);

  static const tanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tanLight, tan],
  );
}

class WShadows {
  WShadows._();

  static const soft = [
    BoxShadow(color: Color(0x1A23190A), blurRadius: 36, offset: Offset(0, 14)),
  ];
  static const large = [
    BoxShadow(color: Color(0x3817130F), blurRadius: 64, offset: Offset(0, 30)),
  ];
  static const red = [
    BoxShadow(color: Color(0x59B0322A), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

class WText {
  WText._();

  static TextStyle display(double size, {Color color = WColors.ink, FontStyle? style}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.12,
        fontStyle: style,
      );

  static TextStyle body(double size,
          {Color color = WColors.text, FontWeight weight = FontWeight.w400, double? height}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height);

  /// Small uppercase label shown above section titles.
  static TextStyle eyebrow({Color color = WColors.red}) => GoogleFonts.poppins(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: color,
      );
}

ThemeData buildWebsiteTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: WColors.cream,
    colorScheme: const ColorScheme.light(
      primary: WColors.red,
      secondary: WColors.tan,
      surface: WColors.paper,
      onPrimary: Colors.white,
      onSurface: WColors.text,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: WColors.text,
      displayColor: WColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WColors.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: GoogleFonts.poppins(color: WColors.mutedLight, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: WColors.muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: WColors.tan, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: WColors.ink,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
