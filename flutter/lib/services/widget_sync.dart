import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../core/constants/allah_names.dart';
import 'checkin_history_service.dart';
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
    await widgetDataService.syncWidget(
      name: inputs.name,
      anchor: anchor,
      streak: streak,
      checkedInToday: inputs.checkedInToday,
      personalized: inputs.personalized,
    );
    // Adoption snapshot (once per session) — piggybacks on the sync that runs
    // on foreground, so we learn who has the widget without an extra trigger.
    await reportWidgetInstallState();
  } catch (_) {
    // Widget refresh is best-effort; a failure must not break app sync.
  }
}
