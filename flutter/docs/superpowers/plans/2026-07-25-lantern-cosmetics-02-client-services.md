# Lantern Cosmetics — Lane B (Client Services) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Flutter service layer for the Lantern Cosmetics economy — a `CosmeticsService` that reads Noor + owned + equipped cosmetics from `sync_all_user_data()`, calls the Lane A `unlock_cosmetic` / `equip_cosmetic` RPCs, awards milestone Noor **only after** a confirmed `claim_streak_milestone`, grants à-la-carte skin IAP ownership server-side with refund/restore reconciliation, and resolves a single premium definition for subscriber-perk skins.

**Architecture:** Pure service layer, no Riverpod, no direct table writes (all mutation via SECURITY DEFINER RPCs per the CLAUDE.md hard rule). State is hydrated from the additive `noor` / `equipped` / `cosmetics` sections of `sync_all_user_data()` into user-scoped SharedPreferences caches — mirroring `premium_grants_service.dart` / `gating_service.dart` exactly. Analytics fire through a static `onAnalyticsEvent` hook (like `GatingService.onAnalyticsEvent` / `StreakAnalytics.onAnalyticsEvent`), with new event-name constants added to the import-free `analytics_event_names.dart` leaf. The IAP grant path mirrors `ConsumableGrantsService` but makes ownership **server-authoritative** (a new `grant_cosmetic_iap` RPC — a Lane A dependency, see Risks) so it is cross-device and refund-reconcilable, which the SharedPreferences-only consumable dedup is not.

**Tech Stack:** Dart / Flutter, Riverpod-free service layer, Supabase RPCs via `SupabaseSyncService.callRpc`, RevenueCat (`purchases_flutter`), SharedPreferences (user-scoped via `scopedKey`), `flutter_test` with `FakeSupabaseSyncService` + `StubPurchaseService` mocking.

---

## Cross-lane dependencies & open questions (READ BEFORE EXECUTING)

These are surfaced to the controller. Tasks below that depend on unbuilt infra are **clearly labeled** and include the exact contract the client codes against; where the server side belongs to Lane A, it is called out as a dependency, not built here.

### DEP-1 (Lane A / webhook) — `grant_cosmetic_iap` RPC does NOT exist yet
Spec §4 names `grant_cosmetic_iap(item_id, …)`, but the four merged Lane A migrations (`20260726000000`, `…000100`, `…000300`, `…000400`) define only `award_noor`, `unlock_cosmetic`, `equip_cosmetic`. **There is no à-la-carte IAP grant RPC and no non-consumable path in `revenuecat-webhook/handler.ts`** (it handles subscriptions + consumable clawbacks only). Spec §13 item 4 explicitly says this is net-new work. **Lane B codes the client against the contract below and gates the grant behind a null-tolerant `callRpc` so the app degrades gracefully until the RPC ships.** The RPC + webhook reconciliation are a Lane A dependency the controller must schedule before IAP is user-visible.

