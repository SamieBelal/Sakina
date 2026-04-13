import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/collection/widgets/bronze_ornate_card.dart';
import '../../../features/collection/widgets/emerald_ornate_card.dart';
import '../../../features/collection/widgets/gold_ornate_card.dart';
import '../../../features/collection/widgets/ornate_card_shimmer.dart';
import '../../../features/collection/widgets/silver_mini_ornate_card.dart';
import '../../../services/card_collection_service.dart';
import '../widgets/onboarding_continue_button.dart';
import '../widgets/onboarding_page_wrapper.dart';

class FeatureNamesScreen extends StatefulWidget {
  const FeatureNamesScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<FeatureNamesScreen> createState() => _FeatureNamesScreenState();
}

class _FeatureNamesScreenState extends State<FeatureNamesScreen>
    with SingleTickerProviderStateMixin {
  static const _shimmerStartDelay = Duration(milliseconds: 1300);

  late final AnimationController _shimmerController;
  bool _showSynchronizedShimmer = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: kOrnateCardShimmerDuration,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(_shimmerStartDelay);
      if (!mounted) return;
      setState(() => _showSynchronizedShimmer = true);
      _shimmerController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  OrnateCardShimmer? get _cardShimmer => _showSynchronizedShimmer
      ? OrnateCardShimmer(controller: _shimmerController)
      : null;

  @override
  Widget build(BuildContext context) {
    return OnboardingPageWrapper(
      progressSegment: 4,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero: card stack
          Expanded(
            flex: 6,
            child: Center(child: _buildCardStack(context)),
          ),

          // Headline + subtitle + CTA
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.featureNamesHeadlinePostLoop,
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.textPrimaryLight,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.05, end: 0, duration: 500.ms, delay: 200.ms),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.featureNamesSubtitlePostLoop,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                const Spacer(),
                OnboardingContinueButton(
                  label: AppStrings.continueButton,
                  onPressed: widget.onNext,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth * 0.30;
    final cardHeight = cardWidth / 0.72;
    final shimmer = _cardShimmer;

    // Fan from a shared bottom-center pivot — symmetric spread.
    const angles = [-0.70, -0.23, 0.23, 0.70];
    final delays = [300, 450, 600, 750];

    final cards = [
      BronzeOrnateTile(
        arabic: AppStrings.featureNamesSampleName3,
        transliteration: AppStrings.featureNamesSampleTranslit3,
        shimmer: shimmer,
      ),
      SilverMiniOrnateTile(
        arabic: AppStrings.featureNamesSampleName2,
        transliteration: AppStrings.featureNamesSampleTranslit2,
        shimmer: shimmer,
      ),
      GoldOrnateTile(
        card: getCollectiblePreviewCard(),
        shimmer: shimmer,
      ),
      EmeraldPreviewTile(
        arabic: AppStrings.featureNamesSampleName1,
        transliteration: AppStrings.featureNamesSampleTranslit1,
        shimmer: shimmer,
      ),
    ];

    final stackHeight = cardHeight + 60;

    return SizedBox(
      height: stackHeight,
      width: screenWidth * 0.9,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          for (var i = 0; i < 4; i++)
            Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()..rotateZ(angles[i]),
              child: SizedBox(width: cardWidth, child: cards[i]),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: delays[i].ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: delays[i].ms),
        ],
      ),
    );
  }
}
