import 'package:flutter_test/flutter_test.dart';

import 'package:sakina/features/dua_times/models/dua_window.dart';
import 'package:sakina/features/dua_times/models/dua_window_type.dart';
import 'package:sakina/services/dua_live_activity_service.dart';

/// Fake channel recording every native call, so the service's decision logic is
/// tested without the platform channel — mirrors the `_FakeWidgetClient` pattern
/// in dua_times_card_test.dart.
class _FakeChannel implements LiveActivityChannel {
  _FakeChannel({this.supported = true});

  bool supported;
  bool throwOnStart = false;

  final List<String> calls = <String>[];
  final List<Map<String, dynamic>> starts = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updates = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> ends = <Map<String, dynamic>>[];

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<void> start(Map<String, dynamic> content) async {
    if (throwOnStart) throw Exception('boom');
    calls.add('start');
    starts.add(content);
  }

  @override
  Future<void> update(Map<String, dynamic> content) async {
    calls.add('update');
    updates.add(content);
  }

  @override
  Future<void> end(Map<String, dynamic> args) async {
    calls.add('end');
    ends.add(args);
  }
}

DuaWindow _window({
  DuaWindowType type = DuaWindowType.lastThirdOfNight,
  DateTime? endUtc,
  bool isAllDay = false,
}) {
  return DuaWindow(
    type: type,
    tier: DuaWindowTier.hero,
    titleKey: 'dua_window.last_third.title',
    sourceRef: 'al-Bukhari 1145',
    startUtc: DateTime.utc(2027, 5, 15, 22, 0),
    endUtc: endUtc ?? DateTime.utc(2027, 5, 16, 2, 0),
    isAllDay: isAllDay,
    locationDependent: true,
  );
}

void main() {
  group('DuaLiveActivityContent — wire contract (golden)', () {
    test('toMap emits exactly the agreed keys, nothing else', () {
      final content = DuaLiveActivityContent.fromWindow(
        _window(),
        UrgencyState.closing,
      );
      final map = content.toMap();
      // A silent key rename here leaves the Live Activity blank on device (the
      // exact drift class hit on the notifications PR) — pin the keys.
      expect(
        map.keys.toSet(),
        {'window_type', 'end_utc_millis', 'urgency', 'is_all_day', 'deep_link'},
      );
      expect(map['window_type'], 'last_third_of_night');
      expect(map['end_utc_millis'],
          DateTime.utc(2027, 5, 16, 2, 0).millisecondsSinceEpoch);
      expect(map['urgency'], 'closing');
      expect(map['is_all_day'], false);
      expect(map['deep_link'], 'sakina://widget/build-dua?source=live_activity');
    });

    test('deep link carries the live_activity source tag (correction #5)', () {
      expect(kDuaLiveActivityDeepLink, contains('source=live_activity'));
    });

    test('windowKey ignores urgency; signature includes it', () {
      final a = DuaLiveActivityContent.fromWindow(
          _window(), UrgencyState.comfortable);
      final b =
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.closing);
      expect(a.windowKey, b.windowKey); // same window instance
      expect(a.signature, isNot(b.signature)); // urgency escalated
    });
  });

  group('DuaLiveActivityService — lifecycle decisions', () {
    test('starts once when a window becomes active', () async {
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);
      final content =
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.closing);

      final result = await svc.sync(content);

      expect(result.transition, LiveActivityTransition.started);
      expect(channel.calls, ['start']);
      expect(svc.currentWindowType, 'last_third_of_night');
    });

    test('perf guard: identical content → no repeat native call', () async {
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);
      final content =
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.closing);

      await svc.sync(content);
      final second = await svc.sync(content);

      expect(second.transition, LiveActivityTransition.none);
      expect(channel.calls, ['start']); // only the first start
    });

    test('same window, escalated urgency → update in place', () async {
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);
      await svc.sync(
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.comfortable));

      final result = await svc.sync(
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.lastCall));

      expect(result.transition, LiveActivityTransition.updated);
      expect(channel.calls, ['start', 'update']);
    });

    test('different window → end old + start new (replace)', () async {
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);
      await svc.sync(DuaLiveActivityContent.fromWindow(
          _window(type: DuaWindowType.lastThirdOfNight), UrgencyState.closing));

      final result = await svc.sync(DuaLiveActivityContent.fromWindow(
          _window(
              type: DuaWindowType.fridayHour,
              endUtc: DateTime.utc(2027, 5, 16, 18, 0)),
          UrgencyState.comfortable));

      expect(result.transition, LiveActivityTransition.replaced);
      expect(result.endedWindowType, 'last_third_of_night');
      expect(channel.calls, ['start', 'end', 'start']);
      expect(svc.currentWindowType, 'friday_hour');
    });

    test('end when live → returns type + native end with final_build_state',
        () async {
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);
      await svc.sync(
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.closing));

      final ended = await svc.end();

      expect(ended, 'last_third_of_night');
      expect(channel.calls, ['start', 'end']);
      expect(channel.ends.single['final_build_state'], true);
      expect(svc.currentWindowType, isNull);
    });

    test('routine end when nothing live → no-op, returns null (no spam)',
        () async {
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);

      final ended = await svc.end();

      expect(ended, isNull);
      expect(channel.calls, isEmpty);
    });

    test('force end when nothing live → dispatches native end-all (orphan-safe)',
        () async {
      // Sign-out path: even with no in-memory activity, an orphan from a killed
      // prior session must be torn down before the next user.
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);

      final ended = await svc.end(immediate: true, force: true);

      expect(ended, isNull); // nothing we owned
      expect(channel.calls, ['end']); // but native end-all still fired
      expect(channel.ends.single['immediate'], true);
      expect(channel.ends.single['final_build_state'], false);
    });

    test('immediate end of a live activity → immediate flag, no grace card',
        () async {
      final channel = _FakeChannel();
      final svc = DuaLiveActivityService(channel: channel);
      await svc.sync(
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.closing));

      final ended = await svc.end(immediate: true, force: true);

      expect(ended, 'last_third_of_night');
      expect(channel.ends.single['immediate'], true);
      expect(channel.ends.single['final_build_state'], false);
    });

    test('unsupported OS → sync no-ops, no channel calls', () async {
      final channel = _FakeChannel(supported: false);
      final svc = DuaLiveActivityService(channel: channel);

      final result = await svc.sync(
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.closing));

      expect(result.transition, LiveActivityTransition.none);
      expect(channel.calls, isEmpty);
      expect(svc.currentWindowType, isNull);
    });

    test('channel error is swallowed (never throws, stays unstarted)', () async {
      final channel = _FakeChannel()..throwOnStart = true;
      final svc = DuaLiveActivityService(channel: channel);

      final result = await svc.sync(
          DuaLiveActivityContent.fromWindow(_window(), UrgencyState.closing));

      expect(result.transition, LiveActivityTransition.none);
      expect(svc.currentWindowType, isNull); // start threw → nothing live
    });
  });
}
