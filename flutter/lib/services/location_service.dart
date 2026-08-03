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

/// What the OS says about location access *right now*.
///
/// Deliberately distinct from [LocationGrantOutcome]: this is an observation,
/// that is a result of asking. The card gates its copy on this, so it must
/// separate "the user said no" from "the device's Location Services are off" —
/// they need different words and different destinations.
enum LocationReadiness {
  /// Permission held AND device Location Services are on.
  granted,

  /// Permission held, but the device's Location Services are switched off.
  /// Nothing the app can prompt for; the fix lives in the OS Settings app.
  servicesOff,

  /// Askable — the system dialog can still be shown.
  denied,

  /// "Never". iOS/Android will not re-show the dialog; Settings is the only way.
  deniedForever,

  /// Indeterminate (platform said so, or the lookup itself failed).
  undetermined,
}

/// The outcome of an explicit user request for precise access.
enum LocationGrantOutcome {
  /// Permission held and Location Services on — a fix is obtainable.
  granted,

  /// The user declined (or the dialog resolved to denied).
  denied,

  /// We routed the user to an OS Settings page instead of a dialog. NOT a
  /// denial — the user denied nothing, and many grant seconds later.
  openedSettings,

  /// Permission is fine but device Location Services are off; we routed to the
  /// Location Services page.
  servicesOff,
}

/// How long a coarse fix may take before we stop waiting and fall back to the
/// cache. Public so tests and the plan can reference the number. Every
/// foreground `resumed` retries, so a short bound costs nothing.
const Duration kCoarseFixTimeout = Duration(seconds: 8);

