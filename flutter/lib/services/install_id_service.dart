import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// SharedPreferences key holding this installation's stable id.
///
/// UNSCOPED on purpose. The id names the INSTALL, not the account: it is
/// generated at first boot — before the user has an account, which is the whole
/// point, since it is what stitches pre-signup reel events to the account that
/// eventually signs up — and it must survive a sign-out, so a second account on
/// the same install still traces back to the same arrival.
const String installIdPrefsKey = 'install_id';

/// The name this id is registered under, in BOTH systems it has to join across:
/// the Mixpanel super property and the RevenueCat subscriber attribute.
///
/// Deliberately NOT RevenueCat's reserved `$mixpanelDistinctId`. That attribute
/// means "this subscriber IS that Mixpanel distinct id", which is false here —
/// Mixpanel's distinct id changes at `identify()` (Simplified ID Merge), while
/// the install id never does. Writing it there would claim an identity mapping
/// that breaks the first time the user signs in.
const String installIdPropertyName = 'install_id';

/// Reads (or, once ever, mints) the install id.
///
/// One id per installation, generated with `Uuid().v4()` and persisted
/// immediately. Deleting the app clears prefs and therefore the id — a
/// reinstall is a new install, which is the intended semantics.
class InstallIdService {
  InstallIdService._();

  static final InstallIdService instance = InstallIdService._();

  factory InstallIdService() => instance;

  /// Overridable so a test can pin the generated value.
  @visibleForTesting
  static String Function() debugGenerate = () => const Uuid().v4();

  String? _cached;
  Future<String>? _inFlight;

  /// The id for this install, minting it on the first call.
  ///
  /// Concurrency-safe: boot calls this from the analytics bootstrap and again
  /// from the purchase-service init, and two overlapping mints would each
  /// generate a uuid and race on the write, handing the two systems different
  /// ids for the same install. The in-flight future is shared instead.
  Future<String> getOrCreate() async {
    final cached = _cached;
    if (cached != null) return cached;
    return _inFlight ??= _resolve();
  }

  Future<String> _resolve() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(installIdPrefsKey);
      if (existing != null && existing.isNotEmpty) {
        return _cached = existing;
      }
      final generated = debugGenerate();
      await prefs.setString(installIdPrefsKey, generated);
      return _cached = generated;
    } finally {
      _inFlight = null;
    }
  }

  /// Test-only: forget the memoized id so the next call re-reads prefs.
  static void debugReset() {
    instance._cached = null;
    instance._inFlight = null;
  }
}
