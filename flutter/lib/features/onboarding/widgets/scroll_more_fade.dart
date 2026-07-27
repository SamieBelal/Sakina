import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// The gentle "there is more below" hint for scrollable onboarding lists
/// (One Ship W2-B2, spec ⑦).
///
/// Shown only when content actually extends past the fold — the alternative,
/// shrinking the cards to fit a short screen, is explicitly banned.
class ScrollMoreFade extends StatelessWidget {
  const ScrollMoreFade({required this.visible, this.height = 48, super.key});

  final ValueListenable<bool> visible;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (context, show, _) => AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundLight.withValues(alpha: 0),
                  AppColors.backgroundLight,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
