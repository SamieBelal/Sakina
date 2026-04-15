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
  bool throwOnGetTags = false;
  final Map<String, String> tags = <String, String>{};
  final List<List<String>> removedTagCalls = <List<String>>[];
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
  Future<void> addTags(Map<String, String> newTags) async {
    tags.addAll(newTags);
  }

  @override
  Future<void> removeTags(List<String> keys) async {
    removedTagCalls.add(keys);
    for (final key in keys) {
      tags.remove(key);
    }
  }

  @override
  Future<Map<String, String>> getTags() async {
    if (throwOnGetTags) {
      throw Exception('OneSignal unreachable');
    }
    return Map<String, String>.from(tags);
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeOneSignalClient client;
  late NotificationService service;
  late List<String> navigatedRoutes;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SupabaseSyncService.debugSetInstance(
        FakeSupabaseSyncService(userId: 'user-1'));
    client = FakeOneSignalClient();
    navigatedRoutes = <String>[];
    service = NotificationService(
      client: client,
      routeNavigator: navigatedRoutes.add,
    );
  });

  tearDown(SupabaseSyncService.debugReset);

  test('updateCheckinTags computes correct tag values from inputs', () async {
    await service.initialize('app-id');
    final checkin = DateTime.utc(2026, 4, 14, 14, 30);

    await service.updateCheckinTags(
      streakCount: 12,
      lastCheckinDate: checkin,
    );

    expect(client.tags[streakCountTagKey], '12');
    expect(client.tags[lastCheckinDateTagKey], checkin.toIso8601String());
  });

  test('getNotificationPreferences parses OneSignal tags correctly', () async {
    await service.initialize('app-id');
    client.tags.addAll(<String, String>{
      notifyDailyTagKey: 'false',
      notifyStreakTagKey: 'true',
    });

    final preferences = await service.getNotificationPreferences();

    expect(preferences, <String, bool>{
      notifyDailyTagKey: false,
      notifyStreakTagKey: true,
    });
  });

  test(
      'getNotificationPreferences falls back to SharedPreferences when OneSignal is unreachable',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'sakina_notification_pref_$notifyDailyTagKey:user-1', false);
    await prefs.setBool(
      'sakina_notification_pref_$notifyStreakTagKey:user-1',
      true,
    );
    await service.initialize('app-id');
    client.throwOnGetTags = true;

    final preferences = await service.getNotificationPreferences();

    expect(preferences, <String, bool>{
      notifyDailyTagKey: false,
      notifyStreakTagKey: true,
    });
  });

  test(
      'setNotificationPreference writes to OneSignal tags and SharedPreferences',
      () async {
    await service.initialize('app-id');

    await service.setNotificationPreference(notifyDailyTagKey, false);

    final prefs = await SharedPreferences.getInstance();
    expect(client.tags[notifyDailyTagKey], 'false');
    expect(
      prefs.getBool('sakina_notification_pref_$notifyDailyTagKey:user-1'),
      isFalse,
    );
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

  test('click listener routes unknown and null types to home', () async {
    await service.initialize('app-id');
    service.addClickListener();

    client.dispatchClick(<String, dynamic>{'type': 'unexpected'});
    client.dispatchClick(null);

    expect(navigatedRoutes, <String>['/', '/']);
  });

  test('optOut calls pushSubscription.optOut', () async {
    await service.initialize('app-id');

    final isOptedIn = await service.optOut();

    expect(client.optOutCalled, isTrue);
    expect(isOptedIn, isFalse);
  });

  test('optIn calls pushSubscription.optIn', () async {
    await service.initialize('app-id');
    client.permissionGranted = true;

    final isOptedIn = await service.optIn();

    expect(client.optInCalled, isTrue);
    expect(isOptedIn, isTrue);
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

  test('refreshSessionTags sets all expected tags', () async {
    await service.initialize('app-id');
    final checkin = DateTime.utc(2026, 4, 13, 22, 15);

    await service.refreshSessionTags(
      streakCount: 9,
      lastCheckinDate: checkin,
    );

    expect(client.tags, containsPair(streakCountTagKey, '9'));
    expect(client.tags,
        containsPair(lastCheckinDateTagKey, checkin.toIso8601String()));
  });
}
