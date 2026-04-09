// import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

const bool _purchasesTemporarilyDisabled = true;

class PurchaseService {
  Future<void> initialize({
    required String appleApiKey,
    required String googleApiKey,
  }) async {
    if (_purchasesTemporarilyDisabled) return;

    // final apiKey = Platform.isIOS ? appleApiKey : googleApiKey;
    // if (apiKey.isEmpty) return;
    //
    // final configuration = PurchasesConfiguration(apiKey);
    // await Purchases.configure(configuration);
  }

  Future<bool> isPremium() async {
    if (_purchasesTemporarilyDisabled) return false;

    // try {
    //   final customerInfo = await Purchases.getCustomerInfo();
    //   return customerInfo.entitlements.active.containsKey('premium');
    // } catch (_) {
    //   return false;
    // }
    return false;
  }

  Future<List<Package>> getOfferings() async {
    if (_purchasesTemporarilyDisabled) return [];

    // try {
    //   final offerings = await Purchases.getOfferings();
    //   return offerings.current?.availablePackages ?? [];
    // } catch (_) {
    //   return [];
    // }
    return [];
  }

  Future<bool> purchase(Package package) async {
    if (_purchasesTemporarilyDisabled) return false;

    // try {
    //   final result = await Purchases.purchasePackage(package);
    //   return result.entitlements.active.containsKey('premium');
    // } catch (_) {
    //   return false;
    // }
    return false;
  }

  Future<bool> restore() async {
    if (_purchasesTemporarilyDisabled) return false;

    // try {
    //   final customerInfo = await Purchases.restorePurchases();
    //   return customerInfo.entitlements.active.containsKey('premium');
    // } catch (_) {
    //   return false;
    // }
    return false;
  }

  Future<void> setUserId(String userId) async {
    if (_purchasesTemporarilyDisabled) return;

    // await Purchases.logIn(userId);
  }
}
