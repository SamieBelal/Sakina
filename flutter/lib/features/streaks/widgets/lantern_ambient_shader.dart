import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Process-wide loader for the lantern's ambient-aura fragment program.
///
/// `FragmentProgram.fromAsset` used to run once per `CompanionMedallion`
/// instance, which was invisible while the companion appeared on one screen at
/// a time. Wave G puts the lantern on several onboarding surfaces in quick
/// succession, so the compile is hoisted here and shared.
///
/// Each caller still creates its OWN [ui.FragmentShader] from the returned
/// program — shaders carry per-frame uniforms and must never be shared between
/// painters. Only the compiled program is cached.
abstract final class LanternAmbientShader {
  static const String assetKey = 'shaders/khatam_glow.frag';

  static Future<ui.FragmentProgram>? _program;

  /// The compiled program, compiling on first call and reusing it after.
  ///
  /// A failure is cached as a failure: it means the asset is missing or
  /// malformed, which will not fix itself on the next mount, and retrying per
  /// instance would spam the log throughout onboarding. Callers treat a throw
  /// as "no aura" — the painter renders correctly without it.
  static Future<ui.FragmentProgram> load() =>
      _program ??= ui.FragmentProgram.fromAsset(assetKey);

  /// Creates a fresh shader for one painter, or null if the program is
  /// unavailable. Never throws — the aura is decorative.
  static Future<ui.FragmentShader?> shader() async {
    try {
      return (await load()).fragmentShader();
    } catch (e) {
      debugPrint('lantern ambient shader unavailable: $e');
      return null;
    }
  }

  /// Test seam: drop the cached program so a test can exercise the load path
  /// (or a failure) without leaking a previous result into the next test.
  @visibleForTesting
  static void resetForTest() => _program = null;
}
