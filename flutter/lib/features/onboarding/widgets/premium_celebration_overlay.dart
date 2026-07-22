import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

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
  // 0=gather/wind-up, 1=gold bloom + flash, 2=title reveal, 3=perks + Begin
  int _phase = 0;
  bool _dismissed = false;

  // Drives the Lottie unlock (gather → bloom + warm-white flash → seal ring →
  // settle). Its duration is set from the composition on load; the phase delays
  // below are tuned to its beats (@60fps: flash swell ≈ 1.27s, gold bloom lands
  // ≈ 1.53s / frame 92, seal ring + sparkles settle ≈ 2.5s, rest from ≈ 2.13s).
  late final AnimationController _lottieController;
  bool _lottieStarted = false;

  static const _gold = AppColors.secondary;
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
    // Phase 0 → 1: the gold light gathers + winds up, then BLOOMS with a warm-
    // white flash at frame ~92 (≈1.55s). Fire the celebratory heavy haptic on
    // the flash beat.
    await Future.delayed(const Duration(milliseconds: 1550));
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);

    // Phase 1 → 2: title resolves just AFTER the bloom, as the flash settles.
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _phase = 2);

    // Phase 2 → 3: perk pills + Begin button once the seal ring + sparkles have
    // settled into the resting emblem. Light haptic.
    await Future.delayed(const Duration(milliseconds: 950));
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
              // ── Ambient unlock (Lottie): gather → gold bloom + warm-white
              // flash → seal-of-light ring → settle into a radiant emblem.
              // Replaces the hand-coded glow/rings/orb/particles. Plays once,
              // centered; the native "Sakina Premium / Unlocked" wordmark,
              // perk pills, and Begin button are layered on top.
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 1.5,
                    height: MediaQuery.of(context).size.width * 1.5,
                    child: Lottie.asset(
                      'assets/animations/premium_celebration.json',
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
                      Text(
                        widget.userName.isNotEmpty
                            ? 'Your journey begins, ${widget.userName}'
                            : 'Your journey begins',
                        style: AppTypography.bodyLarge.copyWith(
                          // Warm off-white + dark shadow so it stays legible
                          // over the celebratory gold light behind it.
                          color: const Color(0xFFF6EFE4),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
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
                          label: '3 Streak Freezes',
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
            ],
          ),
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
