import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';

class HookScreen extends StatelessWidget {
  const HookScreen({
    required this.onNext,
    this.onSignIn,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback? onSignIn;

  static const _green = Color(0xFF0B3528);
  static const _midGreen = Color(0xFF0E4032);
  static const _gold = Color(0xFFD4A574);
  static const _goldBright = Color(0xFFE6BC88);

  static const _archImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCJUu2iTbgfM1X8LZzN3Z91Z4Rx_c5_ppJ8yye3sE29zUljg2EX3k-C26Rg_2SG-l3tbV83sK7YZdSY4q9fQRXw5OCOHRxrDepaCV_gJCAcDlEJDAiDnY9zJvHRKR0GeH1MucXnwMdxYOnS41yFDMiAufYjAexqSR0WM2nS7deraReoPn72b5IRzxZHBiVcw-ePri-B9ht5neXNt9IUPjOF6ZYk61pJjxFzHjS1C6sfAHsBFeVB1GWOXbEsWW4qg8vHPlpAS6P-qQKz';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _green,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Solid brand green base
          Container(color: _green),

          // Layer 2: Illustration (raw)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: _archImageUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.2),
              placeholder: (_, __) => const SizedBox.expand(),
              errorWidget: (_, __, ___) => const SizedBox.expand(),
            ),
          ),

          // Layer 2b: Green color overlay (duotone tint)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _green.withAlpha(190),
              ),
            ),
          ),

          // Smooth 7-stop gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _green.withAlpha(64),
                    _green.withAlpha(89),
                    _green.withAlpha(115),
                    _green.withAlpha(89),
                    _green.withAlpha(153),
                    _green.withAlpha(217),
                    _green.withAlpha(250),
                  ],
                  stops: const [0.0, 0.25, 0.45, 0.60, 0.75, 0.88, 1.0],
                ),
              ),
            ),
          ),

          // Gold radial warmth (subtle glow)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.15),
                  radius: 1.1,
                  colors: [Color(0x14E6BC88), Color(0x00E6BC88)],
                  stops: [0.0, 0.65],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  const Spacer(flex: 4),

                  // Sakina in Aref Ruqaa (Arabic calligraphy)
                  Text(
                    'سكينة',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.arefRuqaa(
                      fontSize: 110,
                      color: _gold,
                      height: 1.0,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                  const SizedBox(height: 44),
                  // Feature words
                  Text(
                    'Reflect \u00B7 Build \u00B7 Discover',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withAlpha(160),
                      letterSpacing: 2.0,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

                  const Spacer(flex: 2),

                  // Ayah — Arabic verse
                  Text(
                    AppStrings.hookAyahArabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      height: 1.8,
                      color: _goldBright,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                  const SizedBox(height: 8),
                  // English translation
                  Text(
                    'Indeed, with hardship comes ease.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withAlpha(200),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                  const SizedBox(height: 6),
                  Text(
                    'ASH-SHARH \u00B7 94:6',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(120),
                      letterSpacing: 2.2,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 650.ms),

                  const SizedBox(height: 40),

                  // CTA button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onNext();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _green,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Text(
                          AppStrings.hookCta,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),

                  const SizedBox(height: 16),

                  // Login link
                  TextButton(
                    onPressed: onSignIn != null
                        ? () {
                            HapticFeedback.lightImpact();
                            onSignIn!();
                          }
                        : null,
                    child: Text(
                      AppStrings.hookLoginLink,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white.withAlpha(158),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
