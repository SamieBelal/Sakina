import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/constants/allah_names.dart';
import '../features/streaks/widgets/cosmetics/cosmetic_catalog_ui.dart';
import 'checkin_history_service.dart';
import 'cosmetics_service.dart';
import 'purchase_service.dart';
import 'streak_service.dart';
import 'widget_analytics.dart';
import 'widget_data_service.dart';

/// Resolved inputs for a home-screen widget refresh.
class WidgetSyncInputs {
  const WidgetSyncInputs({
    required this.name,
    required this.personalized,
    required this.checkedInToday,
  });

  final AllahName name;
  final bool personalized;
  final bool checkedInToday;
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Pure: decide which Name the widget shows. If the user checked in today, show
/// the Name they received (personalized); otherwise the deterministic daily
/// Name. Local-time day boundary, matching `getTodaysName()` (spec §10.4/§5.5).
WidgetSyncInputs composeWidgetSyncState({
  required List<CheckInRecord> history,
  required AllahName todaysName,
  required DateTime now,
}) {
  final today = _ymd(now);
  for (final r in history) {
    if (r.date == today) {
      final matched = allahNames.firstWhere(
        (n) => n.transliteration == r.nameReturned,
        orElse: () => todaysName,
      );
      return WidgetSyncInputs(
          name: matched, personalized: true, checkedInToday: true);
    }
  }
  return WidgetSyncInputs(
      name: todaysName, personalized: false, checkedInToday: false);
}

/// Loads the committed anchor snapshot from the app bundle (the same file the
/// build-time catalog generator reads). Cached after first load.
class WidgetAnchorCatalog {
  Map<String, String>? _cache;

  Future<Map<String, String>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle
        .loadString('assets/widget/name_anchors_snapshot.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = {
      for (final e in json.entries)
        if (!e.key.startsWith('_')) e.key: e.value as String,
    };
    return _cache!;
  }

  Future<String> anchorFor(AllahName name) async {
    final map = await _load();
    return map[widgetNameKeyFor(name)] ?? name.lesson;
  }
}

final WidgetAnchorCatalog _anchorCatalog = WidgetAnchorCatalog();

/// The lantern skin the widget payload should carry. Reads the cosmetics cache
/// (hydrated from `sync_all_user_data`); a failed read must never stop a widget
/// refresh, so it degrades to the widget default rather than throwing.
///
/// Resolved through the SHARED [renderableSkinId] — the same
/// `owned || (premium-exclusive && premium)` gate the Companion stage and the
/// Wardrobe preview use. The home-screen widget is a third render surface for
/// the equipped lantern, and reading `equippedLanternSkin` raw made it the one
/// surface with no entitlement check: a lapsed subscriber's widget would keep
/// showing a premium-exclusive skin indefinitely. (Not reachable today only
/// because no premium-exclusive skin is in [kWidgetBundledSkinIds] — luck, not
/// design.) [widgetEligibleSkinId] still runs after this, as the separate
/// bundled-frames budget filter it is.
///
/// [readCosmetics] / [readPremium] are injectable for tests; production uses
/// [getCosmeticsState] and [PurchaseService.isPremium].
Future<String> resolveWidgetLanternSkin({
  Future<CosmeticsState> Function()? readCosmetics,
  Future<bool> Function()? readPremium,
}) async {
  try {
    final state = await (readCosmetics ?? getCosmeticsState)();
    final isPremium =
        await (readPremium ?? () => PurchaseService().isPremium())();
    return renderableSkinId(state, isPremium: isPremium);
  } catch (_) {
    return kDefaultWidgetLanternSkinId;
  }
}

/// Compose current widget state from caches and push it. Fire-and-forget from
/// the data-sync completion (§10.4); never throws into the caller.
Future<void> syncHomeWidget({DateTime Function()? clock}) async {
  try {
    final now = (clock ?? DateTime.now)();
    final history = await getCheckinHistory();
    final streak = (await getStreak()).currentStreak;
    final inputs = composeWidgetSyncState(
      history: history,
      todaysName: getTodaysName(),
      now: now,
    );
    final anchor = await _anchorCatalog.anchorFor(inputs.name);
    final lanternSkinId = await resolveWidgetLanternSkin();
    await widgetDataService.syncWidget(
      name: inputs.name,
      anchor: anchor,
      streak: streak,
      checkedInToday: inputs.checkedInToday,
      personalized: inputs.personalized,
      lanternSkinId: lanternSkinId,
    );
    // Adoption snapshot (once per session) — piggybacks on the sync that runs
    // on foreground, so we learn who has the widget without an extra trigger.
    await reportWidgetInstallState();
  } catch (_) {
    // Widget refresh is best-effort; a failure must not break app sync.
  }
}
