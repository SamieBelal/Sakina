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
}
