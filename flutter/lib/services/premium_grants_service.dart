import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/purchase_service.dart';
import 'package:sakina/services/token_service.dart';
import 'package:sakina/services/tier_up_scroll_service.dart';

// Monthly grant amounts for premium users
const int premiumMonthlyTokens = 50;
const int premiumMonthlyScrolls = 15;

const String _lastGrantKey = 'sakina_premium_last_grant';

/// Check and apply monthly premium grants.
/// Call on app startup. Idempotent — only grants once per calendar month.
Future<({bool granted, int tokens, int scrolls})> checkPremiumMonthlyGrant() async {
  final premium = await PurchaseService().isPremium();
  if (!premium) return (granted: false, tokens: 0, scrolls: 0);

  final prefs = await SharedPreferences.getInstance();
  final lastGrant = prefs.getString(_lastGrantKey);
  final now = DateTime.now();
  final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  if (lastGrant == thisMonth) {
    return (granted: false, tokens: 0, scrolls: 0); // already granted this month
  }

  // Grant tokens and scrolls
  await earnTokens(premiumMonthlyTokens);
  await earnTierUpScrolls(premiumMonthlyScrolls);
  await prefs.setString(_lastGrantKey, thisMonth);

  return (granted: true, tokens: premiumMonthlyTokens, scrolls: premiumMonthlyScrolls);
}
