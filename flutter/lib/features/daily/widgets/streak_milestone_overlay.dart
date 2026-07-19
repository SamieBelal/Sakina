import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/widgets/companion_medallion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Streak Milestone Celebration Overlay
//
// Amber-themed "unboxing" moment when a user hits a streak milestone
// (7/14/30/60/90/180/365 days). The ambient FX are driven by a single Lottie
// animation (embers gather → flame ignites & rises → living hearth-glow); the
// native content is layered on top through the phase machine:
//   0 → embers gathering (Lottie only)
//   1 → flame ignites (heavy haptic; background warms)
//   2 → flame icon + huge streak number + "Day Streak!" label reveal
//   3 → reward pills (XP + Scrolls) + Continue button
//
// Push as a transparent route via rootNavigator:
//
//   Navigator.of(context, rootNavigator: true).push(
//     PageRouteBuilder(
//       opaque: true,
//       pageBuilder: (_, __, ___) => StreakMilestoneOverlay(
//         streakCount: 7,
//         xpAwarded: 100,
//         scrollsAwarded: 1,
//         onContinue: () { ... },
//       ),
//       transitionsBuilder: (_, anim, __, child) =>
//           FadeTransition(opacity: anim, child: child),
//     ),
//   );
// ─────────────────────────────────────────────────────────────────────────────

class StreakMilestoneOverlay extends StatefulWidget {
  const StreakMilestoneOverlay({
    super.key,
    required this.streakCount,
    required this.xpAwarded,
    required this.scrollsAwarded,
    this.onContinue,
  });

  final int streakCount;
  final int xpAwarded;
  final int scrollsAwarded;

  /// Called when the user taps "Continue". If null, defaults to Navigator.pop.
  final VoidCallback? onContinue;

  @override
  State<StreakMilestoneOverlay> createState() =>
      _StreakMilestoneOverlayState();
}

class _StreakMilestoneOverlayState extends State<StreakMilestoneOverlay>
    with TickerProviderStateMixin {
  // 0=embers gathering, 1=flame ignites, 2=number reveal, 3=rewards + continue
  int _phase = 0;
  bool _dismissed = false;

  // Drives the Lottie hearth (embers gather → flame ignites & rises → settle).
  // Its duration is set from the composition on load; the phase delays below
  // are tuned to its beats (gather ≈ 0–0.93s, IGNITE ≈ frame 96 / 1.6s, rise
  // 1.6–2.67s, settle from ≈ 2.67s).
  late final AnimationController _lottieController;
  bool _lottieStarted = false;

  static const _amber = AppColors.streakAmber;
  static const _bg = Color(0xFF0A0A12);

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _runSequence();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _runSequence() async {
    // Phase 0 → 1: embers gather, then the flame IGNITES (~frame 96 = 1.6s).
    // Fire the heavy haptic on the ignite beat and warm the background.
    await Future.delayed(const Duration(milliseconds: 1650));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

    // Phase 1 → 2: streak number resolves just after the flame catches, as the
    // warm column begins to rise.
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _phase = 2);

    // Phase 2 → 3: number sits while the column rises, then rewards + Continue.
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _phase = 3);
  }

  void _handleContinue() {
    if (_dismissed) return;
    _dismissed = true;
    HapticFeedback.lightImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _phase >= 3) _handleContinue();
      },
      child: Scaffold(
      backgroundColor: _bg,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _phase >= 1
                ? [
                    _bg,
                    Color.lerp(_bg, _amber, 0.18)!,
                    _bg,
                  ]
                : const [_bg, _bg, _bg],
          ),
        ),
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Ambient hearth (Lottie): embers gather → flame ignites &
              // rises → living hearth-glow settles ──
              // Replaces the hand-coded glow/burst-rings/anticipation-orb/
              // particles. Plays once, centered; the streak number + label are
              // layered natively on top. Warm amber matches the streak theme.
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 1.5,
                    height: MediaQuery.of(context).size.width * 1.5,
                    child: Lottie.asset(
                      'assets/animations/streak_milestone.json',
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

              // ── Phase 2+: Flame icon + streak number reveal ──
              if (_phase >= 2)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.18,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      Animate(
                        effects: [
                          FadeEffect(duration: 500.ms),
                          ScaleEffect(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                        ],
                        child: const CompanionMedallion(
                          state: CompanionState(
                            brightness: CompanionBrightness.fullyLit,
                            protected: false,
                          ),
                          size: 132,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${widget.streakCount}',
                        style: AppTypography.displayLarge.copyWith(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: _amber.withValues(alpha: 0.6),
                              blurRadius: 30,
                            ),
                            Shadow(
                              color: _amber.withValues(alpha: 0.3),
                              blurRadius: 60,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 700.ms)
                          .scaleXY(
                            begin: 0.3,
                            end: 1.0,
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 8),
                      Text(
                        'Day Streak!',
                        style: AppTypography.headlineLarge.copyWith(
                          color: _amber,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 500.ms)
                          .slideY(
                            begin: 0.3,
                            end: 0,
                            delay: 300.ms,
                            duration: 500.ms,
                          ),
                    ],
                  ),
                ),

              // ── Phase 3: Reward pills + Continue button ──
              if (_phase >= 3)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _bg.withValues(alpha: 0.0),
                          _bg.withValues(alpha: 0.95),
                          _bg,
                        ],
                        stops: const [0.0, 0.3, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.xpAwarded > 0) ...[
                          _rewardPill(
                            icon: Icons.auto_awesome,
                            label: '+${widget.xpAwarded} XP',
                            color: _amber,
                            delayMs: 0,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (widget.scrollsAwarded > 0) ...[
                          _rewardPill(
                            icon: Icons.receipt_long,
                            label: '+${widget.scrollsAwarded} '
                                '${widget.scrollsAwarded == 1 ? 'Scroll' : 'Scrolls'}',
                            color: const Color(0xFF3B82F6),
                            delayMs: 200,
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: _handleContinue,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 500.ms)
                            .slideY(
                              begin: 0.4,
                              end: 0,
                              delay: 500.ms,
                              duration: 500.ms,
                            ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _rewardPill({
    required IconData icon,
    required String label,
    required Color color,
    required int delayMs,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideX(
          begin: -0.2,
          end: 0,
          delay: delayMs.ms,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
