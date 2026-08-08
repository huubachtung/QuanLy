import 'package:flutter/material.dart';

// ============================================================
// App Color Palette — Juss_TV (Official Branding)
// ============================================================
class AppColors {
  AppColors._();

  // ── Requested Branding Colors ─────────────────────────────
  // Dark: Deep Space #0A0E1A + Electric Blue #1E3A8A + Gold #F59E0B
  static const Color deepSpace = Color(0xFF0A0E1A);
  static const Color electricBlue = Color(0xFF1E3A8A);
  static const Color gold = Color(0xFFF59E0B);

  // Light: Pearl White #F8FAFF + Steel Blue #1E40AF + Gold #D97706
  static const Color pearlWhite = Color(0xFFF8FAFF);
  static const Color steelBlue = Color(0xFF1E40AF);
  static const Color goldDark = Color(0xFFD97706);

  // ── Theme Aliases (Compatibility) ─────────────────────────
  static const Color primaryBlue = steelBlue;    // Primary for Light
  static const Color primaryLight = electricBlue; // Primary for Dark
  
  static const Color darkBg = deepSpace;
  static const Color lightBg = pearlWhite;

  // ── Dark Surfaces ─────────────────────────────────────────
  static const Color darkSurface = Color(0xFF161B2E);
  static const Color darkCard = Color(0xFF1C243D);
  static const Color darkCardElevated = Color(0xFF232D4B);
  static const Color darkBorder = Color(0xFF2D3748);

  // ── Light Surfaces ────────────────────────────────────────
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ── Functional Colors ─────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);

  // ── Task / Project Status ─────────────────────────────────
  static const Color statusNotStarted = Color(0xFF64748B);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusFinished = Color(0xFF10B981);
  static const Color statusDelayed = Color(0xFFEF4444);
  static const Color statusHold = Color(0xFF8B5CF6);
  static const Color statusCancelled = Color(0xFF6B7280);

  // ── Attendance Status ─────────────────────────────────────
  static const Color attendanceDone = Color(0xFF10B981);
  static const Color attendanceLate = Color(0xFFF59E0B);
  static const Color attendanceEarlyLeave = Color(0xFF3B82F6);
  static const Color attendanceLateEarly = Color(0xFFEF4444);
  static const Color attendanceAbsent = Color(0xFF6B7280);
  static const Color attendancePending = Color(0xFF8B5CF6);
}
