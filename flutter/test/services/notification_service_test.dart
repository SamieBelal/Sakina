import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/notification_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

class FakeOneSignalClient implements OneSignalClient {
  final List<String> initializedAppIds = <String>[];
  final List<String> loginUserIds = <String>[];
  int logoutCalls = 0;
  bool permissionGranted = false;
  bool requestPermissionResult = false;
  bool optInCalled = false;
  bool optOutCalled = false;
  bool? optedIn = false;
  final Map<String, String> tags = <String, String>{};
  void Function(NotificationClickEventData event)? clickListener;
  void Function(NotificationForegroundEventData event)? foregroundListener;

  @override
  Future<void> initialize(String appId) async {
    initializedAppIds.add(appId);
  }

  @override
  Future<void> login(String userId) async {
    loginUserIds.add(userId);
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }

  @override
  Future<bool> requestPermission(bool fallbackToSettings) async {
    permissionGranted = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  bool get isPermissionGranted => permissionGranted;

  @override
  Future<void> optIn() async {
    optInCalled = true;
    optedIn = true;
  }

  @override
  Future<void> optOut() async {
    optOutCalled = true;
    optedIn = false;
  }

  @override
  bool? get isOptedIn => optedIn;

  @override
  void addForegroundListener(
    void Function(NotificationForegroundEventData event) listener,
  ) {
    foregroundListener = listener;
  }

  @override
  void addClickListener(
      void Function(NotificationClickEventData event) listener) {
    clickListener = listener;
  }

  void dispatchClick(Map<String, dynamic>? additionalData) {
    clickListener?.call(
      NotificationClickEventData(additionalData: additionalData),
    );
  }
}

class ThrowingFetchRowSupabaseSyncService extends FakeSupabaseSyncService {
  ThrowingFetchRowSupabaseSyncService({super.userId});

