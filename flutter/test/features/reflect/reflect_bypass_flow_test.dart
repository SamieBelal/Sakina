import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/reflect/models/reflect_verse.dart';
import 'package:sakina/features/reflect/providers/reflect_provider.dart';
import 'package:sakina/services/ai_service.dart' as ai;
import 'package:sakina/services/daily_usage_service.dart' as daily;
import 'package:sakina/services/gating_service.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_supabase_sync_service.dart';

class _FakePurchaseService extends PurchaseService {
  _FakePurchaseService() : super.test();
  bool premium = false;
  @override
  Future<bool> isPremium() async => premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _FakePurchaseService fakePurchase;
  final fixedNow = DateTime.parse('2026-04-10T12:00:00Z');

  ai.ReflectResponse successResponse() => ai.ReflectResponse(
        name: 'As-Salam',
        nameArabic: 'السلام',
        reframe: 'Rest is real.',
        story: 'A story.',
        verses: const [
          ReflectVerse(
            arabic: 'verse',
            translation: 'translation',
            reference: 'Ar-Rad 13:28',
          ),
        ],
        duaArabic: 'دعاء',
        duaTransliteration: 'dua',
        duaTranslation: 'supplication',
        duaSource: 'source',
        relatedNames: const [],
        offTopic: false,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    fakePurchase = _FakePurchaseService();
    PurchaseService.debugSetOverride(fakePurchase);
    await hydrateTokenCache(balance: 100, totalSpent: 0);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
    PurchaseService.debugClearOverride();
  });

  test(
      'happy path: reserve → AI success → commit fires; tokens stay debited',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'res-1',
          'balance': 75,
          'bypasses_used': 1,
        };
    fakeSync.rpcHandlers['commit_ai_bypass'] = (_) async => {'ok': true};

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => successResponse(),
        now: () => fixedNow,
        createId: () => 'r-1',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I need patience');
    await notifier.submitWithBypass();

    expect(notifier.state.screenState, ReflectScreenState.result);

    final reserveCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'reserve_ai_bypass');
    final commitCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'commit_ai_bypass');
    final cancelCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'cancel_ai_bypass');
    expect(reserveCalls, hasLength(1));
    expect(commitCalls, hasLength(1),
        reason: 'AI success must trigger a commit');
    expect(cancelCalls, isEmpty,
        reason: 'AI success must NOT trigger a cancel');

    // Token balance reflects the post-reserve debit. (commit doesn't refund.)
    expect((await getTokens()).balance, 75);
    expect(await daily.getReflectBypassesUsedToday(), 1);
  });

  test(
      'TEST-E: AI throws → cancel fires; tokens + counter restored',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': true,
          'reservation_id': 'res-fail',
          'balance': 75,
          'bypasses_used': 1,
        };
    fakeSync.rpcHandlers['cancel_ai_bypass'] = (_) async => {
          'ok': true,
          'balance': 100,
          'refunded_tokens': 25,
        };

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async => throw Exception('OpenAI 503'),
        now: () => fixedNow,
        createId: () => 'r-2',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('I feel anxious');
    await notifier.submitWithBypass();

    expect(notifier.state.screenState, ReflectScreenState.input,
        reason: 'AI failure must return user to input screen');
    expect(notifier.state.error, isNotNull);

    final commitCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'commit_ai_bypass');
    final cancelCalls =
        fakeSync.rpcCalls.where((c) => c['fn'] == 'cancel_ai_bypass');
    expect(commitCalls, isEmpty,
        reason: 'Failed AI must NOT commit a reservation');
    expect(cancelCalls, hasLength(1),
        reason: 'Failed AI must fire cancel to refund tokens');

    // Cancel response hydrated balance back to 100; counter rolled back to 0.
    expect((await getTokens()).balance, 100);
    expect(await daily.getReflectBypassesUsedToday(), 0);
  });

  test('reserve rejected → silent return, no AI call, error string set',
      () async {
    fakeSync.rpcHandlers['reserve_ai_bypass'] = (_) async => {
          'ok': false,
          'reason': 'bypass_cap',
        };
    var reflectFired = false;

    final notifier = ReflectNotifier(
      loadOnInit: false,
      dependencies: ReflectDependencies(
        getFollowUpQuestions: (_) async => const [],
        reflect: (_) async {
          reflectFired = true;
          return successResponse();
        },
        now: () => fixedNow,
        createId: () => 'r-3',
      ),
    );
    addTearDown(notifier.dispose);

    notifier.setUserText('test');
    await notifier.submitWithBypass();

    expect(reflectFired, isFalse,
        reason: 'Reserve rejection must short-circuit the AI call');
    expect(notifier.state.error, contains('Bypass unavailable'));
    expect((await getTokens()).balance, 100,
        reason: 'No token change when reserve rejects');
  });
}
