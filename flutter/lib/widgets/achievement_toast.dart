import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sakina/core/constants/app_colors.dart';
import 'package:sakina/core/constants/app_spacing.dart';
import 'package:sakina/core/theme/app_typography.dart';
import 'package:sakina/services/achievements_service.dart';

// ---------------------------------------------------------------------------
// Global navigator key — set from main.dart
// ---------------------------------------------------------------------------

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// ---------------------------------------------------------------------------
// Queue-based toast system
// ---------------------------------------------------------------------------

final _toastQueue = <Achievement>[];
bool _isShowingToast = false;

/// Show an achievement toast. If one is already showing, queues it.
void showAchievementToast(Achievement achievement) {
  _toastQueue.add(achievement);
  _processQueue();
}

void _processQueue() {
  if (_isShowingToast || _toastQueue.isEmpty) return;

  final context = rootNavigatorKey.currentContext;
  if (context == null) return;

  final overlay = Overlay.of(context);
  final achievement = _toastQueue.removeAt(0);

  _isShowingToast = true;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _AchievementToastWidget(
      achievement: achievement,
      onDismissed: () {
        entry.remove();
        _isShowingToast = false;
        // Process next in queue after a short pause
        Future.delayed(const Duration(milliseconds: 300), _processQueue);
      },
    ),
  );

  overlay.insert(entry);
}

// ---------------------------------------------------------------------------
// Toast widget
// ---------------------------------------------------------------------------

class _AchievementToastWidget extends StatefulWidget {
  const _AchievementToastWidget({
    required this.achievement,
    required this.onDismissed,
  });

  final Achievement achievement;
  final VoidCallback onDismissed;

  @override
  State<_AchievementToastWidget> createState() => _AchievementToastWidgetState();
}

class _AchievementToastWidgetState extends State<_AchievementToastWidget> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Trigger entrance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _visible = false);
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onDismissed();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      bottom: bottomPadding + 80, // above bottom nav
      left: 20,
      right: 20,
      child: IgnorePointer(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: widget.achievement.color.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.achievement.color.withValues(alpha: 0.2),
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
                    // Badge icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.achievement.color.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        color: widget.achievement.color,
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

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Achievement Unlocked',
                            style: AppTypography.labelSmall.copyWith(
                              color: widget.achievement.color,
                              letterSpacing: 1,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.achievement.title,
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Sparkle
                    Icon(
                      Icons.auto_awesome,
                      color: widget.achievement.color.withValues(alpha: 0.6),
                      size: 18,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 0.8, end: 1.2, duration: 800.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
