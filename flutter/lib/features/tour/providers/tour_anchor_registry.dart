import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/onboarding_tour_step.dart';

/// Maps (surface, anchorId) → live `GlobalKey` so the tour overlay can find
/// any anchor at runtime. Screens register their anchors via the
/// `TourAnchor` widget on mount and unregister on dispose.
///
/// Backed by `ChangeNotifier` so listeners (the OverlayHost) rebuild when
/// an anchor appears or disappears.
class TourAnchorRegistry extends ChangeNotifier {
  final Map<_AnchorId, GlobalKey> _keys = {};

  GlobalKey? lookup(TourSurface surface, String anchorId) =>
      _keys[_AnchorId(surface, anchorId)];

  void register(TourSurface surface, String anchorId, GlobalKey key) {
    final id = _AnchorId(surface, anchorId);
    // Idempotent — re-registering the same key is a no-op (Flutter hot
    // reload can cause double-register). Different key for same id means
    // a screen remounted with a fresh key; accept the new one.
    if (_keys[id] == key) return;
    _keys[id] = key;
    notifyListeners();
  }

  void unregister(TourSurface surface, String anchorId, GlobalKey key) {
    final id = _AnchorId(surface, anchorId);
    // Only remove if the registered key matches. Avoids unregistering a
    // fresh registration that arrived after a hot-reload race.
    if (_keys[id] != key) return;
    _keys.remove(id);
    notifyListeners();
  }

  @visibleForTesting
  bool hasAnchor(TourSurface surface, String anchorId) =>
      _keys.containsKey(_AnchorId(surface, anchorId));

  @visibleForTesting
  int get anchorCount => _keys.length;
}

@immutable
class _AnchorId {
  const _AnchorId(this.surface, this.anchorId);
  final TourSurface surface;
  final String anchorId;

  @override
  bool operator ==(Object other) =>
      other is _AnchorId &&
      other.surface == surface &&
      other.anchorId == anchorId;

  @override
  int get hashCode => Object.hash(surface, anchorId);
}

final tourAnchorRegistryProvider = ChangeNotifierProvider<TourAnchorRegistry>(
  (_) => TourAnchorRegistry(),
);
