import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  Future<void> initialize({
    required String appleApiKey,
    required String googleApiKey,
  }) async {
    final apiKey = Platform.isIOS ? appleApiKey : googleApiKey;
    if (apiKey.isEmpty) return;

    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);
  }

  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }

  Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> purchase(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }

  Future<bool> restore() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active.containsKey('premium');
    } catch (_) {
      return false;
    }
  }

  void setUserId(String userId) {
    Purchases.logIn(userId);
  }
}
