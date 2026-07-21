import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:sakina/core/constants/allah_names.dart';
import 'package:sakina/services/location_service.dart';

/// App Group container shared between the Flutter app and the iOS WidgetKit
/// extension. MUST match the App Group capability added to BOTH the Runner and
/// the widget-extension targets in Xcode. See §10.8 of the widget design spec.
const String kWidgetAppGroupId = 'group.com.sakina.app.widget';

/// The `kind` of the iOS widget (WidgetKit `IntentConfiguration`/`Widget`) and
/// the Android provider name. Passed to [HomeWidget.updateWidget].
const String kWidgetName = 'SakinaWidget';

/// The `kind` of the companion (lantern) widget. A THIRD widget in
/// `SakinaWidgetBundle` that reads the SAME [kWidgetPayloadKey] blob and renders
/// the pre-rendered lantern frame for the current streak state. Reloaded
/// alongside [kWidgetName] whenever the streak payload changes.
const String kCompanionWidgetName = 'SakinaCompanionWidget';

/// The single Shared-container key the extension reads. One JSON blob keeps the
/// read atomic on the Swift side.
const String kWidgetPayloadKey = 'sakina_widget_payload';

/// The `kind` of the iOS duʿā-times widget (WidgetKit `Widget`). A SECOND widget
/// in `SakinaWidgetBundle`, distinct from [kWidgetName]. Passed to
/// [HomeWidget.updateWidget] to reload only that widget's timeline (spec §7).
const String kDuaTimesWidgetName = 'SakinaDuaTimesWidget';

/// Shared-container key the duʿā-times extension reads. Holds the JSON-encoded
/// `DuaWindowSchedule` (spec §7). Kept separate from [kWidgetPayloadKey] so the
/// two widgets never contend for the same blob.
const String kDuaTimesPayloadKey = 'sakina_dua_times_payload';

/// Immutable, JSON-serialisable widget payload. Mirrors §4.3 of the spec.
///
/// The extension ONLY trusts [nameKey]/[anchor] when [checkedInToday] is true
/// AND [updatedAtIso] is from the current local day; otherwise it computes the
/// daily Name from its bundled catalog. [streak] is always shown from the last
/// written value.
class WidgetNamePayload {
  const WidgetNamePayload({
    required this.mode,
    required this.nameKey,
    required this.name,
    required this.nameEnglish,
    required this.arabic,
    required this.transliteration,
    required this.anchor,
    required this.checkedInToday,
    required this.streak,
    required this.updatedAtIso,
  });

  /// `personalized` = show [nameKey]; `daily` = extension picks the daily Name.
  final String mode;
  final String nameKey;
  final String name;
  final String nameEnglish;
  final String arabic;
  final String transliteration;
  final String anchor;
  final bool checkedInToday;
  final int streak;
  final String updatedAtIso;

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'name_key': nameKey,
        'name': name,
        'name_english': nameEnglish,
        'arabic': arabic,
        'transliteration': transliteration,
        'anchor': anchor,
        'checked_in_today': checkedInToday,
        'streak': streak,
        'updated_at': updatedAtIso,
      };

  String encode() => jsonEncode(toJson());
}

/// Thin seam over the `home_widget` static API so [WidgetDataService] is unit
/// testable without the platform channel. The default delegates to the plugin.
abstract class HomeWidgetClient {
  Future<void> setAppGroupId(String id);
  Future<void> saveWidgetData(String key, String? value);
  Future<void> updateWidget({required String name});
}

class _PluginHomeWidgetClient implements HomeWidgetClient {
  const _PluginHomeWidgetClient();

  @override
  Future<void> setAppGroupId(String id) => HomeWidget.setAppGroupId(id);

  @override
  Future<void> saveWidgetData(String key, String? value) =>
      HomeWidget.saveWidgetData<String?>(key, value);

  @override
  Future<void> updateWidget({required String name}) =>
      HomeWidget.updateWidget(iOSName: name, name: name);
}

/// Single writer of home-screen widget state.
///
/// Call [syncWidget] from the data-sync completion (see §10.4) rather than
/// scattering calls across feature sites. Call [clearWidget] on sign-out and
/// account deletion so a second user on the device never sees the first user's
/// streak or Name (§10.5).
class WidgetDataService {
  WidgetDataService({
    HomeWidgetClient? client,
    DateTime Function()? clock,
    LocationService? locationService,
  })  : _client = client ?? const _PluginHomeWidgetClient(),
        _clock = clock ?? DateTime.now,
        _location = locationService ?? LocationService();

  final HomeWidgetClient _client;
  final DateTime Function() _clock;
  final LocationService _location;