  @override
  Future<Map<String, dynamic>?> fetchRow(
    String table,
    String userId, {
    String columns = '*',
  }) async {
    throw Exception('Supabase unreachable');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeOneSignalClient client;
  late NotificationService service;
  late List<String> navigatedRoutes;
  late FakeSupabaseSyncService syncService;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    syncService = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(syncService);
    client = FakeOneSignalClient();
    navigatedRoutes = <String>[];
    service = NotificationService(
      client: client,
      routeNavigator: navigatedRoutes.add,
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  test(
      'getNotificationPreferences reconciles push_enabled=false when iOS permission is denied (F2)',
      () async {
    // Regression for finding 2026-04-26-push-enabled-drift.
    // Server believes the user is enabled but the device permission has
    // been revoked (or was never granted). The cron would otherwise
    // dispatch undeliverable pushes and write last_*_sent_at as if
    // successful. getNotificationPreferences must force push_enabled to
    // false on the server so dispatch stops until the user re-enables.
    await service.initialize('test-app');
    client.permissionGranted = false;
    syncService.rows['user_notification_preferences:user-1'] =
        <String, dynamic>{
      'push_enabled': true,
      notifyDailyTagKey: true,
      notifyStreakTagKey: true,
      notifyReengagementTagKey: true,
      notifyWeeklyTagKey: true,
      notifyUpdatesTagKey: true,
    };

    await service.getNotificationPreferences();

    expect(
      syncService.rows['user_notification_preferences:user-1']?['push_enabled'],
      isFalse,
      reason:
          'reconcile must overwrite push_enabled to false when iOS perm denied',
    );
    expect(service.isOptedIn, isFalse,
        reason: 'cached opt-in state must reflect reconciled value');
  });

  test(
      'getNotificationPreferences leaves push_enabled=true intact when iOS permission is granted',
      () async {
    await service.initialize('test-app');
    client.permissionGranted = true;
    syncService.rows['user_notification_preferences:user-1'] =
        <String, dynamic>{
      'push_enabled': true,
      notifyDailyTagKey: true,
      notifyStreakTagKey: true,
      notifyReengagementTagKey: true,
      notifyWeeklyTagKey: true,
      notifyUpdatesTagKey: true,
    };

    await service.getNotificationPreferences();

    expect(
      syncService.rows['user_notification_preferences:user-1']?['push_enabled'],
      isTrue,
      reason: 'reconcile must NOT touch push_enabled when iOS perm is granted',
    );
    expect(service.isOptedIn, isTrue);
  });

  test(
      'getNotificationPreferences stamps push_enabled_last_verified_at when push_enabled=true and iOS perm is granted (Option B defense in depth)',
      () async {
    // Regression for the cron 7-day freshness filter added 2026-04-26.
    // When client confirms server push_enabled=true AND iOS perm is
    // currently granted, the verified_at stamp must move forward so the
    // RPC keeps the user eligible.
    await service.initialize('test-app');
    client.permissionGranted = true;
    syncService.rows['user_notification_preferences:user-1'] =
        <String, dynamic>{
      'push_enabled': true,
      notifyDailyTagKey: true,
      notifyStreakTagKey: true,
      notifyReengagementTagKey: true,
      notifyWeeklyTagKey: true,
      notifyUpdatesTagKey: true,
    };

    final before = DateTime.now().toUtc();
    await service.getNotificationPreferences();
    final after = DateTime.now().toUtc();

    final stamp = syncService
            .rows['user_notification_preferences:user-1']
        ?['push_enabled_last_verified_at'] as String?;
    expect(stamp, isNotNull,
        reason: 'verified_at must be written when perm is granted');
    final parsed = DateTime.parse(stamp!).toUtc();
    expect(
      parsed.isAtSameMomentAs(before) || parsed.isAfter(before),
      isTrue,
      reason: 'verified_at must be >= test start time',
    );
    expect(
      parsed.isAtSameMomentAs(after) || parsed.isBefore(after),
      isTrue,
      reason: 'verified_at must be <= test end time',
    );
  });

  test(
      'getNotificationPreferences does NOT stamp verified_at when iOS perm is denied',
      () async {
    await service.initialize('test-app');
    client.permissionGranted = false;
    syncService.rows['user_notification_preferences:user-1'] =
        <String, dynamic>{
      'push_enabled': true,
      notifyDailyTagKey: true,
      notifyStreakTagKey: true,
      notifyReengagementTagKey: true,
      notifyWeeklyTagKey: true,
      notifyUpdatesTagKey: true,
    };

    await service.getNotificationPreferences();

    expect(
      syncService
              .rows['user_notification_preferences:user-1']
          ?['push_enabled_last_verified_at'],
      isNull,
      reason:
          'verified_at must NOT be stamped when reconcile flips push_enabled=false',
    );
  });

  test('optIn stamps push_enabled_last_verified_at on success', () async {
    await service.initialize('test-app');
    client.permissionGranted = true;

    final before = DateTime.now().toUtc();
    final result = await service.optIn();
    expect(result, isTrue);

    final stamp = syncService
            .rows['user_notification_preferences:user-1']
        ?['push_enabled_last_verified_at'] as String?;
    expect(stamp, isNotNull,
        reason: 'optIn() must stamp verified_at after granting perm');
    expect(DateTime.parse(stamp!).toUtc().isBefore(before), isFalse);
  });

  test('optIn does NOT stamp verified_at when iOS denies permission',
      () async {
    await service.initialize('test-app');
    client.permissionGranted = false;
    client.requestPermissionResult = false;

    final result = await service.optIn();
    expect(result, isFalse);
    expect(
      syncService
              .rows['user_notification_preferences:user-1']
          ?['push_enabled_last_verified_at'],
      isNull,
      reason: 'verified_at must NOT be stamped when permission is denied',
    );
  });

  test('getNotificationPreferences returns Supabase-backed preferences',
      () async {
    syncService.rows['user_notification_preferences:user-1'] =
        <String, dynamic>{
      notifyDailyTagKey: false,
      notifyStreakTagKey: true,
      notifyReengagementTagKey: false,
      notifyWeeklyTagKey: true,
      notifyUpdatesTagKey: false,
    };

    final preferences = await service.getNotificationPreferences();

    expect(preferences, <String, bool>{
      notifyDailyTagKey: false,
      notifyStreakTagKey: true,
      notifyReengagementTagKey: false,
      notifyWeeklyTagKey: true,
      notifyUpdatesTagKey: false,
    });
  });

  test(
      'getNotificationPreferences falls back to SharedPreferences when Supabase is unreachable',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'sakina_notification_pref_$notifyDailyTagKey:user-1', false);
    await prefs.setBool(
      'sakina_notification_pref_$notifyStreakTagKey:user-1',
      true,
    );
    await prefs.setBool(
      'sakina_notification_pref_$notifyReengagementTagKey:user-1',
      false,
    );
    await prefs.setBool(
      'sakina_notification_pref_$notifyWeeklyTagKey:user-1',
      true,
    );
    await prefs.setBool(
      'sakina_notification_pref_$notifyUpdatesTagKey:user-1',
      false,
    );
    SupabaseSyncService.debugSetInstance(
      ThrowingFetchRowSupabaseSyncService(userId: 'user-1'),
    );

    final preferences = await service.getNotificationPreferences();

    expect(preferences, <String, bool>{
      notifyDailyTagKey: false,
      notifyStreakTagKey: true,
      notifyReengagementTagKey: false,
      notifyWeeklyTagKey: true,
      notifyUpdatesTagKey: false,
    });
  });

  test(
      'setNotificationPreference writes to Supabase and SharedPreferences without touching OneSignal tags',
      () async {
    await service.setNotificationPreference(notifyDailyTagKey, false);

    final prefs = await SharedPreferences.getInstance();
    expect(
      syncService.upsertCalls,
      contains(
        containsPair('table', 'user_notification_preferences'),
      ),
    );
    expect(
      syncService.rows['user_notification_preferences:user-1']
          ?[notifyDailyTagKey],
      isFalse,
    );
    expect(
      prefs.getBool('sakina_notification_pref_$notifyDailyTagKey:user-1'),
      isFalse,
    );
    expect(client.tags, isEmpty);
  });

