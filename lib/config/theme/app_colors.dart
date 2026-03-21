import 'package:flutter/material.dart';

class AtrioColors {
  AtrioColors._();

  // === Brand Colors (shared across themes) ===
  static const electricViolet = Color(0xFF7C3AED);
  static const electricVioletLight = Color(0xFF8B5CF6);
  static const electricVioletDark = Color(0xFF6D28D9);
  static const neonLime = Color(0xFFD4FF00);
  static const neonLimeDark = Color(0xFF9BBF00);
  static const vibrantOrange = Color(0xFFFF6321);
  static const vibrantOrangeLight = Color(0xFFFF8A57);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const ratingGold = Color(0xFFFFB800);

  // === Guest Mode (Light Theme — clean white) ===
  static const guestBackground = Color(0xFFFAFAFA);
  static const guestSurface = Color(0xFFFFFFFF);
  static const guestSurfaceVariant = Color(0xFFF5F5F5);
  static const guestCardBorder = Color(0xFFE5E5E5);
  static const guestTextPrimary = Color(0xFF1A1A1A);
  static const guestTextSecondary = Color(0xFF666666);
  static const guestTextTertiary = Color(0xFF999999);
  static const guestDivider = Color(0xFFEEEEEE);
  static const guestInputFill = Color(0xFFF5F5F5);
  static const guestNavBar = Color(0xFFFFFFFF);
  static const guestShimmerBase = Color(0xFFEEEEEE);
  static const guestShimmerHighlight = Color(0xFFF5F5F5);

  // === Host Mode (Dark Theme) ===
  static const hostBackground = Color(0xFF0A0A0A);
  static const hostSurface = Color(0xFF1A1A1A);
  static const hostSurfaceVariant = Color(0xFF222222);
  static const hostCardBorder = Color(0xFF2A2A2A);
  static const hostTextPrimary = Color(0xFFFFFFFF);
  static const hostTextSecondary = Color(0xFF999999);
  static const hostTextTertiary = Color(0xFF666666);
  static const hostDivider = Color(0xFF222222);
  static const hostInputFill = Color(0xFF1A1A1A);
  static const hostNavBar = Color(0xFF0A0A0A);
  static const hostShimmerBase = Color(0xFF222222);
  static const hostShimmerHighlight = Color(0xFF333333);

  // === Status Colors ===
  static const statusConfirmed = neonLime;
  static const statusPending = vibrantOrange;
  static const statusCancelled = error;
  static const statusCompleted = success;
  static const statusActive = electricViolet;
}