/// Wraps `geolocator` with a SharedPreferences cache so the duʿā-times feature
/// works offline and never re-prompts on every launch (spec §4/§10).
///
/// Design rules (spec §12/§15):
/// - **Coarse accuracy only** — prayer times need city-level precision, not
///   navigation-grade. Ships coarse for App Store data-minimization.
/// - **Lazy prompt** — permission is requested only when a caller explicitly
///   invokes [requestPreciseAccess]/[getCoarseLocation], never on construction.
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
    Future<bool> Function()? openLocationSettings,
    Future<SharedPreferences> Function()? prefs,
    Duration? fixTimeout,
  })  : _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _serviceEnabled = serviceEnabled ?? Geolocator.isLocationServiceEnabled,
        _currentPosition = currentPosition ?? _defaultCurrentPosition,
        _openAppSettings = openAppSettings ?? Geolocator.openAppSettings,
        _openLocationSettings =
            openLocationSettings ?? Geolocator.openLocationSettings,
        _prefs = prefs ?? SharedPreferences.getInstance,
        _fixTimeout = fixTimeout ?? kCoarseFixTimeout;

  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<bool> Function() _serviceEnabled;
  final Future<Position> Function() _currentPosition;
  final Future<bool> Function() _openAppSettings;
  final Future<bool> Function() _openLocationSettings;
  final Future<SharedPreferences> Function() _prefs;
  final Duration _fixTimeout;

  /// SharedPreferences keys for the cached coarse fix. Wiped on sign-out via
  /// [clearCache] (called from the widget clear hook) so a second user on the
  /// device never inherits the first user's approximate location (spec §7).
  static const String _latKey = 'dua_times_last_lat';
  static const String _lonKey = 'dua_times_last_lon';

  /// Coarse-accuracy request settings shared by fresh fixes.
  ///
  /// `timeLimit` bounds the fix natively; [_fixTimeout] bounds it again in Dart
  /// (see [getCoarseLocation]) because [_currentPosition] is an injectable seam
  /// and a fake has no native timer.
  static const LocationSettings _coarseSettings = LocationSettings(
    accuracy: LocationAccuracy.low,
    timeLimit: kCoarseFixTimeout,
  );

  static Future<Position> _defaultCurrentPosition() =>
      Geolocator.getCurrentPosition(locationSettings: _coarseSettings);

  /// True when location permission is granted (while-in-use or always).
  Future<bool> hasPermission() async {
    final p = await _checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  /// Lazily request permission (the ONLY method that prompts). Returns the
  /// resulting state. Callers invoke this from an explicit user affordance, not
  /// on launch. Returns the existing state without prompting if already granted
  /// or permanently denied.
  Future<LocationPermission> _ensurePermission() async {
    var permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermission();
    }
    return permission;
  }

  /// Observe-only: what does the OS say *right now*.
  ///
  /// Never prompts, never reads or writes the coarse cache, so it cannot weaken
  /// the permission-gates-the-cache rule in [getCoarseLocation].
  ///
  /// **Swallows its own errors on purpose.** This runs on the foreground-resume
  /// hot path via `DuaWindowNotifier.rebuild()`, whose catch block fires
  /// `dua_schedule_build_failed`. Letting a platform-channel hiccup escape here
  /// would poison the engine-health alarm with location noise.
  Future<LocationReadiness> readiness() async {
    try {
      final permission = await _checkPermission();
      switch (permission) {
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return await _serviceEnabled()
              ? LocationReadiness.granted
              : LocationReadiness.servicesOff;
        case LocationPermission.denied:
          return LocationReadiness.denied;
        case LocationPermission.deniedForever:
          return LocationReadiness.deniedForever;
        case LocationPermission.unableToDetermine:
          return LocationReadiness.undetermined;
      }
    } catch (e) {
      debugPrint('LocationService.readiness failed: $e');
      return LocationReadiness.undetermined;
    }
  }

  /// Request precise access for an explicit user tap, and report honestly what
  /// happened.
  ///
  /// - `denied` (askable) ⇒ show the system prompt.
  /// - `deniedForever` ⇒ iOS/Android won't re-show the prompt after a "Never",
  ///   so route to the OS app-settings page and report [openedSettings]. This
  ///   is NOT a denial: the old `false` return was logged as
  ///   `dua_times_location_denied` even when the user granted in Settings
  ///   seconds later.
  /// - granted **but device Location Services off** ⇒ there is no dialog to
  ///   show, so route to the Location Services page and report [servicesOff].
  ///   Without this branch the button is a visible no-op: the caller sees
  ///   permission granted, shows no dialog, and nothing happens.
  Future<LocationGrantOutcome> requestPreciseAccess() async {
    final permission = await _ensurePermission();
    if (permission == LocationPermission.deniedForever) {
      await _openAppSettings();
      return LocationGrantOutcome.openedSettings;
    }
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!granted) return LocationGrantOutcome.denied;

    if (!await _serviceEnabled()) {
      await _openLocationSettings();
      return LocationGrantOutcome.servicesOff;
    }
    return LocationGrantOutcome.granted;
  }

  /// Fetch a coarse location, degrading gracefully.
  ///
  /// Permission gates the cache: the cached fix is only reused when permission
  /// is *granted* but a fresh fix is unavailable (services off / transient
  /// failure — legitimate offline use). When permission is **denied /
  /// deniedForever / undetermined we return `null`** (calendar-only, and the
  /// card shows the enable banner) — a revoked user must NOT be served precise
  /// times from a stale, possibly wrong-city cached location.
  ///
  /// - [prompt] true ⇒ lazily request permission first (§15 lazy prompt).
  /// - On a successful fresh fix, caches lat/lon for offline reuse.
  Future<CoarseLocation?> getCoarseLocation({bool prompt = false}) async {
    try {
      var permission = await _checkPermission();
      if (prompt && permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      // Not permitted → calendar-only. Do NOT fall back to the stale cache.
      if (!granted) return null;

      // Granted but location services are off → the last cached fix is fine.
      if (!await _serviceEnabled()) {
        return await _cached();
      }

      // Bounded twice on purpose — see [_coarseSettings]. Without the Dart-side
      // timeout a hung fix leaves the caller awaiting forever, which showed up
      // as a permanent "Turn on precise times" banner while analytics reported
      // the grant as successful.
      final pos = await _currentPosition().timeout(_fixTimeout);
      await _cache(pos.latitude, pos.longitude);
      return CoarseLocation(
        lat: pos.latitude,
        lon: pos.longitude,
        fromCache: false,
      );
    } catch (e) {
      // Granted-path transient failure → last cached fix if we have one.
      debugPrint('LocationService.getCoarseLocation failed: $e');
      return await _cached();
    }
  }

  /// Wipe the cached coarse fix (both lat/lon keys). Called on sign-out via the
  /// widget clear hook so a second user on the device never inherits the first
  /// user's approximate home location (spec §7 privacy fix). The derived widget
  /// schedule is cleared separately by [WidgetDataService.clearWidget].
  Future<void> clearCache() async {
    try {
      final p = await _prefs();
      await p.remove(_latKey);
      await p.remove(_lonKey);
    } catch (e) {
      debugPrint('LocationService.clearCache failed: $e');
    }
  }

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
