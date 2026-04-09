import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/xp_service.dart';

class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.levelNumber,
    required this.title,
    required this.titleArabic,
    this.rewards,
    this.onContinue,
  });

  final int levelNumber;
  final String title;
  final String titleArabic;
  final LevelUpRewards? rewards;
  final VoidCallback? onContinue;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  int _phase = 0; // 0=glow buildup, 1=burst, 2=reveal

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 0: glow buildup
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

    // Phase 1: burst
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _phase = 2);
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
        onTap: _phase >= 2 ? _handleContinue : null,
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
                // ── Background glow ──
                if (_phase >= 1)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.secondary.withValues(alpha: 0.25),
                              AppColors.primary.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .scaleXY(
                            begin: 0.0,
                            end: 1.0,
                            duration: 700.ms,
                            curve: Curves.easeOut,
                          )
                          .then()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 1.0, end: 1.12, duration: 2000.ms),
                    ),
                  ),

                // ── Radiating rings (phase 1) ──
                if (_phase == 1)
                  ...List.generate(5, (i) {
                    return Center(
                      child: Container(
                        width: 80 + (i * 50.0),
                        height: 80 + (i * 50.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary
                                .withValues(alpha: 0.5 - (i * 0.08)),
                            width: 2,
                          ),
                        ),
                      )
                          .animate()
                          .scaleXY(
                            begin: 0.3,
                            end: 1.8,
                            duration: 900.ms,
                            delay: (i * 80).ms,
                            curve: Curves.easeOut,
                          )
                          .fadeOut(duration: 900.ms, delay: (i * 80).ms),
                    );
                  }),

                // ── Phase 0: Pulsing orb ──
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
                                color: AppColors.secondary.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scaleXY(
                                begin: 0.5,
                                end: 2.0,
                                duration: 1200.ms,
                                delay: (i * 250).ms,
                              )
                              .fadeOut(duration: 1200.ms, delay: (i * 250).ms);
                        }),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white,
                                AppColors.secondary.withValues(alpha: 0.9),
                                AppColors.secondary.withValues(alpha: 0.0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.6),
                                blurRadius: 50,
                                spreadRadius: 20,
                              )
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 0.8, end: 1.4, duration: 600.ms),
                      ],
                    ),
                  ),

                // ── Phase 2: Full reveal ──
                if (_phase >= 2) ...[
                  // "RANK UP" banner at top
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.10,
                    left: 24,
                    right: 24,
                    child: Column(
                      children: [
                        // Banner ribbon effect
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
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            'RANK UP!',
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
                      ],
                    ),
                  ),

                  // Hexagonal badge area (level number)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.22,
                    left: 24,
                    right: 24,
                    child: Column(
                      children: [
                        // Hexagon-like badge
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.8),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.6),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
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
                                fontSize: 48,
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
                        const SizedBox(height: 24),

                        // Arabic calligraphy — the hero
                        Text(
                          widget.titleArabic,
                          style: AppTypography.nameOfAllahDisplay.copyWith(
                            fontSize: 72,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: AppColors.secondary.withValues(alpha: 0.6),
                                blurRadius: 30,
                              ),
                              Shadow(
                                color: AppColors.secondary.withValues(alpha: 0.3),
                                blurRadius: 60,
                              ),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
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
                        const SizedBox(height: 8),

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
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          'New rank unlocked',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.secondary.withValues(alpha: 0.8),
                          ),
                        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

                        // Rewards
                        if (widget.rewards != null) ...[
                          const SizedBox(height: 24),
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
                      ],
                    ),
                  ),

                  // Continue button at bottom
                  Positioned(
                    bottom: 60,
                    left: 32,
                    right: 32,
                    child: GestureDetector(
                      onTap: _handleContinue,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
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
                  ),

                  // "Tap anywhere to continue" hint
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Tap anywhere to continue',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
                  ),
                ],

                // ── Floating sparkle particles (phase 2+) ──
                if (_phase >= 2)
                  ...List.generate(16, (i) {
                    final isLeft = i % 2 == 0;
                    final startX = isLeft ? -0.5 : 0.5;
                    final isGold = i % 3 == 0;
                    return Positioned(
                      top: 60 + (i * 40.0),
                      left: isLeft ? 10 + (i * 12.0) : null,
                      right: isLeft ? null : 10 + (i * 10.0),
                      child: Container(
                        width: 3 + (i % 4) * 1.5,
                        height: 3 + (i % 4) * 1.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isGold ? AppColors.secondary : AppColors.primary)
                              .withValues(alpha: 0.7 - (i * 0.03)),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: (i * 80).ms, duration: 300.ms)
                          .slideY(
                            begin: 0.5,
                            end: -2.5,
                            delay: (i * 80).ms,
                            duration: 3000.ms,
                          )
                          .slideX(
                            begin: startX,
                            end: 0,
                            delay: (i * 80).ms,
                            duration: 3000.ms,
                          )
                          .fadeOut(
                            delay: (2000 + i * 80).ms,
                            duration: 800.ms,
                          ),
                    );
                  }),
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
