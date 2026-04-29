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

    final tabIndex = _currentIndex(context);
    final isOffTab = tabIndex < 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        // BottomNavigationBar requires a valid index. When the user is on a
        // pushed sub-route (e.g. /quests, /settings, /store) we still need
        // to pass a legal index, but we visually deselect everything by
        // collapsing selected/unselected colors so no tab looks active.
        currentIndex: isOffTab ? 0 : tabIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor:
            isOffTab ? AppColors.textTertiaryLight : AppColors.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        selectedLabelStyle:
            isOffTab ? AppTypography.bodySmall : AppTypography.labelMedium,
        unselectedLabelStyle: AppTypography.bodySmall,
        // When off-tab, use the outlined icon as activeIcon too so no tab
        // appears filled/selected. This keeps BottomNavigationBar happy
        // (still needs a valid currentIndex) without lying to the user
        // about where they are.
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon:
                Icon(isOffTab ? Icons.home_outlined : Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.style_outlined),
            activeIcon:
                Icon(isOffTab ? Icons.style_outlined : Icons.style),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon:
                Icon(isOffTab ? Icons.favorite_outline : Icons.favorite),
            label: 'Reflect',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(
                isOffTab ? Icons.auto_awesome_outlined : Icons.auto_awesome),
            label: 'Duas',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book_outlined),
            activeIcon: Icon(isOffTab ? Icons.book_outlined : Icons.book),
            label: 'Journal',
          ),
        ],
      ),
    );
  }

  /// Returns the bottom-nav index for tab routes, or `-1` for pushed
  /// sub-routes that live inside the shell but aren't tabs (Quests,
  /// Settings, Store). The shell uses `-1` to deselect every tab so the
  /// nav bar doesn't claim the user is on Home when they aren't.
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/collection')) return 1;
    if (location.startsWith('/reflect')) return 2;
    if (location.startsWith('/duas')) return 3;
    if (location.startsWith('/journal')) return 4;
    if (location.startsWith('/quests') ||
        location.startsWith('/settings') ||
        location.startsWith('/store')) {
      return -1;
    }
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
