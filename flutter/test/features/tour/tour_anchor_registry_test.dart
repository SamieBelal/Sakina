import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/tour/models/onboarding_tour_step.dart';
import 'package:sakina/features/tour/providers/tour_anchor_registry.dart';

void main() {
  group('TourAnchorRegistry', () {
    test('register stores key and notifies listeners', () {
      final registry = TourAnchorRegistry();
      var notified = 0;
      registry.addListener(() => notified++);
      final key = GlobalKey();
      registry.register(TourSurface.home, 'beginMuhasabahCta', key);
      expect(registry.lookup(TourSurface.home, 'beginMuhasabahCta'), key);
      expect(notified, 1);
    });

    test('lookup returns null for unregistered anchor', () {
      final registry = TourAnchorRegistry();
      expect(registry.lookup(TourSurface.home, 'nope'), isNull);
    });

    test('unregister removes key and notifies', () {
      final registry = TourAnchorRegistry();
      final key = GlobalKey();
      registry.register(TourSurface.duas, 'buildCta', key);
      var notified = 0;
      registry.addListener(() => notified++);
      registry.unregister(TourSurface.duas, 'buildCta', key);
      expect(registry.lookup(TourSurface.duas, 'buildCta'), isNull);
      expect(notified, 1);
    });

    test('register same key for same id is idempotent (no double-notify)', () {
      final registry = TourAnchorRegistry();
      final key = GlobalKey();
      registry.register(TourSurface.home, 'beginMuhasabahCta', key);
      var notified = 0;
      registry.addListener(() => notified++);
      registry.register(TourSurface.home, 'beginMuhasabahCta', key);
      expect(notified, 0, reason: 'Same key+id should not re-notify');
    });

    test('different surfaces with same anchorId are independent', () {
      final registry = TourAnchorRegistry();
      final a = GlobalKey();
      final b = GlobalKey();
      registry.register(TourSurface.home, 'streakPill', a);
      registry.register(TourSurface.collection, 'streakPill', b);
      expect(registry.lookup(TourSurface.home, 'streakPill'), a);
      expect(registry.lookup(TourSurface.collection, 'streakPill'), b);
      expect(registry.anchorCount, 2);
    });

    test('unregister with mismatched key does NOT remove (avoids hot-reload race)',
        () {
      final registry = TourAnchorRegistry();
      final original = GlobalKey();
      final ghost = GlobalKey();
      registry.register(TourSurface.home, 'streakPill', original);
      registry.unregister(TourSurface.home, 'streakPill', ghost);
      // Original still registered.
      expect(registry.lookup(TourSurface.home, 'streakPill'), original);
    });

    test('re-register with different key replaces (screen remount)', () {
      final registry = TourAnchorRegistry();
      final first = GlobalKey();
      final second = GlobalKey();
      registry.register(TourSurface.home, 'streakPill', first);
      registry.register(TourSurface.home, 'streakPill', second);
      expect(registry.lookup(TourSurface.home, 'streakPill'), second);
    });
  });
}
