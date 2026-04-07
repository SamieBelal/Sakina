import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/card_collection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Full-Screen Name Reveal Overlay — V1 "Orb → Burst → Calligraphy"
//
// Push as a transparent route via rootNavigator:
//
//   Navigator.of(context, rootNavigator: true).push(
//     PageRouteBuilder(
//       opaque: false,
//       pageBuilder: (_, __, ___) => NameRevealOverlay(...),
//       transitionsBuilder: (_, anim, __, child) =>
//           FadeTransition(opacity: anim, child: child),
//     ),
//   );
// ─────────────────────────────────────────────────────────────────────────────

class NameRevealOverlay extends StatefulWidget {
  const NameRevealOverlay({
    super.key,
    required this.nameArabic,
    required this.nameEnglish,
    required this.nameEnglishMeaning,
    required this.teaching,
    this.card,
    this.engageResult,
    this.onContinue,
  });

  final String nameArabic;
  final String nameEnglish;
  final String nameEnglishMeaning;
  final String teaching;
  final CollectibleName? card;
  final CardEngageResult? engageResult;

  /// Called when the user taps "Continue". If null, defaults to Navigator.pop.
  final VoidCallback? onContinue;

  @override
  State<NameRevealOverlay> createState() => _NameRevealOverlayState();
}

class _NameRevealOverlayState extends State<NameRevealOverlay>
    with TickerProviderStateMixin {
  int _phase = 0; // 0=orb, 1=burst, 2=name, 3=details

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _phase = 2);

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _phase = 3);
  }

  Color get _tierColor => widget.engageResult != null
      ? Color(widget.engageResult!.tier.colorValue)
      : AppColors.secondary;

  String get _tierLabel => widget.engageResult?.tier.label ?? '';
  bool get _isNewCard => widget.engageResult?.isNew ?? false;
  bool get _isTierUp =>
      widget.engageResult != null &&
      !widget.engageResult!.isNew &&
      widget.engageResult!.tierChanged;

  bool _continued = false;

  void _handleContinue() {
    if (_continued) return;
    _continued = true;
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
        onTap: _phase >= 3 ? _handleContinue : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _phase >= 1
                  ? [
                      const Color(0xFF0A0A12),
                      Color.lerp(
                          const Color(0xFF0A0A12), _tierColor, 0.15)!,
                      const Color(0xFF0A0A12),
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
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _tierColor.withValues(alpha: 0.2),
                              _tierColor.withValues(alpha: 0.05),
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
                              curve: Curves.easeOut)
                          .then()
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 1.0, end: 1.15, duration: 2000.ms),
                    ),
                  ),

                // ── Radiating rings (phase 1) ──
                if (_phase == 1)
                  ...List.generate(4, (i) {
                    return Center(
                      child: Container(
                        width: 100 + (i * 60.0),
                        height: 100 + (i * 60.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _tierColor
                                .withValues(alpha: 0.4 - (i * 0.08)),
                            width: 2,
                          ),
                        ),
                      )
                          .animate()
                          .scaleXY(
                              begin: 0.3,
                              end: 1.5,
                              duration: 800.ms,
                              delay: (i * 80).ms,
                              curve: Curves.easeOut)
                          .fadeOut(duration: 800.ms, delay: (i * 80).ms),
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
                                    _tierColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat())
                              .scaleXY(
                                  begin: 0.5,
                                  end: 2.0,
                                  duration: 1500.ms,
                                  delay: (i * 300).ms)
                              .fadeOut(
                                  duration: 1500.ms,
                                  delay: (i * 300).ms);
                        }),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white,
                                _tierColor.withValues(alpha: 0.9),
                                _tierColor.withValues(alpha: 0.0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _tierColor.withValues(alpha: 0.6),
                                blurRadius: 40,
                                spreadRadius: 15,
                              )
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 0.8, end: 1.3, duration: 800.ms),
                      ],
                    ),
                  ),

                // ── Phase 2+: Arabic Name ──
                if (_phase >= 2)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.18,
                    left: 24,
                    right: 24,
                    child: Column(
                      children: [
                        if (_tierLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _tierColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      _tierColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              _tierLabel.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(
                                color: _tierColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                fontSize: 11,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(
                                  begin: -0.5,
                                  end: 0,
                                  duration: 400.ms),
                        const SizedBox(height: 24),
                        Text(
                          widget.nameArabic,
                          style: AppTypography.nameOfAllahDisplay.copyWith(
                            fontSize: 80,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color:
                                      _tierColor.withValues(alpha: 0.6),
                                  blurRadius: 30),
                              Shadow(
                                  color:
                                      _tierColor.withValues(alpha: 0.3),
                                  blurRadius: 60),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .scaleXY(
                                begin: 0.3,
                                end: 1.0,
                                duration: 800.ms,
                                curve: Curves.easeOutBack),
                        const SizedBox(height: 12),
                        Text(
                          widget.nameEnglish,
                          style: AppTypography.headlineLarge.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 24),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 500.ms)
                            .slideY(
                                begin: 0.3,
                                end: 0,
                                delay: 300.ms,
                                duration: 500.ms),
                        const SizedBox(height: 6),
                        if (widget.nameEnglishMeaning.isNotEmpty)
                          Text(
                            widget.nameEnglishMeaning,
                            style: AppTypography.bodyLarge.copyWith(
                                color: _tierColor.withValues(alpha: 0.8)),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(
                              delay: 500.ms, duration: 500.ms),
                      ],
                    ),
                  ),

                // ── Phase 3: Details + continue ──
                if (_phase >= 3)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0A0A12).withValues(alpha: 0.0),
                            const Color(0xFF0A0A12).withValues(alpha: 0.95),
                            const Color(0xFF0A0A12),
                          ],
                          stops: const [0.0, 0.25, 1.0],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isNewCard || _isTierUp)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: _tierColor, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isNewCard
                                        ? 'NEW CARD'
                                        : _tierLabel == 'Gold'
                                            ? 'FULLY EVOLVED'
                                            : 'TIER ${widget.engageResult?.newTier ?? 2} UNLOCKED',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: _tierColor,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              )
                                  .animate()
                                  .fadeIn(duration: 400.ms)
                                  .shimmer(
                                      delay: 200.ms,
                                      duration: 1500.ms,
                                      color: _tierColor.withValues(alpha: 0.3)),
                            ),
                          Text(
                            widget.teaching,
                            style: AppTypography.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                                height: 1.5,
                                fontSize: 13),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                          const SizedBox(height: 20),

                          GestureDetector(
                            onTap: _handleContinue,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.buttonRadius),
                              ),
                              child: Text(
                                'Continue',
                                style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                        ],
                      ),
                    ),
                  ),

                // ── Floating particles (phase 2+) ──
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
                          color: _tierColor
                              .withValues(alpha: 0.6 - (i * 0.04)),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: (i * 100).ms, duration: 400.ms)
                          .slideY(
                              begin: 0.5,
                              end: -2.0,
                              delay: (i * 100).ms,
                              duration: 2500.ms)
                          .slideX(
                              begin: startX,
                              end: 0,
                              delay: (i * 100).ms,
                              duration: 2500.ms)
                          .fadeOut(
                              delay: (1500 + i * 100).ms,
                              duration: 800.ms),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

