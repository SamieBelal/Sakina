import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/widget_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// Records the skin pushes instead of touching the platform channel.
class _RecordingWidgetData extends WidgetDataService {
  final List<String> pushed = <String>[];

  @override
  Future<void> setEquippedLanternSkin(String skinId) async => pushed.add(skinId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _RecordingWidgetData widgetData;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    widgetData = _RecordingWidgetData();
  });

  tearDown(SupabaseSyncService.debugReset);

  test('a successful skin equip pushes the skin to the widget', () async {
    fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

    final result = await equipCosmetic(
      itemType: itemTypeLanternSkin,
      itemId: 'emerald_jade',
      widgetData: widgetData,
    );

    expect(result.success, isTrue);
    expect(widgetData.pushed, <String>['emerald_jade']);
  });

  test('a backdrop equip never touches the widget (backdrops are in-app only)',
      () async {
    fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

    await equipCosmetic(
      itemType: itemTypeBackdrop,
      itemId: 'laylat_night',
      widgetData: widgetData,
    );

    expect(widgetData.pushed, isEmpty);
  });

  test('a rejected equip does not push a skin the server refused', () async {
    // No handler → callRpc returns null (the RPC raised).
    final result = await equipCosmetic(
      itemType: itemTypeLanternSkin,
      itemId: 'emerald_jade',
      widgetData: widgetData,
    );

    expect(result.success, isFalse);
    expect(widgetData.pushed, isEmpty);
  });
}
