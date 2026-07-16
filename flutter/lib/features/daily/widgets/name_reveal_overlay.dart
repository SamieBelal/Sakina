import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
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

  // Drives the Lottie reveal (orb → light-burst → settle). Its duration is set
  // from the composition on load; the phase delays below are tuned to its beats
  // (flash ≈ 1.4s, halo settle from ≈ 1.9s).
  late final AnimationController _lottieController;
  bool _lottieStarted = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '[REVEAL] nameArabic="${widget.nameArabic}" nameEnglish="${widget.nameEnglish}" card.arabic="${widget.card?.arabic}"');
    _lottieController = AnimationController(vsync: this);
    _runSequence();
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _runSequence() async {
    // Wind-up + flash land here (Lottie anticipation contracts ~1.2s, flashes
    // ~1.4s). Fire the heavy haptic on the flash.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

    // Name resolves as the flash settles.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _phase = 2);

    // Details/card come in once the light has settled into the halo.
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
      backgroundColor: const Color(0xFF0A0A12),
      body: GestureDetector(
        // Only accept taps once the Continue button is rendered (phase 3).
        // Earlier taps during phase 2 were advancing before the user could
        // see the reward details — see docs/qa/findings/2026-04-22-*.
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
                      Color.lerp(const Color(0xFF0A0A12), _tierColor, 0.15)!,
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
                // ── Ambient reveal (Lottie): orb → light-burst → settle ──
                // Replaces the hand-coded glow/rings/orb/particles. Plays once,
                // centered; the Arabic Name is layered natively on top. The
                // light is warm gold (divine-light read) across all tiers.
                Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 1.5,
                      height: MediaQuery.of(context).size.width * 1.5,
                      child: Lottie.asset(
                        'assets/animations/name_reveal.json',
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
                                  color: _tierColor.withValues(alpha: 0.4)),
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
                              .slideY(begin: -0.5, end: 0, duration: 400.ms),
                        SizedBox(height: _tierLabel.isNotEmpty ? 46 : 28),
                        SizedBox(
                          height: 124,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.nameArabic.isNotEmpty
                                  ? widget.nameArabic
                                  : widget.card?.arabic ?? '',
                              style: AppTypography.nameOfAllahDisplay.copyWith(
                                fontSize: 80,
                                color: Colors.white,
                                fontFamilyFallback: const ['Arial', 'Tahoma'],
                                shadows: [
                                  Shadow(
                                      color: _tierColor.withValues(alpha: 0.6),
                                      blurRadius: 30),
                                  Shadow(
                                      color: _tierColor.withValues(alpha: 0.3),
                                      blurRadius: 60),
                                ],
                              ),
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ).animate().fadeIn(duration: 800.ms).scaleXY(
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
                          ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
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
                                            ? 'FULLY UPGRADED'
                                            : 'TIER ${widget.engageResult?.newTier ?? 2} UNLOCKED',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: _tierColor,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(duration: 400.ms).shimmer(
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

              ],
            ),
          ),
        ),
      ),
    );
  }
}
