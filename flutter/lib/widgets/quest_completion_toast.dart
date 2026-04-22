import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/widgets/achievement_toast.dart';

/// Show a quest completion toast. Delegates to the unified queue in
/// `achievement_toast.dart` so quests and achievements never overlap.
void showQuestCompletionToast(Quest quest) {
  enqueueQuestToast(quest);
}

// ---------------------------------------------------------------------------
// Quest toast widget (public so the unified queue can render it)
// ---------------------------------------------------------------------------

class QuestToastWidget extends StatefulWidget {
  const QuestToastWidget({
    super.key,
    required this.quest,
    required this.onDismissed,
  });

  final Quest quest;
  final VoidCallback onDismissed;

  @override
  State<QuestToastWidget> createState() => _QuestToastWidgetState();
}

class _QuestToastWidgetState extends State<QuestToastWidget> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.selectionClick();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onDismissed();
      });
    });
  }

  String _rewardText() {
    final parts = <String>[];
    if (widget.quest.xpReward > 0) parts.add('+${widget.quest.xpReward} XP');
    if (widget.quest.tokenReward > 0) {
      parts.add('+${widget.quest.tokenReward} Tokens');
    }
    if (widget.quest.scrollReward > 0) {
      parts.add('+${widget.quest.scrollReward} Scrolls');
    }
    return parts.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 80,
      left: 20,
      right: 20,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: _visible ? 1.0 : 0.95,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, 1.5),
            duration: const Duration(milliseconds: 400),
            curve: _visible ? Curves.easeOutBack : Curves.easeIn,
            child: AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      )
                          .animate()
                          .scaleXY(
                            begin: 0.0,
                            end: 1.0,
                            duration: 500.ms,
                            delay: 200.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'QUEST COMPLETE',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 1,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.quest.title,
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_rewardText().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _rewardText(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.secondary.withValues(alpha: 0.6),
                        size: 18,
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms),
                    ],
                  ),
                )
                    .animate()
                    .shimmer(
                      delay: 400.ms,
                      duration: 1000.ms,
                      color: AppColors.secondary.withValues(alpha: 0.4),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
