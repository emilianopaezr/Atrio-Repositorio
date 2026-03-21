import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtrioTypography {
  AtrioTypography._();

  // === Primary: Roboto (Google Fonts) ===

  // === Headings ===
  static TextStyle get displayLarge => GoogleFonts.roboto(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.roboto(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle get headingLarge => GoogleFonts.roboto(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle get headingMedium => GoogleFonts.roboto(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get headingSmall => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // === Body ===
  static TextStyle get bodyLarge => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // === Labels ===
  static TextStyle get labelLarge => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // === Numeric/Price ===
  static TextStyle get priceDisplay => GoogleFonts.roboto(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static TextStyle get priceLarge => GoogleFonts.roboto(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  static TextStyle get priceMedium => GoogleFonts.roboto(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle get priceSmall => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static TextStyle get statistic => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // === Caption ===
  static TextStyle get caption => GoogleFonts.roboto(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.3,
  );

  // === Button ===
  static TextStyle get buttonLarge => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0.3,
  );

  static TextStyle get buttonMedium => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.3,
  );
}
