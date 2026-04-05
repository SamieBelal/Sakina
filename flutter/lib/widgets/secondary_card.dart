import 'package:flutter/material.dart';
import 'package:sakina/core/constants/app_spacing.dart';

/// Secondary card for stats, info blocks, badges
/// - Tinted background (caller provides color)
/// - No shadow (relies on bg color for visual lift)
/// - No border
class SecondaryCard extends StatelessWidget {
  const SecondaryCard({
    required this.child,
    required this.backgroundColor,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
