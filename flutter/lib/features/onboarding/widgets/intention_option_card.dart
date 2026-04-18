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
    this.icon,
    this.iconColor,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

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
    widget.onTap();
    await _bounceController.forward();
    await _bounceController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final noIcon = widget.icon == null;
    final compact = noIcon && widget.subtitle.isEmpty;
    final height = compact ? 56.0 : (noIcon ? 68.0 : 80.0);
    return ScaleTransition(
      scale: _bounceAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: height,
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
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected
                        ? AppColors.secondaryLight
                        : AppColors.primaryLight,
                  ),
                  child: Icon(
                    widget.icon!,
                    color: widget.isSelected
                        ? AppColors.secondary
                        : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: widget.icon != null
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      textAlign: widget.icon != null
                          ? TextAlign.start
                          : TextAlign.center,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    if (widget.subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.subtitle,
                        textAlign: widget.icon != null
                            ? TextAlign.start
                            : TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.icon != null) const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
