import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Streak Milestone Celebration Overlay
//
// Amber-themed "unboxing" moment when a user hits a streak milestone
// (7/14/30/60/90/180/365 days). Four phases:
//   0 → anticipation flame orb + ripples
//   1 → radiating amber burst rings
//   2 → flame icon + huge streak number + "Day Streak!" label
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

class _StreakMilestoneOverlayState extends State<StreakMilestoneOverlay> {
  // 0=anticipation orb, 1=burst rings, 2=number reveal, 3=rewards + continue
  int _phase = 0;

  static const _amber = AppColors.streakAmber;
  static const _bg = Color(0xFF0A0A12);

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 0 → 1: anticipation flame orb (1.2s), then burst + heavy haptic
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

    // Phase 1 → 2: brief burst (400ms), then number reveal
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 2);

    // Phase 2 → 3: number sits for a moment, then rewards + Continue
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _phase = 3);
  }

  void _handleContinue() {
    HapticFeedback.lightImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // ── Background glow ──
              if (_phase >= 1)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _amber.withValues(alpha: 0.22),
                            _amber.withValues(alpha: 0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .scaleXY(
                          begin: 0.0,
                          end: 1.0,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        )
                        .then()
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          begin: 1.0,
                          end: 1.15,
                          duration: 2000.ms,
                        ),
                  ),
                ),

              // ── Phase 1: Radiating amber burst rings ──
              if (_phase == 1)
                ...List.generate(4, (i) {
                  return Center(
                    child: Container(
                      width: 100 + (i * 60.0),
                      height: 100 + (i * 60.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _amber.withValues(alpha: 0.45 - (i * 0.08)),
                          width: 2,
                        ),
                      ),
                    )
                        .animate()
                        .scaleXY(
                          begin: 0.3,
                          end: 1.6,
                          duration: 800.ms,
                          delay: (i * 80).ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(
                          duration: 800.ms,
                          delay: (i * 80).ms,
                        ),
                  );
                }),

              // ── Phase 0: Anticipation flame orb with 3 concentric ripples ──
              if (_phase == 0)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(3, (i) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _amber.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .scaleXY(
                              begin: 0.5,
                              end: 2.0,
                              duration: 1500.ms,
                              delay: (i * 300).ms,
                            )
                            .fadeOut(
                              duration: 1500.ms,
                              delay: (i * 300).ms,
                            );
                      }),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _amber.withValues(alpha: 0.25),
                              _amber.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _amber.withValues(alpha: 0.55),
                              blurRadius: 40,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 0.85,
                            end: 1.25,
                            duration: 800.ms,
                          ),
                    ],
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
                      const Icon(
                        Icons.local_fire_department,
                        color: _amber,
                        size: 48,
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scaleXY(
                            begin: 0.5,
                            end: 1.0,
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
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

              // ── Floating amber particles (phase 2+) ──
              if (_phase >= 2)
                ...List.generate(12, (i) {
                  final isLeft = i % 2 == 0;
                  final startX = isLeft ? -0.5 : 0.5;
                  return Positioned(
                    top: 100 + (i * 50.0),
                    left: isLeft ? 20 + (i * 15.0) : null,
                    right: isLeft ? null : 20 + (i * 12.0),
                    child: Container(
                      width: 4 + (i % 3) * 2.0,
                      height: 4 + (i % 3) * 2.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _amber.withValues(alpha: 0.65 - (i * 0.04)),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: (i * 100).ms,
                          duration: 400.ms,
                        )
                        .slideY(
                          begin: 0.5,
                          end: -2.0,
                          delay: (i * 100).ms,
                          duration: 2500.ms,
                        )
                        .slideX(
                          begin: startX,
                          end: 0,
                          delay: (i * 100).ms,
                          duration: 2500.ms,
                        )
                        .fadeOut(
                          delay: (1500 + i * 100).ms,
                          duration: 800.ms,
                        ),
                  );
                }),
            ],
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
