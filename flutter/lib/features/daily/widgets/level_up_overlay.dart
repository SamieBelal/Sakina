import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/xp_service.dart';
import 'package:sakina/widgets/adjusted_arabic_display.dart';

class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    this.levelNumber,
    required this.title,
    required this.titleArabic,
    this.bannerText = 'RANK UP!',
    this.subtitle = 'New rank unlocked',
    this.rewards,
    this.onContinue,
  });

  final int? levelNumber;
  final String title;
  final String titleArabic;
  final String bannerText;
  final String subtitle;
  final LevelUpRewards? rewards;
  final VoidCallback? onContinue;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

// Phase transition timing for `_runSequence`, retuned to the level_up.json beats
// (200f @ 60fps ≈ 3.33s one-shot; crown-lock flash peaks at frame 112 ≈ 1.87s).
// Cumulative offsets from initState:
// Phase 0 → 1 at +1100ms — mid-ascent (shaft rise + tier rings nesting); the
//   heavy haptic marks the launch/climb, not the reveal.
// Phase 1 → 2 at +1900ms — just after the warm-white CROWN-LOCK flash (~1.87s).
//   The "RANK UP / Level N" native content resolves onto the settled medallion;
//   the celebratory (heavy) haptic fires on this lock beat.
// Phase 2 → 3 at +2900ms — ~1s after the reveal, once the medallion + rising
//   sparks have settled. Gates the outer "tap anywhere" detector; the Continue
//   button's own `delay: 900ms + duration: 500ms` fade-in window sits inside
//   phase 2 (same double-continue guard pattern as name_reveal_overlay.dart).
const _kPhase1Offset = Duration(milliseconds: 1100);
const _kPhase2Offset = Duration(milliseconds: 1900);
const _kPhase3Offset = Duration(milliseconds: 2900);

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with TickerProviderStateMixin {
  // 0=glow buildup, 1=burst, 2=reveal (Continue button shown), 3=tap-anywhere armed.
  // Phase 3 exists to absorb the double-continue race: the Continue button
  // fades in at delay=900ms+duration=500ms (= 1400ms) inside phase 2, and
  // during that window two GestureDetectors compete (full-screen body + the
  // button itself). Gating the outer detector to phase >= 3 keeps the button
  // tappable immediately while the "tap anywhere to continue" affordance only
  // arms once the button is fully on-screen — same pattern as
  // name_reveal_overlay.dart's phase-3 gate.
  int _phase = 0;
  // Pending timers — kept as a list so dispose() can cancel any that haven't
  // fired yet. Previous implementation used bare `Future.delayed(...)` which
  // schedules Timers without giving us a handle to cancel them; widget
  // disposal would leak pending timers and trip `!timersPending` in tests.
  final List<Timer> _pendingTimers = [];

  // Drives the level_up.json reveal (anticipation dip → light shaft + tier rings
  // ascend → chevrons pulse → crown-lock flash ≈ 1.87s → medallion + sparks
  // settle). Its duration is set from the composition on load; the phase offsets
  // above are tuned to its beats. Replaces the hand-coded orb/rings/glow/sparks.
  late final AnimationController _lottieController;
  bool _lottieStarted = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _runSequence();
  }

  void _runSequence() {
    // Re-entry guard: if the sequence is already armed (timers scheduled),
    // don't double-schedule. Only called from `initState` today, but a future
    // hot-reload or didUpdateWidget hook would otherwise duplicate timers.
    if (_pendingTimers.isNotEmpty) return;
    _schedulePhase(_kPhase1Offset, () {
      // Mid-ascent buildup as the shaft rises and rings nest.
      HapticFeedback.mediumImpact();
      setState(() => _phase = 1);
    });
    _schedulePhase(_kPhase2Offset, () {
      // Celebratory haptic on the crown-lock flash beat (~1.87s), landing with
      // the "RANK UP / Level N" reveal.
      HapticFeedback.heavyImpact();
      setState(() => _phase = 2);
    });
    _schedulePhase(_kPhase3Offset, () {
      setState(() => _phase = 3);
    });
  }

  void _schedulePhase(Duration offset, VoidCallback fire) {
    _pendingTimers.add(Timer(offset, () {
      if (!mounted) return;
      fire();
    }));
  }

  @override
  void dispose() {
    for (final t in _pendingTimers) {
      t.cancel();
    }
    _lottieController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    HapticFeedback.lightImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: GestureDetector(
        // Gate outer "tap anywhere" to phase 3 so the Continue button (rendered
        // at phase 2) wins the gesture arena cleanly during its fade-in.
        // Loosening this gate to `>= 2` reintroduces the double-continue bug.
        onTap: _phase >= 3 ? _handleContinue : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _phase >= 1
                  ? [
                      const Color(0xFF1B3A2A), // dark emerald
                      const Color(0xFF0A0A12),
                      Color.lerp(
                        const Color(0xFF0A0A12),
                        AppColors.secondary,
                        0.12,
                      )!,
                    ]
                  : [
                      const Color(0xFF0A0A12),
                      const Color(0xFF0A0A12),
                      const Color(0xFF0A0A12),
                    ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Ambient reveal (Lottie): anticipation → ascent → tier-lock ──
                // Replaces the hand-coded glow/rings/orb/sparks. Plays once,
                // centered, over the emerald→ink canvas; the native "RANK UP /
                // Level N" content is layered on top and resolves at the
                // crown-lock beat (~1.87s).
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 1.5,
                      height: MediaQuery.of(context).size.width * 1.5,
                      child: Lottie.asset(
                        'assets/animations/level_up.json',
                        controller: _lottieController,
                        fit: BoxFit.contain,
                        repeat: false,
                        onLoaded: (composition) {
                          if (_lottieStarted) return;
                          _lottieStarted = true;
                          _lottieController
                            ..duration = composition.duration
                            ..forward(from: 0);
                        },
                      ),
                    ),
                  ),
                ),

                // ── Phase 2: Full reveal ──
                if (_phase >= 2) ...[
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),

                          // Banner ribbon
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.secondary.withValues(alpha: 0.9),
                                  const Color(0xFFD4A44C),
                                  AppColors.secondary.withValues(alpha: 0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.bannerText,
                              style: AppTypography.headlineLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                fontSize: 28,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scaleXY(
                                begin: 0.5,
                                end: 1.0,
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              )
                              .shimmer(
                                delay: 500.ms,
                                duration: 1500.ms,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                          const SizedBox(height: 20),

                          // Level badge
                          if (widget.levelNumber != null) ...[
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.8),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.6),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${widget.levelNumber}',
                                  style: AppTypography.displayLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 500.ms)
                                .scaleXY(
                                  begin: 0.3,
                                  end: 1.0,
                                  delay: 200.ms,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                            const SizedBox(height: 28),
                          ],

                          // Arabic calligraphy — fixed size, no FittedBox
                          AdjustedArabicDisplay(
                            text: widget.titleArabic,
                            style: AppTypography.nameOfAllahDisplay.copyWith(
                              fontSize: 56,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.6),
                                  blurRadius: 30,
                                ),
                                Shadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 60,
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 800.ms)
                              .scaleXY(
                                begin: 0.5,
                                end: 1.0,
                                delay: 400.ms,
                                duration: 700.ms,
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 20),

                          // English title pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              widget.title,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.95),
                                letterSpacing: 2,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 500.ms)
                              .slideY(
                                begin: 0.3,
                                end: 0,
                                delay: 600.ms,
                                duration: 500.ms,
                              ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            widget.subtitle,
                            style: AppTypography.bodyMedium.copyWith(
                              color:
                                  AppColors.secondary.withValues(alpha: 0.8),
                            ),
                          ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                          // Rewards
                          if (widget.rewards != null) ...[
                            const SizedBox(height: 16),
                            _buildRewardRow(
                              Icons.toll,
                              AppColors.secondary,
                              '+${widget.rewards!.tokensAwarded} Tokens',
                              800,
                            ),
                            if (widget.rewards!.scrollsAwarded > 0) ...[
                              const SizedBox(height: 10),
                              _buildRewardRow(
                                Icons.receipt_long,
                                const Color(0xFF3B82F6),
                                '+${widget.rewards!.scrollsAwarded} Scrolls',
                                1000,
                              ),
                            ],
                            if (widget.rewards!.titleUnlocked) ...[
                              const SizedBox(height: 10),
                              _buildRewardRow(
                                Icons.star_rounded,
                                const Color(0xFFFBBF24),
                                'New Title Unlocked!',
                                1200,
                              ),
                            ],
                          ],

                          const Spacer(flex: 3),

                          // Continue button
                          GestureDetector(
                            onTap: _handleContinue,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary
                                        .withValues(alpha: 0.85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.buttonRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Continue',
                                style: AppTypography.labelLarge
                                    .copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ).animate().fadeIn(delay: 900.ms, duration: 500.ms),
                          const SizedBox(height: 8),

                          // "Tap anywhere" hint
                          Text(
                            'Tap anywhere to continue',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(
                              delay: 1200.ms, duration: 400.ms),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardRow(IconData icon, Color color, String label, int delayMs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ).animate().fadeIn(delay: delayMs.ms, duration: 400.ms).slideX(begin: -0.2, end: 0, delay: delayMs.ms, duration: 400.ms);
  }
}