  test(
      'setNotificationPreference for notify_reengagement writes to Supabase and SharedPreferences without touching OneSignal tags',
      () async {
    await service.setNotificationPreference(notifyReengagementTagKey, false);

    final prefs = await SharedPreferences.getInstance();
    expect(
      syncService.rows['user_notification_preferences:user-1']
          ?[notifyReengagementTagKey],
      isFalse,
    );
    expect(
      prefs.getBool(
        'sakina_notification_pref_$notifyReengagementTagKey:user-1',
      ),
      isFalse,
    );
    expect(client.tags, isEmpty);
  });

  test(
      'setNotificationPreference for notify_weekly writes to Supabase and SharedPreferences without touching OneSignal tags',
      () async {
    await service.setNotificationPreference(notifyWeeklyTagKey, false);

    final prefs = await SharedPreferences.getInstance();
    expect(
      syncService.rows['user_notification_preferences:user-1']
          ?[notifyWeeklyTagKey],
      isFalse,
    );
    expect(
      prefs.getBool(
        'sakina_notification_pref_$notifyWeeklyTagKey:user-1',
      ),
      isFalse,
    );
    expect(client.tags, isEmpty);
  });

  test(
      'setNotificationPreference for notify_updates writes to Supabase and SharedPreferences without touching OneSignal tags',
      () async {
    await service.setNotificationPreference(notifyUpdatesTagKey, false);

    final prefs = await SharedPreferences.getInstance();
    expect(
      syncService.rows['user_notification_preferences:user-1']
          ?[notifyUpdatesTagKey],
      isFalse,
    );
    expect(
      prefs.getBool(
        'sakina_notification_pref_$notifyUpdatesTagKey:user-1',
      ),
      isFalse,
    );
    expect(client.tags, isEmpty);
  });

  test('click listener routes daily_reminder to home', () async {
    await service.initialize('app-id');
    service.addClickListener();

    client.dispatchClick(<String, dynamic>{'type': 'daily_reminder'});

    expect(navigatedRoutes, <String>['/']);
  });

  test('click listener routes streak_risk to home', () async {
    await service.initialize('app-id');
    service.addClickListener();

    client.dispatchClick(<String, dynamic>{'type': 'streak_risk'});

    expect(navigatedRoutes, <String>['/']);
  });

  test('click listener routes streak_milestone to home', () async {
    await service.initialize('app-id');
    service.addClickListener();

    client.dispatchClick(<String, dynamic>{'type': 'streak_milestone'});

    expect(navigatedRoutes, <String>['/']);
  });

  test('click listener routes weekly_reflection to journal', () async {
    await service.initialize('app-id');
    service.addClickListener();

    client.dispatchClick(<String, dynamic>{'type': 'weekly_reflection'});

    expect(navigatedRoutes, <String>['/journal']);
  });

  test('click listener routes reengagement to home', () async {
    await service.initialize('app-id');
    service.addClickListener();

    client.dispatchClick(<String, dynamic>{'type': 'reengagement'});

    expect(navigatedRoutes, <String>['/']);
  });

  test('click listener routes unknown and null types to home', () async {
    await service.initialize('app-id');
    service.addClickListener();

    client.dispatchClick(<String, dynamic>{'type': 'unexpected'});
    client.dispatchClick(null);

    expect(navigatedRoutes, <String>['/', '/']);
  });

  test('optOut writes push_enabled=false to Supabase without touching OneSignal',
      () async {
    await service.initialize('app-id');

    final isOptedIn = await service.optOut();

    expect(client.optOutCalled, isFalse); // no SDK opt-out anymore
    expect(isOptedIn, isFalse);
    expect(
      syncService.rows['user_notification_preferences:user-1']
          ?['push_enabled'],
      isFalse,
    );
  });

  test('optIn writes push_enabled=true to Supabase without touching OneSignal',
      () async {
    await service.initialize('app-id');
    client.permissionGranted = true;

    final isOptedIn = await service.optIn();

    expect(client.optInCalled, isFalse); // no SDK opt-in anymore
    expect(isOptedIn, isTrue);
    expect(
      syncService.rows['user_notification_preferences:user-1']
          ?['push_enabled'],
      isTrue,
    );
  });

  test('optIn returns false and writes push_enabled=false when iOS denies permission',
      () async {
    await service.initialize('app-id');
    client.permissionGranted = false;
    client.requestPermissionResult = false; // user taps "Don't Allow"

    final isOptedIn = await service.optIn();

    expect(isOptedIn, isFalse);
    expect(
      syncService.rows['user_notification_preferences:user-1']
          ?['push_enabled'],
      isFalse,
    );
  });

  test('identifyUser calls OneSignal.login with the correct userId', () async {
    await service.initialize('app-id');

    await service.identifyUser('user-123');

    expect(client.loginUserIds, <String>['user-123']);
  });

  test('identifyUser does not relogin the same user repeatedly', () async {
    await service.initialize('app-id');

    await service.identifyUser('user-123');
    await service.identifyUser('user-123');

    expect(client.loginUserIds, <String>['user-123']);
  });

  test('initialize with an empty appId is a no-op', () async {
    await service.initialize('');

    expect(client.initializedAppIds, isEmpty);
  });
}
