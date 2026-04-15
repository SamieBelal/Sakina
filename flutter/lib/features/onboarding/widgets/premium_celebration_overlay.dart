import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Premium Purchase Celebration Overlay
//
// Gold-themed "unboxing" moment after a user purchases Sakina Premium.
// Three phases: anticipation orb → burst + reveal → perks + Begin button.
//
// Push as a transparent route via rootNavigator:
//
//   Navigator.of(context, rootNavigator: true).push(
//     PageRouteBuilder(
//       opaque: false,
//       pageBuilder: (_, __, ___) => PremiumCelebrationOverlay(
//         userName: signUpName,
//         onContinue: () { ... },
//       ),
//       transitionsBuilder: (_, anim, __, child) =>
//           FadeTransition(opacity: anim, child: child),
//     ),
//   );
// ─────────────────────────────────────────────────────────────────────────────

class PremiumCelebrationOverlay extends StatefulWidget {
  const PremiumCelebrationOverlay({
    super.key,
    required this.userName,
    this.onContinue,
  });

  final String userName;

  /// Called when the user taps "Begin". If null, defaults to Navigator.pop.
  final VoidCallback? onContinue;

  @override
  State<PremiumCelebrationOverlay> createState() =>
      _PremiumCelebrationOverlayState();
}

class _PremiumCelebrationOverlayState extends State<PremiumCelebrationOverlay>
    with TickerProviderStateMixin {
  // 0=anticipation orb, 1=burst rings, 2=title reveal, 3=perks + Begin button
  int _phase = 0;

  static const _gold = AppColors.secondary;
  static const _bg = Color(0xFF0A0A12);

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 0 → 1: anticipation orb (1.2s), then burst + heavy haptic
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

    // Phase 1 → 2: brief gap then title reveal
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 2);

    // Phase 2 → 3: perk pills + Begin button, light haptic
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
                    Color.lerp(_bg, _gold, 0.18)!,
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
                      width: 360,
                      height: 360,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _gold.withValues(alpha: 0.22),
                            _gold.withValues(alpha: 0.06),
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

              // ── Phase 1: Radiating burst rings (gold) ──
              if (_phase == 1)
                ...List.generate(4, (i) {
                  return Center(
                    child: Container(
                      width: 100 + (i * 60.0),
                      height: 100 + (i * 60.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.45 - (i * 0.08)),
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

              // ── Phase 0: Anticipation gold orb with 3 concentric ripples ──
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
                              color: _gold.withValues(alpha: 0.35),
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white,
                              _gold.withValues(alpha: 0.95),
                              _gold.withValues(alpha: 0.0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: 0.6),
                              blurRadius: 40,
                              spreadRadius: 15,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 0.8,
                            end: 1.3,
                            duration: 800.ms,
                          ),
                    ],
                  ),
                ),

              // ── Phase 2+: Title reveal ──
              if (_phase >= 2)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.22,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: _gold,
                        size: 36,
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
                        'Welcome to Sakina Premium',
                        style: AppTypography.headlineLarge.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: _gold.withValues(alpha: 0.5),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scaleXY(
                            begin: 0.3,
                            end: 1.0,
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 14),
                      if (widget.userName.isNotEmpty)
                        Text(
                          'Your journey begins, ${widget.userName}',
                          style: AppTypography.bodyLarge.copyWith(
                            color: _gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
                            )
                      else
                        Text(
                          'Your journey begins',
                          style: AppTypography.bodyLarge.copyWith(
                            color: _gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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

              // ── Phase 3: Perk pills + Begin button ──
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
                        _perkPill(
                          icon: Icons.all_inclusive_rounded,
                          label: 'Unlimited Reflections',
                          color: AppColors.primary,
                          delayMs: 0,
                        ),
                        const SizedBox(height: 10),
                        _perkPill(
                          icon: Icons.style_rounded,
                          label: 'Premium Cards',
                          color: _gold,
                          delayMs: 200,
                        ),
                        const SizedBox(height: 10),
                        _perkPill(
                          icon: Icons.ac_unit_rounded,
                          label: 'Streak Freeze',
                          color: const Color(0xFF60A5FA),
                          delayMs: 400,
                        ),
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: _handleContinue,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              'Begin',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 500.ms)
                            .slideY(
                              begin: 0.4,
                              end: 0,
                              delay: 700.ms,
                              duration: 500.ms,
                            ),
                      ],
                    ),
                  ),
                ),

              // ── Floating gold particles (phase 2+) ──
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
                        color: _gold.withValues(alpha: 0.65 - (i * 0.04)),
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

  Widget _perkPill({
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
