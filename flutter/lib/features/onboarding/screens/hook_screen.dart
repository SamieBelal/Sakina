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

  static const _archImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCJUu2iTbgfM1X8LZzN3Z91Z4Rx_c5_ppJ8yye3sE29zUljg2EX3k-C26Rg_2SG-l3tbV83sK7YZdSY4q9fQRXw5OCOHRxrDepaCV_gJCAcDlEJDAiDnY9zJvHRKR0GeH1MucXnwMdxYOnS41yFDMiAufYjAexqSR0WM2nS7deraReoPn72b5IRzxZHBiVcw-ePri-B9ht5neXNt9IUPjOF6ZYk61pJjxFzHjS1C6sfAHsBFeVB1GWOXbEsWW4qg8vHPlpAS6P-qQKz';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final archWidth = screenWidth * 0.6;
    final archHeight = archWidth * 1.25;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // Background glow orbs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(50),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withAlpha(35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Title
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.outfit(
                    fontSize: 38,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: AppSpacing.lg),
                // Arch visual
                _ArchVisual(
                  width: archWidth,
                  height: archHeight,
                  imageUrl: _archImageUrl,
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      delay: 200.ms,
                    ),
                SizedBox(height: screenHeight < 700 ? AppSpacing.lg : AppSpacing.xxl),
                // Hook text
                Text(
                  AppStrings.hookSubtitle1,
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white.withAlpha(140),
                    fontSize: 16,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.hookSubtitle2,
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
                const Spacer(),
                // GET STARTED button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 4,
                        shadowColor: Colors.black.withAlpha(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        AppStrings.hookCta,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
                const SizedBox(height: AppSpacing.md),
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
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white.withAlpha(150),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchVisual extends StatelessWidget {
  const _ArchVisual({
    required this.width,
    required this.height,
    required this.imageUrl,
  });

  final double width;
  final double height;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final topRadius = width / 2;

    return SizedBox(
      width: width * 1.25,
      height: height * 1.08,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative border (white, subtle)
          Container(
            width: width * 1.2,
            height: height * 1.06,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withAlpha(30),
                width: 0.5,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(width * 0.6),
              ),
            ),
          ),
          // Inner decorative border (gold)
          Container(
            width: width * 1.08,
            height: height * 1.02,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.secondary.withAlpha(90),
                width: 1.5,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(width * 0.54),
              ),
            ),
          ),
          // Main arch with image
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(topRadius),
            ),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox.expand(),
                    errorWidget: (_, __, ___) => const SizedBox.expand(),
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.secondary.withAlpha(70),
                          const Color(0xFF32684F).withAlpha(100),
                          AppColors.primaryDark.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                  // Sparkle icon
                  const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
