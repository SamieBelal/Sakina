import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  PurchaseService._();

  @visibleForTesting
  PurchaseService.test();

  static final PurchaseService instance = PurchaseService._();

  factory PurchaseService() => _debugOverride ?? instance;

  static PurchaseService? _debugOverride;

  bool _initialized = false;
  Future<void>? _initializationFuture;

  Future<void> initialize({
    required String appleApiKey,
    required String googleApiKey,
  }) async {
    if (_initialized) return;

    final apiKey = _platformApiKey(
      appleApiKey: appleApiKey,
      googleApiKey: googleApiKey,
    );
    if (apiKey.isEmpty) return;

    final inFlightInitialization = _initializationFuture;
    if (inFlightInitialization != null) {
      await inFlightInitialization;
      return;
    }

    final completer = Completer<void>();
    _initializationFuture = completer.future;

    try {
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _initialized = true;
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      rethrow;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<bool> isPremium() async {
    if (!_initialized) return false;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }

  /// Returns the ISO-8601 timestamp when RevenueCat last detected a billing
  /// issue on the user's `premium` entitlement, or `null` if payment is
  /// healthy or the user is not subscribed.
  ///
  /// We read `entitlements.active` (not `.all`) because RevenueCat keeps
  /// grace-period entitlements in `.active` by design — that is how the
  /// "still has premium but payment is failing" state is represented.
  /// `.all` additionally contains long-expired entitlements, which would
  /// cause the billing banner to stick around for users whose subs lapsed
  /// months ago.
  Future<String?> getBillingIssueDetectedAt() async {
    if (!_initialized) return null;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final premium = customerInfo.entitlements.active['premium'];
      return premium?.billingIssueDetectedAt;
    } catch (_) {
      return null;
    }
  }

  Future<List<Package>> getOfferings() async {
    if (!_initialized) return [];

    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }

  /// Purchases a subscription package and returns `true` if the `premium`
  /// entitlement is now active. Use this for the paywall; subscriptions
  /// flip the entitlement on success.
  ///
  /// Includes a single fallback fetch via [Purchases.getCustomerInfo] when
  /// the immediate `customerInfo` from `purchasePackage` doesn't yet show
  /// `premium` active. RevenueCat's docs say the post-purchase customerInfo
  /// is current, but Apple's server-to-server validation can lag in rare
  /// cases — surfacing a false "purchase failed" then leads to a retry +
  /// double-charge attempt. The fallback closes that window. If the
  /// fallback also returns no entitlement, treat as genuinely failed.
  Future<bool> purchaseSubscription(Package package) async {
    _assertInitialized();
    final customerInfo = await Purchases.purchasePackage(package);
    if (customerInfo.entitlements.active.containsKey('premium')) {
      return true;
    }
    try {
      final fresh = await Purchases.getCustomerInfo();
      return fresh.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }

  /// Purchases a consumable package (tokens, scrolls). Returns `true` on
  /// success — RevenueCat's contract is throw-on-failure (cancellation,
  /// payment error) and return-on-success, so a non-throwing return means
  /// StoreKit recorded the transaction and the user has been charged.
  /// Consumables do NOT flip any entitlement, so the entitlement check used
  /// by [purchaseSubscription] is wrong here and would silently skip the
  /// local grant — that was the 2026-04-26 P0 bug.
  Future<bool> purchaseConsumable(Package package) async {
    _assertInitialized();
    await Purchases.purchasePackage(package);
    return true;
  }

  /// Restores previous purchases and returns `true` if the `premium`
  /// entitlement is now active.
  Future<bool> restorePurchases() async {
    _assertInitialized();
    final customerInfo = await Purchases.restorePurchases();
    return customerInfo.entitlements.active.containsKey('premium');
  }

  /// Identifies the user to RevenueCat. No-op when already logged in with the
  /// same id — this matters because Supabase's `tokenRefreshed` event fires
  /// roughly hourly while the app is running; without the guard, each refresh
  /// would trigger a `Purchases.logIn` backend round-trip and a redundant
  /// `CustomerInfo` listener update.
  Future<void> setUserId(String userId) async {
    if (!_initialized || userId.isEmpty) return;

    try {
      final current = await Purchases.appUserID;
      if (current == userId) return;
    } catch (_) {
      // Fall through to logIn if the current id can't be read.
    }

    await Purchases.logIn(userId);
  }

  String _platformApiKey({
    required String appleApiKey,
    required String googleApiKey,
  }) {
    if (Platform.isIOS) return appleApiKey;
    if (Platform.isAndroid) return googleApiKey;
    return '';
  }

  void _assertInitialized() {
    if (_initialized) return;
    throw StateError('RevenueCat has not been initialized.');
  }

  @visibleForTesting
  static void debugSetOverride(PurchaseService service) {
    _debugOverride = service;
  }

  @visibleForTesting
  static void debugClearOverride() {
    _debugOverride = null;
  }

  @visibleForTesting
  void debugMarkInitialized({bool initialized = true}) {
    _initialized = initialized;
  }
}