Client-assumed contract for the RPC (Task 6 codes to this — Lane A must match or the controller updates this plan):
```
grant_cosmetic_iap(p_item_id text, p_product_id text, p_transaction_id text)
  returns jsonb  -- { "granted": bool, "already_owned": bool, "item_id": text }
```
- Reads `cosmetic_catalog` to verify `p_product_id == iap_product_id` for `p_item_id` (server never trusts the client's item↔product mapping).
- Inserts `user_cosmetics(user_id, 'lantern_skin', item_id, 'iap')` `ON CONFLICT DO NOTHING`.
- Idempotent on `p_transaction_id` (a server-side ledger, mirroring `noor_grants`), so a replay from the RC listener + the synchronous purchase path can't double-insert.

### DEP-2 (Lane A / webhook) — refund + restore reconciliation is server-authoritative
Because ownership lives in `user_cosmetics` (server), a **refund** must remove the row and a **restore** must re-grant it. The client cannot do either safely from SharedPreferences (that's the exact `ConsumableGrantsService` limitation §13 item 4 forbids repeating). The webhook needs a `CANCELLATION`-on-skin-SKU → `clawback_cosmetic_iap` path (mirroring `buildConsumableClawback`). Lane B's client role is limited to: (a) calling `grant_cosmetic_iap` on purchase AND on `restorePurchases`, and (b) re-syncing so a server-side clawback is reflected. Flagged for Lane A.

### DEP-3 (Lane A, item 3 of §13) — `claim_streak_milestone(p_day)` is exploitable
§13 item 3: the existing `claim_streak_milestone` verifies neither that the day is recognized nor reached. Lane B's award-Noor ordering (Task 4) is **correct only if** Lane A has fixed that RPC so a successful claim genuinely means the milestone was reached. Lane B depends on that fix; it does not build it. Documented in Task 4.

### OQ-1 — RULED 2026-07-25: premium-exclusive skins are equippable WHILE PREMIUM ACTIVE, never converted
§13 item 6. **Maintainer ruling (2026-07-25):** premium-exclusive (subscriber-perk) catalog rows are **equippable while any premium source is active** (readable/previewable always) and are **NEVER converted to permanent `user_cosmetics` ownership** — trial/gift/referral users do **not** keep the monthly exclusive after premium lapses; when premium ends the perk is no longer equippable and the equipped slot falls back to an owned default (`classic_gold`). This is exactly the conservative behavior Task 6/7 already implement, so **no plan change is needed** — the ruling confirms it. À-la-carte IAP purchases (Task 7) are the *distinct* permanent-ownership path. Recorded in the superseding ADR `docs/decisions/2026-07-25-cosmetics-non-consumable-iap.md`.

### OQ-2 (open question — deferred per §14 rollout) — entitlement-period reconciliation for subscriber grants
§13 item 7 wants "grant on sync while active" reconciled over the entitlement period (a subscriber who didn't open during the drop month). §14 rollout ships the **free loop first** (P0–P3) and layers premium perks in **P4/P5**. There is no premium-grant-on-sync RPC in the merged Lane A migrations. **Lane B defers this** with a documented note (Task 8): the client will call a future `grant_premium_cosmetics()` RPC on sync when it exists; the entitlement-period backfill is server-side (Lane A) and out of Lane B's scope. No client code can reconcile a window the server doesn't grant.

---

## File Structure

| File | Responsibility |
|---|---|
| `lib/services/analytics_event_names.dart` (modify) | Add cosmetics event-name + property constants to the import-free leaf. |
| `lib/services/cosmetics_service.dart` (create) | The whole Lane B service: read Noor/owned/equipped from sync; hydrate caches; `unlock` / `equip` RPC calls; milestone Noor award (ordered after claim); IAP grant + restore reconciliation; premium-equippable resolution. Top-level functions + a small `CosmeticsService` class with a static `onAnalyticsEvent` hook, matching the codebase split (`streak_service.dart` uses top-level fns + `StreakAnalytics`; `premium_grants_service.dart` uses top-level fns). |
| `lib/services/user_data_batch_sync_service.dart` (modify) | Hydrate the three new sync sections (`noor`, `equipped`, `cosmetics`) into the cosmetics caches, alongside the existing hydrate calls. |
| `test/services/cosmetics_service_test.dart` (create) | Unit tests for read/unlock/equip/milestone-award/IAP-grant using `FakeSupabaseSyncService` + `StubPurchaseService`. |
| `test/services/user_data_batch_sync_cosmetics_test.dart` (create) | Pins the batch-sync hydration of the three new sections. |

**Design decision — top-level functions, not a stateful class:** `cosmetics_service.dart` follows the `streak_service.dart` / `premium_grants_service.dart` shape (top-level `Future` functions + a tiny analytics-hook holder class) rather than the singleton-with-`factory` shape of `GatingService`. Reason: cosmetics state is entirely SharedPreferences-cache-backed with no in-memory session state to hold, so the top-level-function form is the closest existing analog and keeps the service Riverpod-free and trivially testable.

---

## Task 1: Add cosmetics analytics event-name constants

**Files:**
- Modify: `lib/services/analytics_event_names.dart`
- Test: `test/services/cosmetics_service_test.dart` (created in Task 3; a tiny pin here)

We add constants first because every later task references them. Adding them to the import-free leaf keeps the pure service Riverpod-free (pinned by `analytics_event_names_leaf_test.dart`).

- [ ] **Step 1: Write the failing test**

Create `test/services/cosmetics_analytics_names_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/analytics_event_names.dart';

void main() {
  test('cosmetics event-name constants have their pinned dashboard values', () {
    expect(AnalyticsEvents.noorEarned, 'noor_earned');
    expect(AnalyticsEvents.cosmeticUnlocked, 'cosmetic_unlocked');
    expect(AnalyticsEvents.cosmeticEquipped, 'cosmetic_equipped');
    expect(AnalyticsEvents.cosmeticIapPurchased, 'cosmetic_iap_purchased');
    expect(AnalyticsEvents.milestoneSkinUnlocked, 'milestone_skin_unlocked');
    expect(AnalyticsEvents.cosmeticUnlockRejected, 'cosmetic_unlock_rejected');
    expect(AnalyticsEvents.propItemType, 'item_type');
    expect(AnalyticsEvents.propItemId, 'item_id');
    expect(AnalyticsEvents.propAmount, 'amount');
    expect(AnalyticsEvents.propReason, 'reason');
    expect(AnalyticsEvents.cosmeticViaNoor, 'noor');
    expect(AnalyticsEvents.cosmeticViaIap, 'iap');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_analytics_names_test.dart`
Expected: FAIL — compile error, `noorEarned` (and siblings) are not defined on `AnalyticsEvents`.

- [ ] **Step 3: Add the constants**

In `lib/services/analytics_event_names.dart`, insert this block immediately **before** the closing `}` of `abstract final class AnalyticsEvents` (after the `stepNamesFor` method). `propReason` already exists on this class (used by the dua-times events) — DO NOT re-declare it; the test above references the existing one. Add only the new constants:

```dart
  // ── Lantern Cosmetics (Noor economy + skins/backdrops) ──────────────────
  // Spec §7. Emitted from cosmetics_service.dart via the static
  // CosmeticsAnalytics.onAnalyticsEvent hook (no Riverpod in the service).
  // These exact strings are the Mixpanel dashboard contract — renames must be
  // a deliberate analytics-team coordination (pinned by
  // cosmetics_analytics_names_test).

  /// Noor was minted for the user. Props: `amount`, `reason`
  /// (daily|milestone:N|quest). Fired only on a NON-idempotent-replay grant
  /// (award_noor returns the granted amount; a deduped replay returns 0 and
  /// emits nothing).
  static const String noorEarned = 'noor_earned';

  /// A cosmetic was unlocked by spending Noor. Props: `item_type`, `item_id`,
  /// `via` ('noor').
  static const String cosmeticUnlocked = 'cosmetic_unlocked';

  /// A cosmetic was equipped. Props: `item_type`, `item_id`.
  static const String cosmeticEquipped = 'cosmetic_equipped';

  /// An à-la-carte skin was purchased with real money and granted
  /// server-side. Props: `item_id`, `product_id`.
  static const String cosmeticIapPurchased = 'cosmetic_iap_purchased';

  /// A milestone-gated skin was auto-unlocked after a confirmed
  /// claim_streak_milestone. Props: `item_id`, `milestone_day`.
  static const String milestoneSkinUnlocked = 'milestone_skin_unlocked';

  /// An unlock/equip RPC was rejected (insufficient noor, unowned, inactive,
  /// premium-exclusive). Props: `item_type`, `item_id`, `reason`.
  static const String cosmeticUnlockRejected = 'cosmetic_unlock_rejected';

  // Property keys + values for the cosmetics events.
  static const String propItemType = 'item_type';
  static const String propItemId = 'item_id';
  static const String propAmount = 'amount';
  static const String propVia = 'via';
  static const String propProductId = 'product_id';
  static const String propMilestoneDay = 'milestone_day';
  static const String cosmeticViaNoor = 'noor';
  static const String cosmeticViaIap = 'iap';
```

Note: `propReason` is intentionally NOT added here — it already exists on `AnalyticsEvents` (line ~540, `static const String propReason = 'reason';`). The test asserts its value `'reason'`, which the existing constant satisfies.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_analytics_names_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the leaf-invariant test to confirm no Riverpod coupling regressed**

Run: `flutter test test/services/analytics_event_names_leaf_test.dart`
Expected: PASS (the leaf stays import-free; we only added `static const String` lines).

- [ ] **Step 6: Commit**

```bash
git add lib/services/analytics_event_names.dart test/services/cosmetics_analytics_names_test.dart
git commit -m "feat(cosmetics): add Noor/cosmetics analytics event-name constants"
```

---

## Task 2: `CosmeticsState` model + cache read/hydrate scaffolding

**Files:**
- Create: `lib/services/cosmetics_service.dart`
- Test: `test/services/cosmetics_service_test.dart`

This task creates the service file with the read-side only: a plain `CosmeticsState` value class (no Freezed — it is a tiny read-only view, matching `TokenState` / `StreakState` which are hand-written), the user-scoped SharedPreferences cache keys, a `getCosmeticsState()` reader, and `hydrateCosmeticsFromSync(...)` writers. Ownership/equip/noor are cached so the wardrobe (Lane D) renders synchronously without a round-trip, exactly like `TokenState`.

- [ ] **Step 1: Write the failing test**

Create `test/services/cosmetics_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';

import '../support/fake_supabase_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
  });

  tearDown(() {
    SupabaseSyncService.debugReset();
  });

  test('fresh user reads defaults: 0 noor, classic_gold + default equipped, '
      'no owned', () async {
    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.equippedBackdrop, 'default');
    expect(state.ownedLanternSkins, isEmpty);
    expect(state.ownedBackdrops, isEmpty);
    expect(state.owns('lantern_skin', 'moonlit_silver'), isFalse);
  });

  test('hydrateCosmeticsFromSync writes balance, equipped, and owned caches',
      () async {
    await hydrateCosmeticsFromSync(
      noorBalance: 240,
      equippedLanternSkin: 'emerald_jade',
      equippedBackdrop: 'laylat_night',
      owned: const [
        {'item_type': 'lantern_skin', 'item_id': 'emerald_jade'},
        {'item_type': 'lantern_skin', 'item_id': 'moonlit_silver'},
        {'item_type': 'backdrop', 'item_id': 'laylat_night'},
      ],
    );

    final state = await getCosmeticsState();
    expect(state.noorBalance, 240);
    expect(state.equippedLanternSkin, 'emerald_jade');
    expect(state.equippedBackdrop, 'laylat_night');
    expect(state.ownedLanternSkins,
        containsAll(<String>['emerald_jade', 'moonlit_silver']));
    expect(state.ownedBackdrops, contains('laylat_night'));
    expect(state.owns('lantern_skin', 'moonlit_silver'), isTrue);
    expect(state.owns('backdrop', 'emerald_sanctuary'), isFalse);
  });

  test('hydration is scoped per user (no cross-account bleed)', () async {
    await hydrateCosmeticsFromSync(
      noorBalance: 500,
      equippedLanternSkin: 'obsidian_gold',
      equippedBackdrop: 'default',
      owned: const [
        {'item_type': 'lantern_skin', 'item_id': 'obsidian_gold'},
      ],
    );

    // Switch to a different user — caches must not carry over.
    fakeSync.userId = 'user-2';
    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.ownedLanternSkins, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: FAIL — `cosmetics_service.dart` does not exist / `getCosmeticsState` undefined.

- [ ] **Step 3: Create the service scaffolding**

Create `lib/services/cosmetics_service.dart`:

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sakina/services/analytics_event_names.dart';
import 'package:sakina/services/supabase_sync_service.dart';

// ---------------------------------------------------------------------------
// Cosmetics Service (Lane B)
//
// Server-authoritative Lantern Cosmetics economy client. NEVER writes economy
// tables directly — all mutation flows through the Lane A SECURITY DEFINER
// RPCs (award_noor / unlock_cosmetic / equip_cosmetic / grant_cosmetic_iap).
// State is read from the additive noor / equipped / cosmetics sections of
// sync_all_user_data() and mirrored into user-scoped SharedPreferences so the
// wardrobe renders synchronously (mirrors TokenState / premium_grants_service).
//
// No Riverpod imports (pinned indirectly by the leaf-import discipline).
// ---------------------------------------------------------------------------

/// Analytics seam. Top-level cosmetics functions have no Riverpod access, so
/// they emit through this static hook (same pattern as
/// `GatingService.onAnalyticsEvent` / `StreakAnalytics.onAnalyticsEvent`).
/// Wired once in `main.dart`; null in tests and until wired, so emitting is a
/// safe no-op.
class CosmeticsAnalytics {
  CosmeticsAnalytics._();

  static void Function(String event, Map<String, dynamic> props)?
      onAnalyticsEvent;

  static void emit(String event, Map<String, dynamic> props) {
    try {
      onAnalyticsEvent?.call(event, props);
    } catch (_) {
      // Telemetry must never break an economy write.
    }
  }
}

/// Read-only view of the user's cosmetics economy state. Hand-written (like
/// TokenState / StreakState) — no Freezed, since it is a tiny read model with
/// no JSON round-trip of its own.
@immutable
class CosmeticsState {
  const CosmeticsState({
    required this.noorBalance,
    required this.equippedLanternSkin,
    required this.equippedBackdrop,
    required this.ownedLanternSkins,
    required this.ownedBackdrops,
  });

  final int noorBalance;
  final String equippedLanternSkin;
  final String equippedBackdrop;
  final Set<String> ownedLanternSkins;
  final Set<String> ownedBackdrops;

  bool owns(String itemType, String itemId) {
    switch (itemType) {
      case itemTypeLanternSkin:
        return itemId == defaultLanternSkin ||
            ownedLanternSkins.contains(itemId);
      case itemTypeBackdrop:
        return itemId == defaultBackdrop || ownedBackdrops.contains(itemId);
      default:
        return false;
    }
  }
}

// item_type values — mirror the cosmetic_catalog CHECK constraint.
const String itemTypeLanternSkin = 'lantern_skin';
const String itemTypeBackdrop = 'backdrop';

// The always-owned defaults (backfilled server-side; never in user_cosmetics).
const String defaultLanternSkin = 'classic_gold';
const String defaultBackdrop = 'default';

// User-scoped SharedPreferences base keys.
const String _noorBalanceKey = 'sakina_noor_balance';
const String _equippedSkinKey = 'sakina_equipped_lantern_skin';
const String _equippedBackdropKey = 'sakina_equipped_backdrop';
const String _ownedSkinsKey = 'sakina_owned_lantern_skins';
const String _ownedBackdropsKey = 'sakina_owned_backdrops';

Future<Set<String>> _readOwnedSet(
  SharedPreferences prefs,
  String baseKey,
) async {
  final raw = prefs.getString(supabaseSyncService.scopedKey(baseKey));
  if (raw == null || raw.isEmpty) return <String>{};
  try {
    return (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
  } catch (_) {
    return <String>{};
  }
}

/// Reads the cached cosmetics state. Server is the source of truth; this cache
/// is refreshed on every `sync_all_user_data` via [hydrateCosmeticsFromSync].
Future<CosmeticsState> getCosmeticsState() async {
  final prefs = await SharedPreferences.getInstance();
  return CosmeticsState(
    noorBalance:
        prefs.getInt(supabaseSyncService.scopedKey(_noorBalanceKey)) ?? 0,
    equippedLanternSkin:
        prefs.getString(supabaseSyncService.scopedKey(_equippedSkinKey)) ??
            defaultLanternSkin,
    equippedBackdrop:
        prefs.getString(supabaseSyncService.scopedKey(_equippedBackdropKey)) ??
            defaultBackdrop,
    ownedLanternSkins: await _readOwnedSet(prefs, _ownedSkinsKey),
    ownedBackdrops: await _readOwnedSet(prefs, _ownedBackdropsKey),
  );
}

/// Mirrors the three additive sync sections into the local caches. Called by
/// `user_data_batch_sync_service` on every app-launch / re-sync. Owned rows
/// arrive as the `cosmetics` section's `[{item_type, item_id, acquired_via}]`.
Future<void> hydrateCosmeticsFromSync({
  required int noorBalance,
  required String equippedLanternSkin,
  required String equippedBackdrop,
  required List<Map<String, dynamic>> owned,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
      supabaseSyncService.scopedKey(_noorBalanceKey), noorBalance);
  await prefs.setString(
      supabaseSyncService.scopedKey(_equippedSkinKey), equippedLanternSkin);
  await prefs.setString(
      supabaseSyncService.scopedKey(_equippedBackdropKey), equippedBackdrop);

  final skins = <String>[];
  final backdrops = <String>[];
  for (final row in owned) {
    final type = row['item_type'];
    final id = row['item_id'];
    if (id is! String) continue;
    if (type == itemTypeLanternSkin) {
      skins.add(id);
    } else if (type == itemTypeBackdrop) {
      backdrops.add(id);
    }
  }
  await prefs.setString(
      supabaseSyncService.scopedKey(_ownedSkinsKey), jsonEncode(skins));
  await prefs.setString(
      supabaseSyncService.scopedKey(_ownedBackdropsKey), jsonEncode(backdrops));
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: PASS (all 3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_service_test.dart
git commit -m "feat(cosmetics): CosmeticsState read model + sync hydration"
```

---

## Task 3: `unlock_cosmetic` (spend Noor) with error surfacing + analytics

**Files:**
- Modify: `lib/services/cosmetics_service.dart`
- Test: `test/services/cosmetics_service_test.dart`

Calls the Lane A `unlock_cosmetic(p_item_type text, p_item_id text) returns boolean` RPC (defined in `20260726000000` + hardened in `20260726000400`). The RPC atomically checks + deducts Noor and inserts inventory `ON CONFLICT DO NOTHING`; it **raises** on insufficient Noor / inactive / premium-exclusive / out-of-window. `callRpc` swallows the raise and returns `null`, so the client maps `null → failure` and surfaces a typed result the UI turns into a snackbar. On success we optimistically mirror the balance/ownership into the cache so the wardrobe updates without a round-trip; the next full sync reconciles.

- [ ] **Step 1: Write the failing test**

Append to `test/services/cosmetics_service_test.dart` (inside `main`):

```dart
  group('unlockCosmetic', () {
    test('success: mirrors ownership + debits noor cache + emits analytics',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 200,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );
      fakeSync.rpcHandlers['unlock_cosmetic'] = (params) async => true;

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent =
          (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await unlockCosmetic(
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        noorPrice: 120,
      );

      expect(result.success, isTrue);
      expect(fakeSync.rpcCalls.single['fn'], 'unlock_cosmetic');
      expect(fakeSync.rpcCalls.single['params'],
          {'p_item_type': 'lantern_skin', 'p_item_id': 'moonlit_silver'});

      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'moonlit_silver'), isTrue);
      expect(state.noorBalance, 80); // 200 - 120

      expect(events.single.$1, 'cosmetic_unlocked');
      expect(events.single.$2,
          {'item_type': 'lantern_skin', 'item_id': 'moonlit_silver',
           'via': 'noor'});
    });

    test('rejection (RPC raises → null): no cache mutation, emits rejected',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 10,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );
      // No handler registered → FakeSupabaseSyncService.callRpc returns null,
      // exactly like callRpc swallowing a server RAISE.

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await unlockCosmetic(
        itemType: 'lantern_skin',
        itemId: 'masjid_brass',
        noorPrice: 300,
      );

      expect(result.success, isFalse);
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'masjid_brass'), isFalse);
      expect(state.noorBalance, 10); // untouched
      expect(events.single.$1, 'cosmetic_unlock_rejected');
    });

    test('unauthenticated: returns failure without an RPC call', () async {
      fakeSync.userId = null;
      final result = await unlockCosmetic(
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        noorPrice: 120,
      );
      expect(result.success, isFalse);
      expect(fakeSync.rpcCalls, isEmpty);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: FAIL — `unlockCosmetic` and `CosmeticActionResult` undefined.

- [ ] **Step 3: Implement `unlockCosmetic`**

Add to `lib/services/cosmetics_service.dart` (after `hydrateCosmeticsFromSync`):

```dart
/// Outcome of an unlock / equip / grant action. [success] drives whether the
/// caller shows a confirmation or an error snackbar (spec §UI). The service
/// itself surfaces nothing — it returns this so the widget layer owns the
/// snackbar (services never show UI).
@immutable
class CosmeticActionResult {
  const CosmeticActionResult({required this.success});
  final bool success;

  static const CosmeticActionResult ok = CosmeticActionResult(success: true);
  static const CosmeticActionResult failed =
      CosmeticActionResult(success: false);
}

/// Spends Noor to unlock [itemId]. Delegates ALL price/availability/gating to
/// the Lane A `unlock_cosmetic` RPC (server never trusts the client price —
/// [noorPrice] is used ONLY to optimistically mirror the debit into the cache
/// on success; the next sync reconciles the authoritative balance). Returns
/// [CosmeticActionResult.failed] when the RPC raises (insufficient noor,
/// inactive, premium-exclusive, out-of-window) — `callRpc` maps the raise to
/// null.
Future<CosmeticActionResult> unlockCosmetic({
  required String itemType,
  required String itemId,
  required int noorPrice,
}) async {
  if (supabaseSyncService.currentUserId == null) {
    return CosmeticActionResult.failed;
  }

  final ok = await supabaseSyncService.callRpc<bool>(
    'unlock_cosmetic',
    {'p_item_type': itemType, 'p_item_id': itemId},
  );

  if (ok != true) {
    CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticUnlockRejected, {
      AnalyticsEvents.propItemType: itemType,
      AnalyticsEvents.propItemId: itemId,
      AnalyticsEvents.propReason: 'rpc_declined',
    });
    return CosmeticActionResult.failed;
  }

  await _addOwnedToCache(itemType, itemId);
  await _debitNoorCache(noorPrice);

  CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticUnlocked, {
    AnalyticsEvents.propItemType: itemType,
    AnalyticsEvents.propItemId: itemId,
    AnalyticsEvents.propVia: AnalyticsEvents.cosmeticViaNoor,
  });
  return CosmeticActionResult.ok;
}

Future<void> _addOwnedToCache(String itemType, String itemId) async {
  final prefs = await SharedPreferences.getInstance();
  final baseKey =
      itemType == itemTypeBackdrop ? _ownedBackdropsKey : _ownedSkinsKey;
  final set = await _readOwnedSet(prefs, baseKey);
  set.add(itemId);
  await prefs.setString(
      supabaseSyncService.scopedKey(baseKey), jsonEncode(set.toList()));
}

Future<void> _debitNoorCache(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final key = supabaseSyncService.scopedKey(_noorBalanceKey);
  final current = prefs.getInt(key) ?? 0;
  await prefs.setInt(key, (current - amount).clamp(0, 1 << 31));
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_service_test.dart
git commit -m "feat(cosmetics): unlockCosmetic RPC call + optimistic cache mirror"
```

---

## Task 4: `award_noor` for milestones — ORDERED after `claim_streak_milestone`

**Files:**
- Modify: `lib/services/cosmetics_service.dart`
- Test: `test/services/cosmetics_service_test.dart`

**This is spec §13 item 13 — the CRITICAL client-gating requirement.** `award_noor(p_reason, p_reason_key)` is idempotent (deduped on `(user_id, reason_key)` via the `noor_grants` ledger) but does NOT itself verify the milestone was reached — that authority is in `claim_streak_milestone(N)`. So the client MUST call `award_noor('milestone:N', 'milestone:N')` **ONLY after** a successful `claim_streak_milestone(N)` returns `newly_claimed=true`, with a **server-shaped `reason_key`** (`'milestone:N'`, matching the exact `p_reason` cases the RPC recognizes) so the ledger dedupes correctly. Never award speculatively.

**Reason-key shape (pinned):** `p_reason` and `p_reason_key` are BOTH `'milestone:<day>'` where `<day>` is the streak-milestone day (7/14/30/60/100). The `award_noor` RPC's `case` only recognizes `milestone:7|14|30|60|100` and `daily`/`quest`; any other reason raises `unknown noor reason`. The `reason_key` being identical to `reason` is intentional: one milestone day earns Noor exactly once per user, forever — the ledger PK `(user_id, 'milestone:30')` enforces that even across streak rebuilds (kills the farming exploit §13 item 1).

**DEP-3:** this ordering is only *safe* if Lane A has fixed the exploitable `claim_streak_milestone` (§13 item 3). Lane B depends on that fix and does not build it. Documented inline.

- [ ] **Step 1: Write the failing test**

Append to `test/services/cosmetics_service_test.dart`:

```dart
  group('awardMilestoneNoor (ordered after claim_streak_milestone)', () {
    test('awards Noor ONLY after a confirmed claim; correct reason_key shape',
        () async {
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (params) async => {'newly_claimed': true};
      fakeSync.rpcHandlers['award_noor'] = (params) async => 150; // milestone:30

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardMilestoneNoor(30);

      expect(granted, 150);
      // Ordering: claim BEFORE award.
      final fns = fakeSync.rpcCalls.map((c) => c['fn']).toList();
      expect(fns, ['claim_streak_milestone', 'award_noor']);
      // Server-shaped reason_key.
      expect(fakeSync.rpcCalls[1]['params'],
          {'p_reason': 'milestone:30', 'p_reason_key': 'milestone:30'});
      // Analytics.
      expect(events.single.$1, 'noor_earned');
      expect(events.single.$2, {'amount': 150, 'reason': 'milestone:30'});
    });

    test('does NOT award when claim reports already-claimed (newly=false)',
        () async {
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (params) async => {'newly_claimed': false};
      fakeSync.rpcHandlers['award_noor'] = (params) async => 150;

      final granted = await awardMilestoneNoor(30);

      expect(granted, 0);
      final fns = fakeSync.rpcCalls.map((c) => c['fn']).toList();
      expect(fns, ['claim_streak_milestone']); // award_noor NEVER called
    });

    test('does NOT award when claim RPC fails (null)', () async {
      // No claim handler → returns null (RPC unavailable / raised).
      fakeSync.rpcHandlers['award_noor'] = (params) async => 150;

      final granted = await awardMilestoneNoor(7);

      expect(granted, 0);
      expect(fakeSync.rpcCalls.map((c) => c['fn']),
          isNot(contains('award_noor')));
    });

    test('idempotent-replay: award_noor returns 0 → no analytics, no crash',
        () async {
      fakeSync.rpcHandlers['claim_streak_milestone'] =
          (params) async => {'newly_claimed': true};
      fakeSync.rpcHandlers['award_noor'] = (params) async => 0; // deduped

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardMilestoneNoor(30);

      expect(granted, 0);
      expect(events, isEmpty); // a 0-amount replay emits nothing
    });

    test('unrecognized milestone day is refused client-side (no RPC calls)',
        () async {
      final granted = await awardMilestoneNoor(999);
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('unauthenticated: no RPC calls, returns 0', () async {
      fakeSync.userId = null;
      final granted = await awardMilestoneNoor(30);
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: FAIL — `awardMilestoneNoor` undefined.

- [ ] **Step 3: Implement `awardMilestoneNoor`**

Add to `lib/services/cosmetics_service.dart`:

```dart
/// The streak-milestone days that `award_noor` recognizes (the RPC's `case`
/// arms are `milestone:7|14|30|60|100`). Client-side allowlist so an
/// unrecognized day never reaches the RPC (which would `raise 'unknown noor
/// reason'`). Kept in lockstep with the RPC body in
/// `20260726000000_cosmetics_economy.sql`.
const Set<int> awardableMilestoneDays = {7, 14, 30, 60, 100};

/// Awards milestone Noor for reaching [day], but ONLY after a successful,
/// newly-recorded `claim_streak_milestone(day)`. This ordering is spec §13
/// item 13: `award_noor` is idempotent but does NOT verify the milestone was
/// reached — that authority is `claim_streak_milestone`. We therefore claim
/// first and award only when the claim reports `newly_claimed=true`.
///
/// DEP-3: correctness assumes Lane A fixed the exploitable `claim_streak_
/// milestone` (§13 item 3) so a `newly_claimed=true` genuinely means the day
/// was recognized AND reached. Lane B depends on that fix; it does not build it.
///
/// The reason + reason_key are BOTH the server-shaped `'milestone:<day>'` so
/// the `noor_grants` ledger dedupes per (user, day) forever — a streak rebuild
/// can never re-mint the same milestone's Noor (kills the farming exploit).
///
/// Returns the Noor amount minted (server-derived), or 0 when the claim was
/// not newly recorded, the day is unrecognized, the user is unauthenticated,
/// or the grant was an idempotent replay (award_noor returns 0).
Future<int> awardMilestoneNoor(int day) async {
  if (supabaseSyncService.currentUserId == null) return 0;
  if (!awardableMilestoneDays.contains(day)) return 0;

  // 1. Claim FIRST — the server decides whether the milestone is genuinely
  //    new + reached. Only proceed to award on a fresh claim.
  final claim = await supabaseSyncService.callRpc<Map<String, dynamic>>(
    'claim_streak_milestone',
    {'p_day': day},
  );
  final newlyClaimed = claim?['newly_claimed'] == true;
  if (!newlyClaimed) return 0;

  // 2. THEN award, with the server-shaped reason_key so the ledger dedupes.
  final reasonKey = 'milestone:$day';
  final amount = await supabaseSyncService.callRpc<int>(
    'award_noor',
    {'p_reason': reasonKey, 'p_reason_key': reasonKey},
  );
  if (amount == null || amount <= 0) return 0; // deduped replay or failure

  // Mirror the mint into the cache so the wardrobe balance updates without a
  // round-trip; the next full sync reconciles the authoritative value.
  await _creditNoorCache(amount);

  CosmeticsAnalytics.emit(AnalyticsEvents.noorEarned, {
    AnalyticsEvents.propAmount: amount,
    AnalyticsEvents.propReason: reasonKey,
  });
  return amount;
}

Future<void> _creditNoorCache(int amount) async {
  final prefs = await SharedPreferences.getInstance();
  final key = supabaseSyncService.scopedKey(_noorBalanceKey);
  final current = prefs.getInt(key) ?? 0;
  await prefs.setInt(key, current + amount);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: PASS (all `awardMilestoneNoor` tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_service_test.dart
git commit -m "feat(cosmetics): milestone Noor award gated behind claim_streak_milestone (spec §13.13)"
```

---

## Task 5: `award_noor` for daily muḥāsabah + quests (non-milestone reasons)

**Files:**
- Modify: `lib/services/cosmetics_service.dart`
- Test: `test/services/cosmetics_service_test.dart`

The daily-completion (+10) and quest (+15) Noor grants (spec §3) don't have a `claim_*` prerequisite — the daily loop / quest completion IS the earned event. They still MUST be idempotent per occurrence, so the caller supplies a **date/quest-scoped `reason_key`** (e.g. `daily:2026-07-25` or `quest:<questId>:<periodStart>`) while the `reason` stays the coarse `'daily'` / `'quest'` the RPC's `case` recognizes for the amount. This keeps the amount server-derived (from `reason`) but the dedup per-occurrence (from `reason_key`).

- [ ] **Step 1: Write the failing test**

Append to `test/services/cosmetics_service_test.dart`:

```dart
  group('awardNoor (daily / quest — reason vs reason_key split)', () {
    test('daily: coarse reason drives amount, scoped reason_key dedupes',
        () async {
      fakeSync.rpcHandlers['award_noor'] = (params) async => 10;

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted = await awardNoor(
        reason: 'daily',
        reasonKey: 'daily:2026-07-25',
      );

      expect(granted, 10);
      expect(fakeSync.rpcCalls.single['params'],
          {'p_reason': 'daily', 'p_reason_key': 'daily:2026-07-25'});
      expect(events.single.$1, 'noor_earned');
      expect(events.single.$2, {'amount': 10, 'reason': 'daily'});
    });

    test('idempotent replay (returns 0) mints nothing + emits nothing',
        () async {
      fakeSync.rpcHandlers['award_noor'] = (params) async => 0;
      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final granted =
          await awardNoor(reason: 'daily', reasonKey: 'daily:2026-07-25');

      expect(granted, 0);
      expect(events, isEmpty);
    });

    test('refuses a reason the RPC does not recognize (no RPC call)', () async {
      final granted =
          await awardNoor(reason: 'bogus', reasonKey: 'bogus:1');
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('unauthenticated: no RPC call', () async {
      fakeSync.userId = null;
      final granted =
          await awardNoor(reason: 'daily', reasonKey: 'daily:2026-07-25');
      expect(granted, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: FAIL — `awardNoor` undefined.

- [ ] **Step 3: Implement `awardNoor`**

Add to `lib/services/cosmetics_service.dart`:

```dart
/// The coarse `reason` values `award_noor` recognizes for NON-milestone grants
/// (its `case` arms). Milestone grants go through [awardMilestoneNoor], which
/// enforces the claim-first ordering, so `'milestone:*'` is intentionally NOT
/// accepted here.
const Set<String> awardableNoorReasons = {'daily', 'quest'};

/// Awards Noor for a non-milestone earned event (daily muḥāsabah completion,
/// quest completion — spec §3). The [reason] is the coarse value the RPC maps
/// to an amount (server-derived); the [reasonKey] is the per-occurrence dedup
/// key (e.g. `daily:2026-07-25`, `quest:<id>:<period>`) so re-running the loop
/// the same day cannot double-mint.
///
/// Returns the amount minted, or 0 on a deduped replay / unrecognized reason /
/// unauthenticated caller.
Future<int> awardNoor({
  required String reason,
  required String reasonKey,
}) async {
  if (supabaseSyncService.currentUserId == null) return 0;
  if (!awardableNoorReasons.contains(reason)) return 0;

  final amount = await supabaseSyncService.callRpc<int>(
    'award_noor',
    {'p_reason': reason, 'p_reason_key': reasonKey},
  );
  if (amount == null || amount <= 0) return 0;

  await _creditNoorCache(amount);
  CosmeticsAnalytics.emit(AnalyticsEvents.noorEarned, {
    AnalyticsEvents.propAmount: amount,
    AnalyticsEvents.propReason: reason,
  });
  return amount;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_service_test.dart
git commit -m "feat(cosmetics): awardNoor for daily/quest with per-occurrence reason_key dedup"
```

---

## Task 6: `equip_cosmetic` — ownership-checked + premium-equippable resolution

**Files:**
- Modify: `lib/services/cosmetics_service.dart`
- Test: `test/services/cosmetics_service_test.dart`

Calls Lane A `equip_cosmetic(p_item_type, p_item_id) returns boolean` (raises if the user doesn't own the item; `callRpc` maps the raise to null → failure). On success, mirror the equipped column into the cache. This task also resolves **spec §13 item 6 / OQ-1**: the client's "can this be equipped?" predicate for a **premium-exclusive** catalog row is `PurchaseService().isPremium()` — a premium user can equip a subscriber-perk skin they do NOT own in `user_cosmetics` (the server `equip_cosmetic` is the authority; if Lane A blocks equip-without-ownership for premium-exclusive rows, this client predicate simply lets the UI show the Equip button and the RPC becomes the gate). We deliberately do **NOT** convert premium-exclusive rows to permanent ownership from the client (OQ-1).

- [ ] **Step 1: Write the failing test**

Append to `test/services/cosmetics_service_test.dart`. Add this stub at the top of the file (below imports) if not already present from another task:

```dart
class StubPurchaseService extends PurchaseService {
  StubPurchaseService(this.premium) : super.test();
  final bool premium;
  @override
  Future<bool> isPremium() async => premium;
}
```

Add `import 'package:sakina/services/purchase_service.dart';` to the test imports. Then append:

```dart
  group('equipCosmetic', () {
    test('success: mirrors equipped cache + emits analytics', () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [
          {'item_type': 'lantern_skin', 'item_id': 'emerald_jade'},
        ],
      );
      fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await equipCosmetic(
        itemType: 'lantern_skin',
        itemId: 'emerald_jade',
      );

      expect(result.success, isTrue);
      expect(fakeSync.rpcCalls.single['params'],
          {'p_item_type': 'lantern_skin', 'p_item_id': 'emerald_jade'});
      final state = await getCosmeticsState();
      expect(state.equippedLanternSkin, 'emerald_jade');
      expect(events.single.$1, 'cosmetic_equipped');
      expect(events.single.$2,
          {'item_type': 'lantern_skin', 'item_id': 'emerald_jade'});
    });

    test('backdrop success updates the backdrop slot, not the skin slot',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [
          {'item_type': 'backdrop', 'item_id': 'laylat_night'},
        ],
      );
      fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

      await equipCosmetic(itemType: 'backdrop', itemId: 'laylat_night');
      final state = await getCosmeticsState();
      expect(state.equippedBackdrop, 'laylat_night');
      expect(state.equippedLanternSkin, 'classic_gold'); // untouched
    });

    test('rejection (unowned → RPC raises → null): equipped cache unchanged',
        () async {
      await hydrateCosmeticsFromSync(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        owned: const [],
      );
      // No handler → null (server raised "cannot equip unowned item").
      final result = await equipCosmetic(
        itemType: 'lantern_skin',
        itemId: 'obsidian_gold',
      );
      expect(result.success, isFalse);
      final state = await getCosmeticsState();
      expect(state.equippedLanternSkin, 'classic_gold');
    });
  });

  group('canEquip (premium-exclusive resolution — OQ-1 conservative)', () {
    test('owned item is always equippable', () async {
      final state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {'moonlit_silver'},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        isPremiumExclusive: false,
        purchaseService: StubPurchaseService(false),
      );
      expect(can, isTrue);
    });

    test('premium-exclusive + premium user (not owned) IS equippable', () async {
      final state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'ramadan_royal',
        isPremiumExclusive: true,
        purchaseService: StubPurchaseService(true),
      );
      expect(can, isTrue);
    });

    test('premium-exclusive + NON-premium user (not owned) is NOT equippable',
        () async {
      final state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'ramadan_royal',
        isPremiumExclusive: true,
        purchaseService: StubPurchaseService(false),
      );
      expect(can, isFalse);
    });

    test('non-exclusive + not owned is NOT equippable (must unlock first)',
        () async {
      final state = CosmeticsState(
        noorBalance: 0,
        equippedLanternSkin: 'classic_gold',
        equippedBackdrop: 'default',
        ownedLanternSkins: {},
        ownedBackdrops: {},
      );
      final can = await canEquip(
        state: state,
        itemType: 'lantern_skin',
        itemId: 'moonlit_silver',
        isPremiumExclusive: false,
        purchaseService: StubPurchaseService(true),
      );
      expect(can, isFalse);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: FAIL — `equipCosmetic` / `canEquip` undefined.

- [ ] **Step 3: Implement `equipCosmetic` + `canEquip`**

Add the import at the top of `lib/services/cosmetics_service.dart`:

```dart
import 'package:sakina/services/purchase_service.dart';
```

Add the functions:

```dart
/// Equips [itemId] via the Lane A `equip_cosmetic` RPC, which verifies
/// ownership server-side (raises "cannot equip unowned item" → null here).
/// On success, mirrors the equipped column into the cache so the Companion
/// stage / Home medallion re-render without a round-trip.
Future<CosmeticActionResult> equipCosmetic({
  required String itemType,
  required String itemId,
}) async {
  if (supabaseSyncService.currentUserId == null) {
    return CosmeticActionResult.failed;
  }

  final ok = await supabaseSyncService.callRpc<bool>(
    'equip_cosmetic',
    {'p_item_type': itemType, 'p_item_id': itemId},
  );
  if (ok != true) return CosmeticActionResult.failed;

  final prefs = await SharedPreferences.getInstance();
  final key = itemType == itemTypeBackdrop
      ? _equippedBackdropKey
      : _equippedSkinKey;
  await prefs.setString(supabaseSyncService.scopedKey(key), itemId);

  CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticEquipped, {
    AnalyticsEvents.propItemType: itemType,
    AnalyticsEvents.propItemId: itemId,
  });
  return CosmeticActionResult.ok;
}

/// Client-side predicate for whether the Equip button should be shown for a
/// catalog row (spec §13 item 6 / OQ-1 — the single premium definition seam).
///
/// Rules (conservative — the spec is silent on whether trial/gift/referral
/// users PERMANENTLY keep premium-exclusive skins, so we never convert them to
/// ownership here; see OQ-1):
///   • Owned (in user_cosmetics or the always-owned default) → equippable.
///   • Premium-exclusive AND the caller is premium (any source: sub, trial,
///     gift, referral — [PurchaseService.isPremium] ORs over all) → equippable
///     WHILE premium is active. The server `equip_cosmetic` remains the final
///     authority; this only decides whether to surface the button.
///   • Otherwise → NOT equippable (the user must unlock/buy it first).
///
/// [purchaseService] is injectable for tests; production passes the default
/// `PurchaseService()`.
Future<bool> canEquip({
  required CosmeticsState state,
  required String itemType,
  required String itemId,
  required bool isPremiumExclusive,
  PurchaseService? purchaseService,
}) async {
  if (state.owns(itemType, itemId)) return true;
  if (isPremiumExclusive) {
    final svc = purchaseService ?? PurchaseService();
    return svc.isPremium();
  }
  return false;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: PASS (all `equipCosmetic` + `canEquip` tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_service_test.dart
git commit -m "feat(cosmetics): equip_cosmetic call + premium-exclusive equippable resolution (§13.6/OQ-1)"
```

---

## Task 7: À-la-carte skin IAP grant + restore reconciliation (DEP-1 / DEP-2)

**Files:**
- Modify: `lib/services/cosmetics_service.dart`
- Test: `test/services/cosmetics_service_test.dart`

**Spec §13 item 4 — non-consumable IAP infra is net-new, NOT reused.** Unlike `ConsumableGrantsService` (SharedPreferences dedup, not cross-device), skin ownership MUST be server-authoritative. The client's job: after a RevenueCat purchase (and on `restorePurchases`), call the server `grant_cosmetic_iap` RPC (**DEP-1** — the RPC does not exist yet; client codes to the contract and degrades gracefully on null) with the transaction id so the server verifies the receipt-derived product↔item mapping and inserts `user_cosmetics(... 'iap')` idempotently. **Refund/restore reconciliation is server-side (DEP-2):** a refund clawback is a webhook `CANCELLATION`-on-skin path (Lane A); the client only re-syncs to reflect it. On `restorePurchases`, the client re-drives `grant_cosmetic_iap` for each owned skin transaction so a reinstalled/second-device user regains ownership.

The à-la-carte SKUs (from the seed catalog `iap_product_id` column): `sakina.skin.obsidian` → `obsidian_gold`, `sakina.skin.masjid` → `masjid_brass`, `sakina.skin.crystal` → `crystal_star`. The client keeps a SKU→item map ONLY to know which transactions are skin purchases; the **server** re-verifies the mapping (never trust the client).

- [ ] **Step 1: Write the failing test**

Append to `test/services/cosmetics_service_test.dart`:

```dart
  group('grantSkinIap (server-authoritative, DEP-1 contract)', () {
    test('success: calls grant_cosmetic_iap with product+txn, mirrors ownership'
        ', emits analytics', () async {
      fakeSync.rpcHandlers['grant_cosmetic_iap'] = (params) async => {
            'granted': true,
            'already_owned': false,
            'item_id': 'obsidian_gold',
          };

      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await grantSkinIap(
        productId: 'sakina.skin.obsidian',
        transactionId: 'txn-abc',
      );

      expect(result.success, isTrue);
      expect(fakeSync.rpcCalls.single['fn'], 'grant_cosmetic_iap');
      expect(fakeSync.rpcCalls.single['params'], {
        'p_item_id': 'obsidian_gold',
        'p_product_id': 'sakina.skin.obsidian',
        'p_transaction_id': 'txn-abc',
      });
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'obsidian_gold'), isTrue);
      expect(events.single.$1, 'cosmetic_iap_purchased');
      expect(events.single.$2,
          {'item_id': 'obsidian_gold', 'product_id': 'sakina.skin.obsidian'});
    });

    test('unknown product id is refused client-side (no RPC, no grant)',
        () async {
      final result = await grantSkinIap(
        productId: 'sakina.tokens_100',
        transactionId: 'txn-1',
      );
      expect(result.success, isFalse);
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('RPC unavailable (DEP-1 not shipped → null): graceful failure',
        () async {
      // No handler registered → callRpc returns null.
      final result = await grantSkinIap(
        productId: 'sakina.skin.masjid',
        transactionId: 'txn-2',
      );
      expect(result.success, isFalse);
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'masjid_brass'), isFalse);
    });

    test('already_owned (idempotent replay / restore): success, no double '
        'analytics', () async {
      fakeSync.rpcHandlers['grant_cosmetic_iap'] = (params) async => {
            'granted': false,
            'already_owned': true,
            'item_id': 'crystal_star',
          };
      final events = <(String, Map<String, dynamic>)>[];
      CosmeticsAnalytics.onAnalyticsEvent = (e, p) => events.add((e, p));
      addTearDown(() => CosmeticsAnalytics.onAnalyticsEvent = null);

      final result = await grantSkinIap(
        productId: 'sakina.skin.crystal',
        transactionId: 'txn-3',
      );

      // Ownership is still ensured in the cache, but no fresh-purchase event.
      expect(result.success, isTrue);
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'crystal_star'), isTrue);
      expect(events, isEmpty);
    });

    test('unauthenticated: no RPC call', () async {
      fakeSync.userId = null;
      final result = await grantSkinIap(
        productId: 'sakina.skin.obsidian',
        transactionId: 'txn-x',
      );
      expect(result.success, isFalse);
      expect(fakeSync.rpcCalls, isEmpty);
    });
  });

  test('skinIapProductToItem maps the three à-la-carte SKUs', () {
    expect(skinIapProductToItem['sakina.skin.obsidian'], 'obsidian_gold');
    expect(skinIapProductToItem['sakina.skin.masjid'], 'masjid_brass');
    expect(skinIapProductToItem['sakina.skin.crystal'], 'crystal_star');
    expect(skinIapProductToItem.containsKey('sakina.tokens_100'), isFalse);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: FAIL — `grantSkinIap` / `skinIapProductToItem` undefined.

- [ ] **Step 3: Implement `grantSkinIap` + the SKU map**

Add to `lib/services/cosmetics_service.dart`:

```dart
/// À-la-carte skin IAP SKUs → catalog item_id. Mirrors the `iap_product_id`
/// column in `20260726000100_seed_cosmetic_catalog.sql`. The client uses this
/// ONLY to recognize which RC transactions are skin purchases and to pass the
/// item_id to the server; the SERVER re-verifies product↔item against the
/// catalog (never trust the client mapping). When SKUs change, this map AND
/// the seed migration must both update.
const Map<String, String> skinIapProductToItem = {
  'sakina.skin.obsidian': 'obsidian_gold',
  'sakina.skin.masjid': 'masjid_brass',
  'sakina.skin.crystal': 'crystal_star',
};

/// Grants a purchased à-la-carte skin server-side (spec §13 item 4 — this is
/// net-new, NOT the SharedPreferences-dedup consumable path). Called from the
/// synchronous purchase path AND from the restore path.
///
/// DEP-1: `grant_cosmetic_iap` does not exist in the merged Lane A migrations
/// yet. The client codes to the contract:
///   grant_cosmetic_iap(p_item_id, p_product_id, p_transaction_id)
///     returns jsonb { granted, already_owned, item_id }
/// and treats a null (RPC missing / raised) as a clean failure so the app
/// degrades gracefully until Lane A ships it. Idempotency + receipt
/// verification + refund clawback are server-side (DEP-2).
///
/// Returns success when the server confirms ownership (granted OR
/// already_owned). Emits `cosmetic_iap_purchased` ONLY on a fresh grant
/// (`granted == true`) so a restore/replay doesn't double-count revenue.
Future<CosmeticActionResult> grantSkinIap({
  required String productId,
  required String transactionId,
}) async {
  if (supabaseSyncService.currentUserId == null) {
    return CosmeticActionResult.failed;
  }
  final itemId = skinIapProductToItem[productId];
  if (itemId == null) {
    // Not a skin SKU — refuse client-side (consumables go through
    // ConsumableGrantsService, not here).
    return CosmeticActionResult.failed;
  }

  final res = await supabaseSyncService.callRpc<Map<String, dynamic>>(
    'grant_cosmetic_iap',
    {
      'p_item_id': itemId,
      'p_product_id': productId,
      'p_transaction_id': transactionId,
    },
  );
  if (res == null) return CosmeticActionResult.failed;

  final granted = res['granted'] == true;
  final alreadyOwned = res['already_owned'] == true;
  if (!granted && !alreadyOwned) return CosmeticActionResult.failed;

  // Server confirmed ownership — mirror into the cache so the wardrobe shows
  // "Equip" immediately; the next sync reconciles.
  await _addOwnedToCache(itemTypeLanternSkin, itemId);

  if (granted) {
    CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticIapPurchased, {
      AnalyticsEvents.propItemId: itemId,
      AnalyticsEvents.propProductId: productId,
    });
  }
  return CosmeticActionResult.ok;
}

/// Re-drives [grantSkinIap] for every skin transaction in a RevenueCat
/// [CustomerInfo] — the restore / reinstall / second-device recovery path
/// (DEP-2). Idempotent server-side (`already_owned`), so replaying the full
/// non-subscription transaction history is safe. Returns the count of
/// transactions processed (granted OR already-owned).
///
/// Callers: the RC `customerInfoUpdateListener` (wired in main.dart) and the
/// explicit "Restore purchases" action. Best-effort — a single failed grant
/// does not abort the loop.
Future<int> reconcileSkinIapsFromCustomerInfo(
  List<({String productId, String transactionId})> transactions,
) async {
  var processed = 0;
  for (final txn in transactions) {
    if (!skinIapProductToItem.containsKey(txn.productId)) continue;
    final result = await grantSkinIap(
      productId: txn.productId,
      transactionId: txn.transactionId,
    );
    if (result.success) processed += 1;
  }
  return processed;
}
```

- [ ] **Step 4: Write the failing test for `reconcileSkinIapsFromCustomerInfo`**

Append to `test/services/cosmetics_service_test.dart`:

```dart
  group('reconcileSkinIapsFromCustomerInfo (restore path, DEP-2)', () {
    test('grants each skin txn, skips non-skin txns, returns processed count',
        () async {
      fakeSync.rpcHandlers['grant_cosmetic_iap'] = (params) async => {
            'granted': false,
            'already_owned': true,
            'item_id': params!['p_item_id'],
          };

      final processed = await reconcileSkinIapsFromCustomerInfo(const [
        (productId: 'sakina.skin.obsidian', transactionId: 't1'),
        (productId: 'sakina.tokens_100', transactionId: 't2'), // skipped
        (productId: 'sakina.skin.crystal', transactionId: 't3'),
      ]);

      expect(processed, 2);
      final fns = fakeSync.rpcCalls.map((c) => c['fn']).toList();
      expect(fns, ['grant_cosmetic_iap', 'grant_cosmetic_iap']);
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'obsidian_gold'), isTrue);
      expect(state.owns('lantern_skin', 'crystal_star'), isTrue);
    });
  });
```

- [ ] **Step 5: Run tests to verify pass**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: PASS (all IAP grant + reconcile tests).

- [ ] **Step 6: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_service_test.dart
git commit -m "feat(cosmetics): server-authoritative skin IAP grant + restore reconcile (§13.4, DEP-1/2)"
```

---

## Task 8: Document the deferred premium-cosmetics grant seam (OQ-2 / §13.7)

**Files:**
- Modify: `lib/services/cosmetics_service.dart`
- Test: `test/services/cosmetics_service_test.dart`

Spec §13 item 7 (entitlement-period reconciliation for subscriber grants — monthly-exclusive + seasonal) and §14 rollout defer premium perks to P4/P5. There is no premium-grant-on-sync RPC in the merged Lane A migrations. Lane B adds a **thin, clearly-deferred hook** `syncPremiumCosmetics()` that calls a future `grant_premium_cosmetics()` RPC when it exists and no-ops (returns 0) gracefully until then. This gives Lane D / the app a single call site to wire on sync now, without inventing the server logic. The entitlement-period backfill remains server-side (Lane A, out of scope).

- [ ] **Step 1: Write the failing test**

Append to `test/services/cosmetics_service_test.dart`:

```dart
  group('syncPremiumCosmetics (deferred — OQ-2/§13.7)', () {
    test('non-premium: no RPC call, returns 0', () async {
      final n = await syncPremiumCosmetics(
        purchaseService: StubPurchaseService(false),
      );
      expect(n, 0);
      expect(fakeSync.rpcCalls, isEmpty);
    });

    test('premium but RPC absent (null): graceful 0, mirrors nothing',
        () async {
      // grant_premium_cosmetics not registered → callRpc returns null.
      final n = await syncPremiumCosmetics(
        purchaseService: StubPurchaseService(true),
      );
      expect(n, 0);
      final state = await getCosmeticsState();
      expect(state.ownedLanternSkins, isEmpty);
    });

    test('premium + RPC grants rows: mirrors granted skins into ownership cache',
        () async {
      fakeSync.rpcHandlers['grant_premium_cosmetics'] = (params) async => {
            'granted': [
              {'item_type': 'lantern_skin', 'item_id': 'ramadan_royal'},
            ],
          };
      final n = await syncPremiumCosmetics(
        purchaseService: StubPurchaseService(true),
      );
      expect(n, 1);
      final state = await getCosmeticsState();
      expect(state.owns('lantern_skin', 'ramadan_royal'), isTrue);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: FAIL — `syncPremiumCosmetics` undefined.

- [ ] **Step 3: Implement the deferred hook**

Add to `lib/services/cosmetics_service.dart`:

```dart
/// DEFERRED (OQ-2 / spec §13 item 7, §14 rollout P4/P5): reconciles the
/// premium-only cosmetic grants (monthly-exclusive skin + seasonal auto-grant)
/// on sync while the subscription is active.
///
/// There is NO `grant_premium_cosmetics` RPC in the merged Lane A migrations
/// yet, and the entitlement-period backfill (granting a subscriber who did NOT
/// open during the drop month) is inherently server-side — a client cannot
/// reconcile a window the server never granted. So this is a THIN forward hook:
/// it calls the future RPC when it exists and no-ops (returns 0) until then,
/// giving the app a single stable call site to wire on sync now.
///
/// When Lane A ships `grant_premium_cosmetics()` (SECURITY DEFINER; grants
/// premium-exclusive/seasonal rows `ON CONFLICT DO NOTHING` when premium is
/// active and the drop_month / islamic_occasions window matches), this hook
/// mirrors any newly-granted rows into the ownership cache. Returns the count
/// of rows granted this sync.
Future<int> syncPremiumCosmetics({PurchaseService? purchaseService}) async {
  if (supabaseSyncService.currentUserId == null) return 0;
  final svc = purchaseService ?? PurchaseService();
  if (!await svc.isPremium()) return 0;

  final res = await supabaseSyncService.callRpc<Map<String, dynamic>>(
    'grant_premium_cosmetics',
  );
  if (res == null) return 0; // RPC not shipped yet — graceful no-op.

  final granted = res['granted'];
  if (granted is! List) return 0;

  var count = 0;
  for (final row in granted) {
    if (row is! Map) continue;
    final type = row['item_type'];
    final id = row['item_id'];
    if (id is! String || type is! String) continue;
    await _addOwnedToCache(type, id);
    count += 1;
  }
  return count;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_service_test.dart
git commit -m "feat(cosmetics): deferred syncPremiumCosmetics forward hook (OQ-2/§13.7)"
```

---

## Task 9: Wire cosmetics hydration into the batch sync service

**Files:**
- Modify: `lib/services/user_data_batch_sync_service.dart`
- Create: `test/services/user_data_batch_sync_cosmetics_test.dart`

The `noor` / `equipped` / `cosmetics` sections of `sync_all_user_data()` (added in `20260726000300`) must be read into the cosmetics caches on every launch/re-sync, alongside the existing hydrate calls. We hydrate defensively: only when the `noor` + `equipped` sections are present (a pre-cosmetics server omits them; leave the cache at defaults rather than zeroing).

- [ ] **Step 1: Write the failing test**

Create `test/services/user_data_batch_sync_cosmetics_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/user_data_batch_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hydrateCosmeticsFromBatchPayload writes all three sections', () async {
    final payload = UserDataBatchPayload.fromRpc({
      'noor': {'balance': 320, 'total_earned': 500, 'total_spent': 180},
      'equipped': {'lantern_skin': 'emerald_jade', 'backdrop': 'laylat_night'},
      'cosmetics': [
        {'item_type': 'lantern_skin', 'item_id': 'emerald_jade',
         'acquired_via': 'milestone'},
        {'item_type': 'backdrop', 'item_id': 'laylat_night',
         'acquired_via': 'noor'},
      ],
    });

    await hydrateCosmeticsFromBatchPayload(payload);

    final state = await getCosmeticsState();
    expect(state.noorBalance, 320);
    expect(state.equippedLanternSkin, 'emerald_jade');
    expect(state.equippedBackdrop, 'laylat_night');
    expect(state.owns('lantern_skin', 'emerald_jade'), isTrue);
    expect(state.owns('backdrop', 'laylat_night'), isTrue);
  });

  test('missing cosmetics sections (pre-cosmetics server) leave defaults',
      () async {
    final payload = UserDataBatchPayload.fromRpc({
      'xp': {'total_xp': 0},
    });

    await hydrateCosmeticsFromBatchPayload(payload);

    final state = await getCosmeticsState();
    expect(state.noorBalance, 0);
    expect(state.equippedLanternSkin, 'classic_gold');
    expect(state.equippedBackdrop, 'default');
    expect(state.ownedLanternSkins, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/user_data_batch_sync_cosmetics_test.dart`
Expected: FAIL — `hydrateCosmeticsFromBatchPayload` undefined.

- [ ] **Step 3: Add the batch-payload hydrator + call it in the sync flow**

In `lib/services/user_data_batch_sync_service.dart`, add the import at the top (with the other service imports):

```dart
import 'package:sakina/services/cosmetics_service.dart';
```

Add this top-level function at the end of the file (after `_boolValue`):

```dart
/// Hydrates the cosmetics-economy caches from the additive `noor`, `equipped`,
/// and `cosmetics` sections of `sync_all_user_data()` (migration
/// 20260726000300). DEFENSIVE: a pre-cosmetics server omits these sections —
/// in that case we leave the caches at their defaults (0 noor, classic_gold /
/// default equipped) rather than zeroing, so an old backend never wipes a
/// user's equipped skin.
Future<void> hydrateCosmeticsFromBatchPayload(
  UserDataBatchPayload payload,
) async {
  final noor = payload.objectSection('noor');
  final equipped = payload.objectSection('equipped');
  if (noor == null || equipped == null) return; // pre-cosmetics server.

  final balance = _intValue(noor['balance']) ?? 0;
  final skin = _stringValue(equipped['lantern_skin']) ?? defaultLanternSkin;
  final backdrop = _stringValue(equipped['backdrop']) ?? defaultBackdrop;
  final owned = payload.listSection('cosmetics') ?? const [];

  await hydrateCosmeticsFromSync(
    noorBalance: balance,
    equippedLanternSkin: skin,
    equippedBackdrop: backdrop,
    owned: owned,
  );
}
```

Then, inside `hydrateUserDataFromBatchRpc()`, add the call immediately after the `quest_progress` hydrate block (after the `_hydrateOrSeedListSection(rows: payload.listSection('quest_progress'), …)` call at line ~193, before the `if (!payload.containsKey('achievements'))` fallback block):

```dart
  await hydrateCosmeticsFromBatchPayload(payload);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/user_data_batch_sync_cosmetics_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Run the existing batch-sync test to confirm no regression**

Run: `flutter test test/services/user_data_batch_sync_service_test.dart`
Expected: PASS (the added call is additive and defensive).

- [ ] **Step 6: Commit**

```bash
git add lib/services/user_data_batch_sync_service.dart test/services/user_data_batch_sync_cosmetics_test.dart
git commit -m "feat(cosmetics): hydrate noor/equipped/cosmetics sync sections into caches"
```

---

## Task 10: Full-suite green + analyze

**Files:** none (verification only)

- [ ] **Step 1: Run all new + touched tests together**

Run:
```bash
flutter test \
  test/services/cosmetics_analytics_names_test.dart \
  test/services/cosmetics_service_test.dart \
  test/services/user_data_batch_sync_cosmetics_test.dart \
  test/services/user_data_batch_sync_service_test.dart \
  test/services/analytics_event_names_leaf_test.dart
```
Expected: PASS, all files.

- [ ] **Step 2: Analyze the touched files**

Run: `flutter analyze lib/services/cosmetics_service.dart lib/services/user_data_batch_sync_service.dart lib/services/analytics_event_names.dart`
Expected: No new errors. (Baseline repo has ~54 pre-existing infos/warnings elsewhere; the goal is zero NEW issues in the touched files.)

- [ ] **Step 3: Commit any analyze fixups (if needed)**

```bash
git add -A
git commit -m "chore(cosmetics): flutter analyze cleanups for Lane B service"
```

---

## Self-Review

**1. Spec coverage** (Lane B hard requirements from §13 + task brief):

| Requirement | Task |
|---|---|
| `CosmeticsService` reads noor/owned/equipped from `sync_all_user_data` (never direct table read) | Task 2 (`hydrateCosmeticsFromSync`, `getCosmeticsState`) + Task 9 (batch wiring) |
| Calls `unlock_cosmetic` / `equip_cosmetic`, surfaces errors via result → snackbar pattern | Tasks 3, 6 (`CosmeticActionResult`, no UI in service) |
| Emits analytics via static `onAnalyticsEvent` hook; constants in `analytics_event_names.dart` | Task 1 + `CosmeticsAnalytics` in Task 2, emitted in 3/4/5/6/7 |
| `award_noor('milestone:N')` ONLY after successful `claim_streak_milestone(N)`, server-shaped reason_key | Task 4 (CRITICAL — explicit ordering + reason_key `milestone:N`) |
| Non-consumable IAP grant path + RC reconciliation (refund/restore); called out as net-new/DEP | Task 7 (`grantSkinIap`, `reconcileSkinIapsFromCustomerInfo`) + DEP-1/DEP-2 |
| Single premium definition; premium-exclusive equippable vs owned; no client conversion to ownership | Task 6 (`canEquip`) + OQ-1 |
| Entitlement-period reconciliation for subscriber grants (or documented defer) | Task 8 (`syncPremiumCosmetics` deferred hook) + OQ-2 |
| Never write economy tables directly (RPC-only) | All mutations via `callRpc`; no `.from(...).upsert` in the service |
| Services Riverpod-free; no Supabase from widgets | `cosmetics_service.dart` imports only the leaf constants + purchase_service + sync service; pinned by leaf test |
| Unit tests mock Supabase/RPC per existing patterns | `FakeSupabaseSyncService` + `StubPurchaseService` throughout |
| TDD: failing test → run(fail) → impl → run(pass) → commit, exact commands | Every task |

Analytics events from spec §7 covered: `cosmetic_equipped`, `noor_earned`, `cosmetic_unlocked{via:noor}`, `cosmetic_iap_purchased`, `milestone_skin_unlocked` (constant added; emission of `milestone_skin_unlocked` specifically is a Lane D concern when the milestone-skin unlock UI lands — the constant is provided so Lane D wires it; Lane B does the Noor-grant + generic unlock). `companion_screen_opened`, `wardrobe_opened`, `cosmetic_previewed`, `premium_exclusive_granted`, `seasonal_granted` are **Lane D/UI + Lane A** concerns (screen/grant surfaces), intentionally out of Lane B scope — noted so the controller doesn't expect them here.

**2. Placeholder scan:** No `TBD` / `implement later` / "add error handling" / "write tests for the above" — every code + test step contains complete content. The deferred hooks (Task 8 `syncPremiumCosmetics`, DEP-1 `grant_cosmetic_iap`) are fully-implemented client code that degrades on `null`, NOT placeholders; their server counterparts are explicitly labeled cross-lane dependencies with contracts.

**3. Type consistency:**
- `CosmeticActionResult` (fields `success`; statics `ok`/`failed`) — defined Task 3, reused Tasks 6, 7 identically.
- `CosmeticsState` (fields `noorBalance`, `equippedLanternSkin`, `equippedBackdrop`, `ownedLanternSkins`, `ownedBackdrops`; method `owns`) — defined Task 2, constructed in Task 6/8 tests with the same named params.
- `CosmeticsAnalytics.emit` / `onAnalyticsEvent` — defined Task 2, used 3/4/5/6/7.
- Cache key constants (`_noorBalanceKey` etc.) + helpers (`_addOwnedToCache`, `_creditNoorCache`, `_debitNoorCache`, `_readOwnedSet`) — each defined once, referenced consistently.
- RPC param names match Lane A signatures exactly: `unlock_cosmetic`/`equip_cosmetic` use `p_item_type`+`p_item_id`; `award_noor` uses `p_reason`+`p_reason_key`; `claim_streak_milestone` uses `p_day` (matches `streak_service.dart`).
- `StubPurchaseService` uses `super.test()` — matches `PurchaseService.test()` constructor and the `premium_grants_service_test.dart` pattern.
- `UserDataBatchPayload` (`fromRpc`, `objectSection`, `listSection`) — reused from the existing sync service, not redefined.

All consistent. Plan is complete.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-25-lantern-cosmetics-02-client-services.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration. REQUIRED SUB-SKILL: superpowers:subagent-driven-development.
2. **Inline Execution** — execute tasks in this session using superpowers:executing-plans, batch execution with checkpoints.

**Before executing, the controller must resolve OQ-1 (premium-exclusive permanent ownership policy) and schedule the Lane A dependencies DEP-1 (`grant_cosmetic_iap` RPC), DEP-2 (webhook skin clawback/restore), and DEP-3 (fix `claim_streak_milestone`).**