  /// Last serialized payload written this process — the perf guard (§10.4):
  /// skip [HomeWidget.updateWidget] when nothing changed.
  String? _lastWritten;

  /// Last duʿā-times schedule JSON written this process — the same perf guard
  /// as [_lastWritten], but for the duʿā-times widget. Skips the save +
  /// WidgetKit reload when the schedule is byte-identical (spec §7: the
  /// ~40-70/day reload budget is easy to burn on every foreground rebuild).
  String? _lastDuaTimesWritten;

  /// Register the App Group. Call once from `main()` before `runApp`.
  Future<void> initialize() async {
    await _client.setAppGroupId(kWidgetAppGroupId);
  }

  /// Compose the payload for [name] and push it to the widget. Only reloads the
  /// timeline when the serialized payload actually changed.
  ///
  /// [personalized] true means [name] is the Name the user received in today's
  /// muḥāsabah; false means it's the deterministic daily Name (a hint — the
  /// extension may recompute it offline).
  Future<void> syncWidget({
    required AllahName name,
    required String anchor,
    required int streak,
    required bool checkedInToday,
    required bool personalized,
  }) async {
    final payload = WidgetNamePayload(
      mode: personalized ? 'personalized' : 'daily',
      nameKey: widgetNameKeyFor(name),
      name: name.transliteration,
      nameEnglish: name.english,
      arabic: name.arabic,
      transliteration: name.transliteration,
      anchor: anchor,
      checkedInToday: checkedInToday,
      streak: streak,
      // UTC + trailing 'Z' so the Swift ISO8601DateFormatter can parse it; the
      // extension compares it against the current LOCAL day (§10.7).
      updatedAtIso: _clock().toUtc().toIso8601String(),
    );
    await _write(payload.encode());
  }

  /// Push a precomputed duʿā-window schedule (already JSON-encoded by the engine
  /// per the §7 serialization contract) to the duʿā-times widget, then reload its
  /// timeline. The extension decodes it from the App Group; when it is missing,
  /// stale, or the travel guard trips, the widget falls back to its bundled
  /// calendar (spec §9/§10).
  ///
  /// Signature is a fixed contract — the `dua_window_provider` calls this exact
  /// shape. Do not change it.
  Future<void> saveDuaTimesSchedule(String scheduleJson) async {
    // Perf guard (spec §7): the provider rebuilds + pushes on every foreground,
    // date-rollover, and tick-driven rebuild. A WidgetKit reload per push burns
    // the ~40-70/day budget fast, so skip the save + reload when the schedule
    // is byte-identical to the last one written this process.
    if (scheduleJson == _lastDuaTimesWritten) return;
    _lastDuaTimesWritten = scheduleJson;
    await _client.saveWidgetData(kDuaTimesPayloadKey, scheduleJson);
    await _client.updateWidget(name: kDuaTimesWidgetName);
  }

  /// Wipe personalized state from the shared container and revert the widgets to
  /// their daily/calendar fallbacks. MUST run on sign-out and account deletion.
  ///
  /// Also nulls [kDuaTimesPayloadKey] so a second user on the device never
  /// inherits the first user's location-derived schedule — which would leak
  /// their approximate home location (spec §7 privacy fix).
  Future<void> clearWidget() async {
    await _client.saveWidgetData(kWidgetPayloadKey, null);
    await _client.saveWidgetData(kDuaTimesPayloadKey, null);
    // Also wipe the raw coarse lat/lon cache: nulling the derived schedule isn't
    // enough — the next user's rebuild would re-derive precise times from the
    // first user's cached location (spec §7 privacy fix).
    await _location.clearCache();
    _lastWritten = null;
    _lastDuaTimesWritten = null;
    await _client.updateWidget(name: kWidgetName);
    await _client.updateWidget(name: kCompanionWidgetName);
    await _client.updateWidget(name: kDuaTimesWidgetName);
  }

  Future<void> _write(String encoded) async {
    // `updated_at` changes every call, so compare on the semantic payload minus
    // the timestamp — otherwise the guard never fires.
    final comparable = _stripTimestamp(encoded);
    if (comparable == _lastWritten) return;
    _lastWritten = comparable;
    await _client.saveWidgetData(kWidgetPayloadKey, encoded);
    await _client.updateWidget(name: kWidgetName);
    // The companion widget reads the same blob — reload its timeline too so its
    // lantern brightness tracks the streak.
    await _client.updateWidget(name: kCompanionWidgetName);
  }

  String _stripTimestamp(String encoded) {
    final map = jsonDecode(encoded) as Map<String, dynamic>;
    map.remove('updated_at');
    return jsonEncode(map);
  }
}

/// Global instance, matching the codebase's `supabaseSyncService` pattern.
final WidgetDataService widgetDataService = WidgetDataService();
