import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/features/duas/providers/duas_provider.dart';
import 'package:sakina/services/ai_service.dart';
import 'package:sakina/services/daily_usage_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  final fixedNow = DateTime.parse('2026-04-10T12:00:00Z');

  FindDuasResponse findResponse() => const FindDuasResponse(
        names: [
          FindDuasNameEntry(
            name: 'Al-Mujeeb',
            nameArabic: 'المجيب',
            why: 'He answers sincere calls.',
          ),
        ],
        duas: [
          FindDuasDuaEntry(
            title: 'For relief',
            arabic: 'دعاء',
            transliteration: 'dua',
            translation: 'supplication',
            source: 'Tirmidhi',
          ),
        ],
      );

  BuiltDuaResponse buildResponse() => const BuiltDuaResponse(
        arabic: 'اللهم اهدني',
        transliteration: 'Allahumma ihdini',
        translation: 'O Allah, guide me',
        breakdown: [
          BuiltDuaSection(
            label: 'Opening',
            arabic: 'الحمد لله',
            transliteration: 'Alhamdulillah',
            translation: 'All praise is for Allah',
          ),
          BuiltDuaSection(
            label: 'Salawat',
            arabic: 'اللهم صل على محمد',
            transliteration: 'Allahumma salli ala Muhammad',
            translation: 'O Allah, send blessings upon Muhammad',
          ),
          BuiltDuaSection(
            label: 'Ask',
            arabic: 'اهدني',
            transliteration: 'ihdini',
            translation: 'guide me',
          ),
          BuiltDuaSection(
            label: 'Closing',
            arabic: 'آمين',
            transliteration: 'Ameen',
            translation: 'Ameen',
          ),
        ],
        namesUsed: [
          BuiltDuaNameUsed(
            name: 'Al-Hadi',
            nameArabic: 'الهادي',
            why: 'For guidance',
          ),
        ],
        relatedDuas: [
          FindDuasDuaEntry(
            title: 'For guidance',
            arabic: 'دعاء',
            transliteration: 'dua',
            translation: 'guidance',
            source: 'Muslim',
          ),
        ],
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(SupabaseSyncService.debugReset);

  test('loads saved duas and browse IDs from scoped cache on init', () async {
    SharedPreferences.setMockInitialValues({
      'saved_built_duas:user-1': jsonEncode([
        {
          'id': 'dua-1',
          'savedAt': '2026-04-09T12:00:00Z',
          'need': 'calm',
          'arabic': 'arabic',
          'transliteration': 'translit',
          'translation': 'translation',
        },
      ]),
      'saved_related_duas:user-1': jsonEncode([
        {
          'id': 'related-1',
          'title': 'Ease',
          'arabic': 'arabic',
          'transliteration': 'translit',
          'translation': 'translation',
          'source': 'source',
        },
      ]),
      'saved_browse_dua_ids:user-1': ['browse-1'],
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final notifier = DuasNotifier(
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-loaded',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.savedBuiltDuas, hasLength(1));
    expect(notifier.state.savedRelatedDuas, hasLength(1));
    expect(notifier.state.savedDuaIds, contains('browse-1'));
  });

  test('browse saves, find succeeds, and related duas toggle persistently',
      () async {
    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-browse',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.toggleSavedDua('browse-1');
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.savedDuaIds, contains('browse-1'));

    notifier.setFindNeed('I need relief');
    await notifier.submitFind();
    expect(notifier.state.findResult?.duas, hasLength(1));
    expect(notifier.state.error, isNull);

    const related = FindDuasDuaEntry(
      title: 'For relief',
      arabic: 'دعاء',
      transliteration: 'dua',
      translation: 'supplication',
      source: 'Tirmidhi',
    );
    notifier.toggleSaveRelatedDua(related);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.isRelatedDuaSaved(related), isTrue);

    notifier.toggleSaveRelatedDua(related);
    await Future<void>.delayed(Duration.zero);
    expect(notifier.isRelatedDuaSaved(related), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('saved_browse_dua_ids:user-1'), ['browse-1']);
    expect(prefs.getString('saved_related_duas:user-1'), isNotNull);
  });

  test('off-topic and failed builds do not consume free usage', () async {
    final offTopicNotifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-offtopic',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(offTopicNotifier.dispose);

    offTopicNotifier.setBuildNeed('hi');
    await offTopicNotifier.submitBuild();

    expect(
      offTopicNotifier.state.error,
      'This place is for your heart. Please describe a sincere need or intention for your dua.',
    );
    expect(await getBuiltDuaUsageToday(), 0);

    final failingNotifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => throw Exception('boom'),
        now: () => fixedNow,
        createId: () => 'dua-error',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(failingNotifier.dispose);

    failingNotifier.setBuildNeed('Guide me');
    await failingNotifier.submitBuild();

    expect(
        failingNotifier.state.error, 'Something went wrong. Please try again.');
    expect(await getBuiltDuaUsageToday(), 0);
  });

  test('resetBuild clears buildNeed so the screen can sync the text controller',
      () async {
    // Regression for finding 2026-04-26-build-dua-tryagain-no-clear.
    // The screen's ref.listen watches buildNeed transitioning from non-empty
    // to empty as its signal to clear the TextEditingController. If
    // resetBuild ever stops setting buildNeed to '', the input field on
    // Try Again will silently start preserving stale text again.
    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-reset',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.setBuildNeed('a previous, possibly off-topic, request');
    expect(notifier.state.buildNeed, isNotEmpty);

    notifier.resetBuild();
    expect(notifier.state.buildNeed, isEmpty,
        reason:
            'Try Again handler relies on buildNeed clearing to wipe the text controller');
    expect(notifier.state.buildResult, isNull);
    expect(notifier.state.error, isNull);
  });

  test(
      'build that returns empty breakdown (server-side off-topic) does not consume free usage',
      () async {
    // Regression for finding 2026-04-26-build-dua-offtopic-counter:
    // when the regex pre-filter passes but the AI returns an unparseable /
    // empty response (off-topic equivalent), the counter must NOT increment.
    const emptyBreakdownResponse = BuiltDuaResponse(
      arabic: '',
      transliteration: '',
      translation: '',
      breakdown: [],
      namesUsed: [],
      relatedDuas: [],
    );

    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => emptyBreakdownResponse,
        now: () => fixedNow,
        createId: () => 'dua-empty',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    // "pizza recipe" passes the regex pre-filter, hits the AI, gets back
    // an empty breakdown (the server's way of saying "off-topic").
    notifier.setBuildNeed('pizza recipe with pepperoni and extra cheese');
    await notifier.submitBuild();

    expect(notifier.state.buildResult?.breakdown, isEmpty);
    expect(await getBuiltDuaUsageToday(), 0,
        reason:
            'Empty breakdown means the user got no dua; free usage must not decrement.');
  });

  test(
      'successful build tracks names, supports section navigation, and saves built duas',
      () async {
    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-123',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.setBuildNeed('Guide me gently');
    await notifier.submitBuild();

    expect(notifier.state.buildResult, isNotNull);
    expect(notifier.state.buildLoading, isFalse);
    expect(await getBuiltDuaUsageToday(), 1);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList(fakeSync.scopedKey('sakina_names_invoked')),
      contains('Al-Hadi'),
    );
    expect(prefs.getStringList('sakina_names_invoked'), isNull);

    notifier.nextBuildSection();
    notifier.nextBuildSection();
    notifier.nextBuildSection();
    expect(notifier.state.buildCurrentSection, 3);
    notifier.previousBuildSection();
    expect(notifier.state.buildCurrentSection, 2);

    await notifier.saveCurrentBuiltDua();

    expect(notifier.state.savedBuiltDuas, hasLength(1));
    expect(notifier.state.savedBuiltDuas.single.id, 'dua-123');
    expect(notifier.state.savedBuiltDuas.single.savedAt,
        fixedNow.toIso8601String());
    expect(notifier.isBuiltDuaSaved(), isTrue);

    final builtWrites = fakeSync.insertCalls
        .where((call) => call['table'] == 'user_built_duas')
        .toList();
    expect(builtWrites, hasLength(1));

    await notifier.removeSavedBuiltDua('dua-123');
    expect(notifier.state.savedBuiltDuas, isEmpty);
    expect(
        fakeSync.deleteCalls.any((call) =>
            call['table'] == 'user_built_duas' && call['value'] == 'dua-123'),
        isTrue);
  });

  test(
      'token-gated builds can continue with token without consuming free usage',
      () async {
    for (var i = 0; i < dailyFreeBuiltDuas; i++) {
      await incrementBuiltDuaUsage();
    }

    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-token',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.setBuildNeed('Ease my heart');
    await notifier.submitBuild();

    expect(notifier.state.buildNeedsToken, isTrue);
    expect(await getBuiltDuaUsageToday(), dailyFreeBuiltDuas);

    await notifier.submitBuildWithToken();
    expect(notifier.state.buildResult, isNotNull);
    expect(await getBuiltDuaUsageToday(), dailyFreeBuiltDuas);
  });

  test('find failures surface an error without mutating prior state', () async {
    final notifier = DuasNotifier(
      loadOnInit: false,
      dependencies: DuasDependencies(
        findDuas: (_) async => throw Exception('find failed'),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-find-error',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    notifier.setFindNeed('Need help');
    await notifier.submitFind();

    expect(notifier.state.findResult, isNull);
    expect(notifier.state.error, 'Something went wrong. Please try again.');
  });

  test(
      'saveCurrentBuiltDua sets needsUpgrade and does not save when free limit hit',
      () async {
    // Seed 5 saved duas (the freeJournalLimit) on a free user.
    final savedPayload = List.generate(
      DuasNotifier.freeJournalLimit,
      (i) => {
        'id': 'dua-$i',
        'savedAt': fixedNow.toIso8601String(),
        'need': 'need-$i',
        'arabic': 'ar',
        'transliteration': 'tr',
        'translation': 'en',
      },
    );
    SharedPreferences.setMockInitialValues({
      'saved_built_duas:user-1': jsonEncode(savedPayload),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final notifier = DuasNotifier(
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-new',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    // Wait for loadSavedDuas to finish
    await Future<void>.delayed(Duration.zero);
    expect(notifier.state.savedBuiltDuas, hasLength(DuasNotifier.freeJournalLimit));

    // Put something in state.buildResult so saveCurrentBuiltDua proceeds past
    // its null guard
    notifier.setBuildNeed('anything');
    await notifier.submitBuild();

    expect(notifier.state.needsUpgrade, isFalse);
    await notifier.saveCurrentBuiltDua();

    expect(notifier.state.needsUpgrade, isTrue);
    expect(
      notifier.state.savedBuiltDuas,
      hasLength(DuasNotifier.freeJournalLimit),
      reason: 'blocked save must not add to the list',
    );

    notifier.dismissUpgradePrompt();
    expect(notifier.state.needsUpgrade, isFalse);
  });

  test(
      'save-handled flag prevents the Ameen auto-save loop after cap rejection',
      () async {
    // Regression guard for the infinite-loop bug: when a free user hits the
    // journal cap, the Ameen screen's auto-save was re-running on every
    // widget rebuild (triggered by dismissUpgradePrompt flipping
    // needsUpgrade back to false), re-raising the upgrade sheet forever.
    // The fix sets buildResultSaveHandled=true on cap rejection so the
    // widget can gate the auto-save on it. This test pins that flag's
    // lifecycle at the provider level.
    final savedPayload = List.generate(
      DuasNotifier.freeJournalLimit,
      (i) => {
        'id': 'dua-$i',
        'savedAt': fixedNow.toIso8601String(),
        'need': 'need-$i',
        'arabic': 'ar',
        'transliteration': 'tr',
        'translation': 'en',
      },
    );
    SharedPreferences.setMockInitialValues({
      'saved_built_duas:user-1': jsonEncode(savedPayload),
    });
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);

    final notifier = DuasNotifier(
      dependencies: DuasDependencies(
        findDuas: (_) async => findResponse(),
        buildDua: (_) async => buildResponse(),
        now: () => fixedNow,
        createId: () => 'dua-new',
      ),
      resultRevealDelay: Duration.zero,
    );
    addTearDown(notifier.dispose);

    await Future<void>.delayed(Duration.zero);

    notifier.setBuildNeed('anything');
    await notifier.submitBuild();

    // A freshly produced build result has not yet been handled by auto-save.
    expect(notifier.state.buildResultSaveHandled, isFalse);

    await notifier.saveCurrentBuiltDua();

    // Cap rejection path marks the attempt as handled AND raises the sheet.
    expect(notifier.state.needsUpgrade, isTrue);
    expect(notifier.state.buildResultSaveHandled, isTrue);

    // Dismissing the upgrade sheet must NOT reset buildResultSaveHandled,
    // otherwise the Ameen rebuild would re-enter the auto-save branch.
    notifier.dismissUpgradePrompt();
    expect(notifier.state.needsUpgrade, isFalse);
    expect(
      notifier.state.buildResultSaveHandled,
      isTrue,
      reason:
          'dismissing the upgrade sheet must keep buildResultSaveHandled=true '
          'so the Ameen widget does not retry the auto-save in a loop',
    );

    // Starting a new build resets the flag so the next result can auto-save.
    notifier.setBuildNeed('another intention');
    await notifier.submitBuild();
    expect(notifier.state.buildResultSaveHandled, isFalse);
  });
}
