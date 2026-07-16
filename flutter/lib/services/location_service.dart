import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A coarse, cached device location for prayer-time computation.
///
/// [fromCache] is true when this was read from SharedPreferences rather than a
/// fresh fix (offline / permission not re-prompted).
@immutable
class CoarseLocation {
  const CoarseLocation({
    required this.lat,
    required this.lon,
    required this.fromCache,
  });

  final double lat;
  final double lon;
  final bool fromCache;

  @override
  bool operator ==(Object other) =>
      other is CoarseLocation &&
      other.lat == lat &&
      other.lon == lon &&
      other.fromCache == fromCache;

  @override
  int get hashCode => Object.hash(lat, lon, fromCache);

  @override
  String toString() =>
      'CoarseLocation(lat: $lat, lon: $lon, fromCache: $fromCache)';
}

/// Wraps `geolocator` with a SharedPreferences cache so the duʿā-times feature
/// works offline and never re-prompts on every launch (spec §4/§10).
///
/// Design rules (spec §12/§15):
/// - **Coarse accuracy only** — prayer times need city-level precision, not
///   navigation-grade. Ships coarse for App Store data-minimization.
/// - **Lazy prompt** — permission is requested only when a caller explicitly
///   invokes [ensurePermission]/[getCoarseLocation], never on construction.
/// - **Graceful degrade** — permission denied / services off ⇒ returns `null`
///   (or the last cache) so callers fall back to calendar-only windows.
///
/// No Riverpod / Supabase (pure service, per `CLAUDE.md`). Injectable seams
/// ([checkPermission]/[requestPermission]/[serviceEnabled]/[currentPosition])
/// keep it unit-testable without a platform channel.
class LocationService {
  LocationService({
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<bool> Function()? serviceEnabled,
    Future<Position> Function()? currentPosition,
    Future<bool> Function()? openAppSettings,
    Future<SharedPreferences> Function()? prefs,
  })  : _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _serviceEnabled = serviceEnabled ?? Geolocator.isLocationServiceEnabled,
        _currentPosition = currentPosition ?? _defaultCurrentPosition,
        _openAppSettings = openAppSettings ?? Geolocator.openAppSettings,
        _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<bool> Function() _serviceEnabled;
  final Future<Position> Function() _currentPosition;
  final Future<bool> Function() _openAppSettings;
  final Future<SharedPreferences> Function() _prefs;

  /// SharedPreferences keys for the cached coarse fix. Not user-scoped: a coarse
  /// city is not per-account data, and the widget sign-out wipe (spec §7) clears
  /// the *derived schedule*, not this raw cache.
  static const String _latKey = 'dua_times_last_lat';
  static const String _lonKey = 'dua_times_last_lon';

  /// Coarse-accuracy request settings shared by fresh fixes.
  static const LocationSettings _coarseSettings =
      LocationSettings(accuracy: LocationAccuracy.low);

  static Future<Position> _defaultCurrentPosition() =>
      Geolocator.getCurrentPosition(locationSettings: _coarseSettings);

  /// Current permission state WITHOUT prompting. Callers use this to decide
  /// whether to show an "Enable precise times" affordance.
  Future<LocationPermission> permissionState() => _checkPermission();

  /// True when location permission is granted (while-in-use or always).
  Future<bool> hasPermission() async {
    final p = await _checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Lazily request permission (the ONLY method that prompts). Returns the
  /// resulting state. Callers invoke this from an explicit user affordance, not
  /// on launch. Returns the existing state without prompting if already granted
  /// or permanently denied.
  Future<LocationPermission> ensurePermission() async {
    var permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermission();
    }
    return permission;
  }

  /// Ensure permission for an explicit user tap ("Turn on precise times").
  ///
  /// - `denied` (askable) ⇒ show the system prompt.
  /// - `deniedForever` ⇒ iOS/Android won't re-show the prompt after a "Never",
  ///   so route the user to the OS app-settings page instead. Otherwise the
  ///   button would silently do nothing.
  ///
  /// Returns `true` only when permission ended up granted in-flow. When we open
  /// Settings we return `false` — the actual grant is picked up when the app
  /// returns to the foreground and the schedule rebuilds.
  Future<bool> ensureOrOpenSettings() async {
    final permission = await ensurePermission();
    if (permission == LocationPermission.deniedForever) {
      await _openAppSettings();
      return false;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Fetch a coarse location, degrading gracefully.
  ///
  /// - Services off or permission denied/deniedForever ⇒ returns the cached fix
  ///   if present (so offline still works), else `null` (calendar-only).
  /// - [prompt] true ⇒ lazily request permission first (§15 lazy prompt).
  /// - On a successful fresh fix, caches lat/lon for offline reuse.
  Future<CoarseLocation?> getCoarseLocation({bool prompt = false}) async {
    try {
      if (!await _serviceEnabled()) {
        return await _cached();
      }

      var permission = await _checkPermission();
      if (prompt && permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return await _cached();
      }

      final pos = await _currentPosition();
      await _cache(pos.latitude, pos.longitude);
      return CoarseLocation(
        lat: pos.latitude,
        lon: pos.longitude,
        fromCache: false,
      );
    } catch (e) {
      // Never throw at call sites — degrade to cache/calendar-only.
      debugPrint('LocationService.getCoarseLocation failed: $e');
      return await _cached();
    }
  }

  /// The last cached coarse fix, or `null` if none stored.
  Future<CoarseLocation?> cachedLocation() => _cached();

  Future<CoarseLocation?> _cached() async {
    try {
      final p = await _prefs();
      final lat = p.getDouble(_latKey);
      final lon = p.getDouble(_lonKey);
      if (lat == null || lon == null) return null;
      return CoarseLocation(lat: lat, lon: lon, fromCache: true);
    } catch (e) {
      debugPrint('LocationService._cached failed: $e');
      return null;
    }
  }

  Future<void> _cache(double lat, double lon) async {
    try {
      final p = await _prefs();
      await p.setDouble(_latKey, lat);
      await p.setDouble(_lonKey, lon);
    } catch (e) {
      debugPrint('LocationService._cache failed: $e');
    }
  }
}
