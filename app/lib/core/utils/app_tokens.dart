import 'package:flutter/material.dart';

/// Design tokens strictly aligned with SKILL.md rules:
/// - 8pt Grid (4, 8, 12, 16, 24, 32, 48)
/// - Corner Radii (Micro 6-8px, Inputs 10-12px, Cards 16px)
/// - Micro-interactions (150ms - 200ms)
class AppTokens {
  AppTokens._();

  // ── Radii ──────────────────────────────────────────────────
  static const double rMicro = 8.0;
  static const double rInput = 12.0;
  static const double rCard = 16.0;

  static final BorderRadius radiusMicro = BorderRadius.circular(rMicro);
  static final BorderRadius radiusInput = BorderRadius.circular(rInput);
  static final BorderRadius radiusCard = BorderRadius.circular(rCard);

  // ── 8pt Grid Spacing ───────────────────────────────────────
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;

  // Convenient EdgeInsets
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p24 = EdgeInsets.all(s24);

  static const EdgeInsets screenPadding = EdgeInsets.all(s16);
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets cardPadding = EdgeInsets.all(s16);

  // ── Micro-Interaction Animations ───────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 200);
  static const Curve curveDefault = Curves.easeOutQuad;
  static const Curve curveFastOut = Curves.fastOutSlowIn;

  // ── Icon Sizes ─────────────────────────────────────────────
  static const double iconMicro = 16.0;
  static const double iconAction = 20.0;
  static const double iconStandard = 24.0;
}
