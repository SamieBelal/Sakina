import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakina/features/collection/providers/card_collection_provider.dart';
import 'package:sakina/features/collection/providers/tier_up_scroll_provider.dart';
import 'package:sakina/features/daily/providers/daily_loop_provider.dart';
import 'package:sakina/features/daily/providers/daily_question_provider.dart';
import 'package:sakina/features/daily/providers/daily_rewards_provider.dart';
import 'package:sakina/features/daily/providers/token_provider.dart';
import 'package:sakina/features/discovery/providers/discovery_quiz_provider.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/features/quests/providers/quests_provider.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/features/streaks/providers/companion_inputs_provider.dart';

void invalidateAllUserProviders(WidgetRef ref) {
  ref.invalidate(reflectProvider);
  ref.invalidate(duasProvider);
  ref.invalidate(cardCollectionProvider);
  ref.invalidate(dailyRewardsProvider);
  ref.invalidate(questsProvider);
  ref.invalidate(dailyLoopProvider);
  ref.invalidate(tokenProvider);
  ref.invalidate(tierUpScrollProvider);
  ref.invalidate(discoveryQuizProvider);
  ref.invalidate(dailyQuestionProvider);
  ref.invalidate(premiumStateProvider);
  // The companion reads getStreak() directly, so a streak/freeze mutation
  // (dev tools, sign-out reset) must force it to re-read — otherwise it keeps a
  // stale brightness until the freeze bool happens to flip or the app relaunches.
  ref.invalidate(companionInputsProvider);
}
