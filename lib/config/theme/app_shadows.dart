import 'package:flutter/material.dart';
import 'app_colors.dart';

class AtrioShadows {
  AtrioShadows._();

  // === Guest (Light) Shadows ===
  static final guestCardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final guestElevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static final guestButtonShadow = [
    BoxShadow(
      color: AtrioColors.electricViolet.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // === Host (Dark) Glow Shadows ===
  static final hostCardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final hostGlowViolet = [
    BoxShadow(
      color: AtrioColors.electricViolet.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static final hostGlowLime = [
    BoxShadow(
      color: AtrioColors.neonLime.withValues(alpha: 0.2),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static final hostGlowOrange = [
    BoxShadow(
      color: AtrioColors.vibrantOrange.withValues(alpha: 0.2),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static final hostButtonShadow = [
    BoxShadow(
      color: AtrioColors.electricViolet.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];
}
