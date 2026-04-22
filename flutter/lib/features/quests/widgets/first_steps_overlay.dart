import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';

class FirstStepsOverlay extends StatefulWidget {
  const FirstStepsOverlay({
    super.key,
    required this.tokensAwarded,
    required this.scrollsAwarded,
    this.onContinue,
  });

  final int tokensAwarded;
  final int scrollsAwarded;
  final VoidCallback? onContinue;

  @override
  State<FirstStepsOverlay> createState() => _FirstStepsOverlayState();
}

class _FirstStepsOverlayState extends State<FirstStepsOverlay> {
  int _phase = 0; // 0=glow buildup, 1=burst, 2=reveal

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

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
                      const Color(0xFF1B3A2A),
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
                                color:
                                    AppColors.secondary.withValues(alpha: 0.3),
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
                              .fadeOut(
                                  duration: 1200.ms, delay: (i * 250).ms);
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
                                color:
                                    AppColors.secondary.withValues(alpha: 0.6),
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
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.12,
                    left: 32,
                    right: 32,
                    child: Column(
                      children: [
                        // Trophy icon
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.secondary.withValues(alpha: 0.3),
                                AppColors.secondary.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 48,
                            color: AppColors.secondary,
                          ),
                        )
                            .animate()
                            .scaleXY(
                              begin: 0.0,
                              end: 1.0,
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            )
                            .then()
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 1.0, end: 1.06, duration: 1500.ms),
                        const SizedBox(height: 16),

                        // "QUEST LINE COMPLETE"
                        Text(
                          'QUEST LINE COMPLETE',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms),
                        const SizedBox(height: 20),

                        // Arabic calligraphy
                        SizedBox(
                          height: 80,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'بِدَايَة',
                              style:
                                  AppTypography.nameOfAllahDisplay.copyWith(
                                fontSize: 64,
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
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 700.ms)
                            .scaleXY(
                              begin: 0.6,
                              end: 1.0,
                              delay: 300.ms,
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 6),

                        // "First Steps" pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            'First Steps',
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 1,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms, duration: 400.ms),
                        const SizedBox(height: 24),

                        // Completed quests checklist
                        ...beginnerQuests.asMap().entries.map((entry) {
                          final i = entry.key;
                          final quest = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  quest.title,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            )
                                .animate()
                                .fadeIn(
                                  delay: (600 + i * 150).ms,
                                  duration: 400.ms,
                                )
                                .slideX(
                                  begin: -0.15,
                                  end: 0,
                                  delay: (600 + i * 150).ms,
                                  duration: 400.ms,
                                ),
                          );
                        }),
                        const SizedBox(height: 16),

                        // Rewards
                        _buildRewardRow(
                          Icons.toll,
                          AppColors.secondary,
                          '+${widget.tokensAwarded} Tokens',
                          1100,
                        ),
                        if (widget.scrollsAwarded > 0) ...[
                          const SizedBox(height: 10),
                          _buildRewardRow(
                            Icons.receipt_long,
                            const Color(0xFF3B82F6),
                            '+${widget.scrollsAwarded} Scrolls',
                            1250,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Continue button
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
                    ).animate().fadeIn(delay: 1400.ms, duration: 500.ms),
                  ),

                  // Tap hint
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
                    ).animate().fadeIn(delay: 1600.ms, duration: 400.ms),
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
                          color:
                              (isGold ? AppColors.secondary : AppColors.primary)
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

  Widget _buildRewardRow(
      IconData icon, Color color, String label, int delayMs) {
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
    )
        .animate()
        .fadeIn(delay: delayMs.ms, duration: 400.ms)
        .slideX(begin: -0.2, end: 0, delay: delayMs.ms, duration: 400.ms);
  }
}
