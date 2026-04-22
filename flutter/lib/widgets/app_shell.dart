import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../features/quests/providers/quests_provider.dart';
import '../features/quests/widgets/first_steps_overlay.dart';
import '../widgets/quest_completion_toast.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bundle celebration: show overlay no matter which tab the user is on.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      final celebration = next.pendingBundleCelebration;
      if (celebration != null && prev?.pendingBundleCelebration == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = Navigator.of(context, rootNavigator: true);
          navigator
              .push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => FirstStepsOverlay(
                    tokensAwarded: celebration.tokens,
                    scrollsAwarded: celebration.scrolls,
                  ),
                ),
              )
              .whenComplete(() {
                ref
                    .read(questsProvider.notifier)
                    .clearPendingBundleCelebration();
              });
        });
      }
    });

    // Quest completion toasts: react when pendingCompletions becomes non-empty.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      if (next.pendingCompletions.isNotEmpty &&
          (prev?.pendingCompletions.isEmpty ?? true)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final quests =
              ref.read(questsProvider.notifier).consumePendingCompletions();
          for (final quest in quests) {
            showQuestCompletionToast(quest);
          }
        });
      }
    });

    // First Steps beginner quest completion toasts.
    ref.listen<QuestsState>(questsProvider, (prev, next) {
      final beginner = next.pendingBeginnerCompletion;
      if (beginner != null && prev?.pendingBeginnerCompletion == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showQuestCompletionToast(Quest(
            id: beginner.id.key,
            cadence: QuestCadence.daily,
            title: beginner.title,
            description: beginner.description,
            icon: beginner.icon,
            xpReward: beginner.xpReward,
            tokenReward: beginner.tokenReward,
            scrollReward: beginner.scrollReward,
            poolIndex: -1,
            target: 0,
          ));
          ref
              .read(questsProvider.notifier)
              .clearPendingBeginnerCompletion();
        });
      }
    });

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        selectedLabelStyle: AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.bodySmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            activeIcon: Icon(Icons.style),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: 'Reflect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Duas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Journal',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/collection')) return 1;
    if (location.startsWith('/reflect')) return 2;
    if (location.startsWith('/duas')) return 3;
    if (location.startsWith('/journal')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/collection');
      case 2:
        context.go('/reflect');
      case 3:
        context.go('/duas');
      case 4:
        context.go('/journal');
    }
  }
}
