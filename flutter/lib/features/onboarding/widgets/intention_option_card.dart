import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class IntentionOptionCard extends StatefulWidget {
  const IntentionOptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<IntentionOptionCard> createState() => _IntentionOptionCardState();
}

class _IntentionOptionCardState extends State<IntentionOptionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    HapticFeedback.selectionClick();
    await _bounceController.forward();
    await _bounceController.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryLight
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: widget.isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.textOnPrimary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
