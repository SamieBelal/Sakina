# Lane E — iOS Widget Skin Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the iOS home-screen companion widget render the lantern skin the user equipped in-app, instead of the single hardcoded brass lantern it renders today.

**Architecture:** The widget extension cannot run Flutter's `CustomPainter`, so each skin ships as pre-rendered PNG frames (`companion_<skinId>_<brightness>.png`) exported by a `flutter test` harness that drives the same `LanternPainter` the app uses. `WidgetDataService` adds one additive `lantern_skin` key to the existing App-Group JSON blob, filtered through a **bundled-set allowlist** so the payload can never name a skin whose PNGs are absent from the installed build. The Swift widget resolves the asset through a fallback chain (`equipped skin → classic_gold → the legacy un-prefixed frame`) so it can never render blank. `equipCosmetic` pushes a fresh payload + WidgetKit reload immediately after a successful skin equip.

**Tech Stack:** Flutter/Dart (`flutter test`, `flutter analyze`) · `home_widget` plugin (App Group `group.com.sakina.app.widget`) · SwiftUI + WidgetKit · `swiftc` standalone test harness (no XCTest target exists — see "Pre-existing conditions")

---

## Context you must read before starting

You are picking up Lane E of the Lantern Cosmetics feature (`docs/superpowers/specs/2026-07-25-lantern-cosmetics-design.md`, §5 "iOS widget (the bundle-size constraint)" and §13 item 9). Lanes A/B/C are merged. Read these files once before Task 1:

- `lib/services/widget_data_service.dart` — the single writer of App-Group widget state.
- `ios/SakinaWidget/SakinaCompanionWidget.swift` — the widget you are changing.
- `ios/SakinaWidget/DuaScheduleResolver.swift` + `ios/SakinaWidgetTests/main.swift` — the established "Foundation-only core + `swiftc` harness" pattern you will copy in Tasks 8–9.
- `test/widgets/gen_companion_widget_frames_test.dart` — the existing frame generator you are extending the idea of (you will **not** modify it).

### What already exists (real signatures — do not drift from these)

`lib/services/widget_data_service.dart`:

```dart
const String kWidgetAppGroupId = 'group.com.sakina.app.widget';
const String kWidgetName = 'SakinaWidget';
const String kCompanionWidgetName = 'SakinaCompanionWidget';
const String kWidgetPayloadKey = 'sakina_widget_payload';
const String kDuaTimesWidgetName = 'SakinaDuaTimesWidget';
const String kDuaTimesPayloadKey = 'sakina_dua_times_payload';

class WidgetNamePayload { /* mode, nameKey, name, nameEnglish, arabic,
    transliteration, anchor, checkedInToday, streak, updatedAtIso */ }
// toJson keys: mode, name_key, name, name_english, arabic, transliteration,
//              anchor, checked_in_today, streak, updated_at

abstract class HomeWidgetClient {
  Future<void> setAppGroupId(String id);
  Future<void> saveWidgetData(String key, String? value);
  Future<void> updateWidget({required String name});
}

class WidgetDataService {
  WidgetDataService({HomeWidgetClient? client, DateTime Function()? clock,
                     LocationService? locationService});
  Future<void> initialize();
  Future<void> syncWidget({required AllahName name, required String anchor,
      required int streak, required bool checkedInToday, required bool personalized});
  Future<void> saveDuaTimesSchedule(String scheduleJson);
  Future<void> clearWidget();
}
final WidgetDataService widgetDataService = WidgetDataService();
```

There is **no read method** on `HomeWidgetClient` — you cannot read the payload back out of the shared container. That is why `WidgetDataService` will remember the last payload in memory (Task 3) rather than doing a read-modify-write.

`lib/services/cosmetics_service.dart` (Lane B, merged):

```dart
const String itemTypeLanternSkin = 'lantern_skin';
const String itemTypeBackdrop = 'backdrop';
const String defaultLanternSkin = 'classic_gold';
class CosmeticsState { int noorBalance; String equippedLanternSkin;
    String equippedBackdrop; Set<String> ownedLanternSkins; Set<String> ownedBackdrops; }
Future<CosmeticsState> getCosmeticsState();
Future<CosmeticActionResult> equipCosmetic({required String itemType, required String itemId});
```

`lib/features/streaks/models/companion_state.dart` — `enum CompanionBrightness { endowedDim, dormant, pendingUnlit, atRiskUnlit, dim, glowing, fullyLit }`.

`lib/features/streaks/models/lantern_skin.dart` — 9 skins: `LanternSkin.all` = `classic_gold, moonlit_silver, emerald_jade, obsidian_gold, rose_quartz, ramadan_gold`; `LanternSkin.sculpted` = `masjid_brass, crystal_star, ramadan_royal`.

`lib/features/streaks/widgets/lantern_painter.dart`:

```dart
LanternPainter({required double illumination, required double glow,
    required bool dormant, required bool protected, required double pulse,
    double? wear, ui.FragmentShader? ambientShader, bool ambient = true,
    LanternSkin skin = LanternSkin.classicGold});
```

`ios/SakinaWidget/SakinaCompanionWidget.swift` today:

```swift
private struct CompanionPayload: Decodable {
    let checked_in_today: Bool; let streak: Int; let updated_at: String; let mode: String
}
private struct CompanionDisplay {
    let brightness: String; let streak: Int; let checkedIn: Bool
    let loggedOut: Bool; let atRisk: Bool
}
private func companionImage(_ brightness: String) -> Image? {
    guard let url = Bundle.main.url(forResource: "companion_\(brightness)", withExtension: "png"), ...
}
```

`resolveCompanion(at:phase:)` only ever produces these six brightness strings: `endowedDim`, `dim`, `glowing`, `fullyLit`, `atRiskUnlit`, `pendingUnlit`. **`dormant` is unreachable in the widget** (streak ≤ 0 renders `endowedDim`), which is why you will not export a `dormant` frame per skin.

### Decisions already made (do not relitigate)

1. **Backdrops are OUT of scope for the widget.** Spec §5: the widget keeps its cream container and renders only the lantern skin. Nothing in this plan touches `Backdrop` / `BackdropPainter`.
2. **Skins only travel to the widget through the App-Group payload.** No Supabase access from the widget extension; no economy RPC is touched by this lane.
3. **Bundled-set policy (with the byte math).** Measured today: the seven legacy 660 px frames total **1,412,050 B**; excluding the unreachable `dormant` frame (316,940 B) that is **1,095,110 B ≈ 1.04 MiB of PNG per skin at 660 px**. Exporting at 360 px cuts pixel area to `(360/660)² = 0.2975`; PNG bytes for this content track area at roughly 0.30–0.40×, so expect **~330–420 KB per skin**, i.e. **~2.9–3.8 MB for all nine skins (54 PNGs)**.
   **Policy: bundle all nine skins.** Task 7 measures the real total and applies this gate:
   - measured total **≤ 4.0 MB** → keep all nine (expected outcome);
   - measured total **> 4.0 MB** → trim `kWidgetBundledSkinIds` to the curated four `classic_gold, obsidian_gold, masjid_brass, crystal_star` (the default plus the three à-la-carte real-money skins from `skinIapProductToItem` — a paid skin must never silently fall back), delete the other files, re-run the frame-set test.
   The set is one constant, so the gate is a one-line change either way.
4. **Naming scheme:** `companion_<skinId>_<brightness>.png`, e.g. `companion_emerald_jade_fullyLit.png`. The legacy `companion_<brightness>.png` files stay exactly as they are and act as the last-resort fallback.

### Pre-existing conditions (read carefully — these are not yours to fix)

- **The seven legacy PNGs are currently modified in the working tree.** `test/widgets/gen_companion_widget_frames_test.dart` rewrites them on *every* full `flutter test` run, which is why `git status` shows them dirty. **Do not revert them, do not regenerate them, do not delete them.** This plan never runs that generator and never edits that file. (Your new generator is env-gated precisely so it does not add to this churn — see Task 6.)
- **There is no Swift/XCTest target for the widget extension.** `ios/Runner.xcodeproj` has `RunnerTests` only; `ios/SakinaWidgetTests/main.swift` is a standalone `swiftc`-compiled harness, not an Xcode target. You will follow that same pattern (Task 8) rather than inventing an XCTest target. Because top-level executable code is only legal in a file named `main.swift`, the new harness goes in a subdirectory: `ios/SakinaWidgetTests/CompanionSkin/main.swift`.
- **Xcode target membership is automatic for `ios/SakinaWidget/`.** Per `ios/SakinaWidget/SETUP.md` §"Xcode target membership — automatic", that directory is a `PBXFileSystemSynchronizedRootGroup` with an empty `exceptions = ()` list, so new `.swift` and `.png` files there join the widget target with no manual step. **This does not apply to files added anywhere else** — `ios/SakinaWidgetTests/` is outside the synced group (correct: test code must not ship).
- **`flutter build ios` is NOT a gate in this plan** (too slow). Gates are `flutter test`, `flutter analyze`, and the `swiftc` harness. Device/Xcode verification is an explicit MANUAL follow-up (Task 10).
- **Known-flaky baseline:** `test/services/purchase_service_premium_started*` and the `find_duas` eval fail on a clean checkout. A full-suite non-zero exit is not necessarily your regression — always check the named failures.

---

## File Structure

| File | Create/Modify | Responsibility |
|---|---|---|
| `lib/services/widget_data_service.dart` | Modify | Widget frame contract (default skin id, widget-reachable brightness list, bundled-skin allowlist, asset-name function, eligibility filter); `lantern_skin` payload field; `setEquippedLanternSkin`; skin reset on `clearWidget` |
| `lib/services/widget_sync.dart` | Modify | `resolveWidgetLanternSkin()` seam + pass the equipped skin into `syncWidget` |
| `lib/services/cosmetics_service.dart` | Modify | After a successful **skin** equip, push the payload + reload the widget (best-effort) |
| `test/services/widget_lantern_frame_contract_test.dart` | Create | Pins the contract constants against the real skin catalog + brightness enum |
| `test/services/widget_data_service_test.dart` | Modify | Payload carries the skin; unbundled ids fall back; `setEquippedLanternSkin`; `clearWidget` resets |
| `test/services/widget_sync_lantern_skin_test.dart` | Create | `resolveWidgetLanternSkin` reads the cache and survives a failed read |
| `test/services/cosmetics_equip_widget_refresh_test.dart` | Create | Skin equip refreshes the widget; backdrop/failed equip do not |
| `test/widgets/gen_companion_skin_frames_test.dart` | Create | The re-runnable PNG export harness (env-gated) |
| `test/widgets/companion_widget_frame_set_test.dart` | Create | Always-on guard: every bundled skin has a complete, non-empty frame set on disk |
| `ios/SakinaWidget/CompanionSkinResolver.swift` | Create | Foundation-only payload decode + skin sanitisation + asset-candidate chain (the unit-testable core) |
| `ios/SakinaWidget/SakinaCompanionWidget.swift` | Modify | Read `lantern_skin`, carry it on `CompanionDisplay`, resolve the image through the candidate chain |
| `ios/SakinaWidgetTests/CompanionSkin/main.swift` | Create | `swiftc` harness for the resolver |
| `ios/SakinaWidget/companion_<skinId>_<brightness>.png` | Create (generated) | 54 exported frames (9 skins × 6 widget-reachable brightnesses) |
| `ios/SakinaWidget/SETUP.md` | Modify | Document the new naming scheme, generator command, and fallback chain |

---

### Task 1: Widget frame contract + eligibility filter

The single source of truth for *which* skins the installed build can render and *what* the files are called. Everything else (payload writer, exporter, disk guard, Swift fallback) hangs off these constants.

**Files:**
- Modify: `lib/services/widget_data_service.dart` (insert after `kDuaTimesPayloadKey`, around line 34)
- Test: `test/services/widget_lantern_frame_contract_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/services/widget_lantern_frame_contract_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/services/widget_data_service.dart';

void main() {
  final catalogIds = <String>{
    for (final s in [...LanternSkin.all, ...LanternSkin.sculpted]) s.id,
  };

  test('every bundled skin id exists in the code catalog', () {
    expect(kWidgetBundledSkinIds.difference(catalogIds), isEmpty,
        reason: 'kWidgetBundledSkinIds names a skin LanternSkin does not define');
  });

  test('the widget default skin is itself bundled', () {
    expect(kWidgetBundledSkinIds, contains(kDefaultWidgetLanternSkinId));
    expect(kDefaultWidgetLanternSkinId, LanternSkin.classicGold.id);
  });

  test('widget brightnesses cover every reachable state and exclude dormant',
      () {
    expect(kWidgetCompanionBrightnesses, isNot(contains(CompanionBrightness.dormant)),
        reason: 'the Swift resolveCompanion never emits dormant — do not export it');
    final expected = CompanionBrightness.values.toSet()
      ..remove(CompanionBrightness.dormant);
    expect(kWidgetCompanionBrightnesses.toSet(), expected);
  });

  test('frame asset name is <skinId>_<brightness>', () {
    expect(
      companionWidgetFrameAsset('emerald_jade', CompanionBrightness.fullyLit),
      'companion_emerald_jade_fullyLit.png',
    );
  });

  test('a bundled skin id passes the eligibility filter unchanged', () {
    expect(widgetEligibleSkinId('emerald_jade'), 'emerald_jade');
  });

  test('an unbundled or malformed skin id falls back to the default', () {
    expect(widgetEligibleSkinId('not_a_skin'), kDefaultWidgetLanternSkinId);
    expect(widgetEligibleSkinId(''), kDefaultWidgetLanternSkinId);
    expect(widgetEligibleSkinId('../../etc/passwd'), kDefaultWidgetLanternSkinId);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/widget_lantern_frame_contract_test.dart`

Expected: FAIL at compile time — `Error: Undefined name 'kWidgetBundledSkinIds'.` (plus the same for `kDefaultWidgetLanternSkinId`, `kWidgetCompanionBrightnesses`, `companionWidgetFrameAsset`, `widgetEligibleSkinId`).

- [ ] **Step 3: Write minimal implementation**

In `lib/services/widget_data_service.dart`, add this import next to the existing ones at the top of the file:

```dart
import 'package:sakina/features/streaks/models/companion_state.dart';
```

(`companion_state.dart` is a dependency-free model file; `lib/services` already imports feature models elsewhere, e.g. `dua_live_activity_service.dart`.)

Then insert the contract block immediately after `const String kDuaTimesPayloadKey = 'sakina_dua_times_payload';`:

```dart
// ── Lantern-skin widget contract (Lane E) ────────────────────────────────────
// The widget extension can't run LanternPainter, so each skin ships as
// pre-rendered PNGs generated by
// `GEN_WIDGET_FRAMES=1 flutter test test/widgets/gen_companion_skin_frames_test.dart`.
// These four declarations are the ONE place the Dart writer, the PNG exporter,
// the on-disk guard test, and the Swift lookup agree.

/// The skin the companion widget falls back to whenever the payload is missing,
/// unreadable, or names a skin this build has no frames for. Mirrors
/// `defaultLanternSkin` in `cosmetics_service.dart` — duplicated deliberately so
/// the widget contract never depends on the economy layer, and pinned equal by
/// `test/services/widget_lantern_frame_contract_test.dart`.
const String kDefaultWidgetLanternSkinId = 'classic_gold';

/// The brightness states the companion widget can actually reach.
/// [CompanionBrightness.dormant] is deliberately absent: the Swift
/// `resolveCompanion` maps streak <= 0 to `endowedDim` and never emits dormant,
/// so a per-skin dormant frame would add ~300 KB × 9 for a state no widget can
/// ever display.
const List<CompanionBrightness> kWidgetCompanionBrightnesses =
    <CompanionBrightness>[
  CompanionBrightness.endowedDim,
  CompanionBrightness.pendingUnlit,
  CompanionBrightness.atRiskUnlit,
  CompanionBrightness.dim,
  CompanionBrightness.glowing,
  CompanionBrightness.fullyLit,
];

/// Skins whose PNG frames are bundled in THIS build of the widget extension.
///
/// Deliberately a hand-maintained literal, NOT derived from `LanternSkin.all`:
/// adding a skin to the code catalog (or the server `cosmetic_catalog`) must NOT
/// make it widget-eligible until someone exports and commits its frames. That
/// asymmetry is what prevents a server-side catalog change from producing a
/// blank widget on already-installed builds — an equipped skin that isn't in
/// this set is silently rendered as [kDefaultWidgetLanternSkinId].
const Set<String> kWidgetBundledSkinIds = <String>{
  'classic_gold',
  'moonlit_silver',
  'emerald_jade',
  'obsidian_gold',
  'rose_quartz',
  'ramadan_gold',
  'masjid_brass',
  'crystal_star',
  'ramadan_royal',
};

/// File name of the exported frame for [skinId] at [brightness]. Mirrored by
/// `companionAssetCandidates` in `ios/SakinaWidget/CompanionSkinResolver.swift`.
String companionWidgetFrameAsset(String skinId, CompanionBrightness brightness) =>
    'companion_${skinId}_${brightness.name}.png';

/// Widget-eligibility filter. Applied by the single payload writer, so a skin id
/// this build cannot render never reaches the shared container at all.
String widgetEligibleSkinId(String equippedSkinId) =>
    kWidgetBundledSkinIds.contains(equippedSkinId)
        ? equippedSkinId
        : kDefaultWidgetLanternSkinId;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/widget_lantern_frame_contract_test.dart`

Expected: `00:0X +6: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/services/widget_data_service.dart test/services/widget_lantern_frame_contract_test.dart
git commit -m "feat(widget): lantern-skin frame contract + eligibility filter"
```

---

### Task 2: Payload carries the equipped skin

Add `lantern_skin` to the App-Group blob. Additive and backward-compatible in both directions: an old widget build ignores the unknown key (Swift `Decodable` skips unknown keys), and a new widget reading a payload written by an old app build sees the key missing and falls back (Task 8/9).

**Files:**
- Modify: `lib/services/widget_data_service.dart` (`WidgetNamePayload`, `WidgetDataService.syncWidget`)
- Test: `test/services/widget_data_service_test.dart`

- [ ] **Step 1: Write the failing test**

Append these four tests inside the existing `void main() { ... }` of `test/services/widget_data_service_test.dart`, immediately after the `'changed streak reloads the widget'` test:

```dart
  test('payload carries the default lantern skin when none is supplied',
      () async {
    final client = _FakeHomeWidgetClient();
    await build(client).syncWidget(
      name: name,
      anchor: 'a',
      streak: 3,
      checkedInToday: true,
      personalized: true,
    );
    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['lantern_skin'], 'classic_gold');
  });

  test('payload carries a bundled equipped skin', () async {
    final client = _FakeHomeWidgetClient();
    await build(client).syncWidget(
      name: name,
      anchor: 'a',
      streak: 3,
      checkedInToday: true,
      personalized: true,
      lanternSkinId: 'emerald_jade',
    );
    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['lantern_skin'], 'emerald_jade');
  });

  test('a skin with no bundled frames is written as the default, never raw',
      () async {
    final client = _FakeHomeWidgetClient();
    await build(client).syncWidget(
      name: name,
      anchor: 'a',
      streak: 3,
      checkedInToday: true,
      personalized: true,
      lanternSkinId: 'skin_from_a_future_catalog',
    );
    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['lantern_skin'], 'classic_gold',
        reason: 'an unbundled id would make the widget look for a missing PNG');
  });

  test('changing only the skin busts the perf guard', () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 3,
        checkedInToday: true, personalized: true);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 3,
        checkedInToday: true, personalized: true,
        lanternSkinId: 'moonlit_silver');
    expect(client.updates, 4,
        reason: 'two distinct payloads × two widgets (Name + companion)');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/widget_data_service_test.dart`

Expected: FAIL at compile time — `Error: No named parameter with the name 'lanternSkinId'.`

- [ ] **Step 3: Write minimal implementation**

In `lib/services/widget_data_service.dart`, replace the `WidgetNamePayload` class (lines 42–82) with:

```dart
class WidgetNamePayload {
  const WidgetNamePayload({
    required this.mode,
    required this.nameKey,
    required this.name,
    required this.nameEnglish,
    required this.arabic,
    required this.transliteration,
    required this.anchor,
    required this.checkedInToday,
    required this.streak,
    required this.updatedAtIso,
    required this.lanternSkin,
  });

  /// `personalized` = show [nameKey]; `daily` = extension picks the daily Name.
  final String mode;
  final String nameKey;
  final String name;
  final String nameEnglish;
  final String arabic;
  final String transliteration;
  final String anchor;
  final bool checkedInToday;
  final int streak;
  final String updatedAtIso;

  /// The equipped lantern skin id, already filtered through
  /// [widgetEligibleSkinId] by the writer — the companion widget loads
  /// `companion_<lanternSkin>_<brightness>.png`. Additive key: widget builds
  /// older than Lane E decode the blob fine and ignore it.
  final String lanternSkin;

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'name_key': nameKey,
        'name': name,
        'name_english': nameEnglish,
        'arabic': arabic,
        'transliteration': transliteration,
        'anchor': anchor,
        'checked_in_today': checkedInToday,
        'streak': streak,
        'updated_at': updatedAtIso,
        'lantern_skin': lanternSkin,
      };

  /// Same payload with a new skin + timestamp. Lets [WidgetDataService] re-push
  /// on equip without a read-modify-write (the [HomeWidgetClient] seam has no
  /// read).
  WidgetNamePayload withLanternSkin(String skinId, String newUpdatedAtIso) =>
      WidgetNamePayload(
        mode: mode,
        nameKey: nameKey,
        name: name,
        nameEnglish: nameEnglish,
        arabic: arabic,
        transliteration: transliteration,
        anchor: anchor,
        checkedInToday: checkedInToday,
        streak: streak,
        updatedAtIso: newUpdatedAtIso,
        lanternSkin: skinId,
      );

  String encode() => jsonEncode(toJson());
}
```

Then, inside `class WidgetDataService`, add this field directly below `String? _lastDuaTimesWritten;`:

```dart
  /// Last equipped lantern skin this process knows about, already filtered to a
  /// bundled id. Remembered so an equip (which knows the skin but not the Name)
  /// and a sync (which knows the Name but may not pass a skin) can't clobber
  /// each other.
  String _equippedSkin = kDefaultWidgetLanternSkinId;
```

Finally, replace the `syncWidget` method (lines 147–169) with:

```dart
  Future<void> syncWidget({
    required AllahName name,
    required String anchor,
    required int streak,
    required bool checkedInToday,
    required bool personalized,
    String? lanternSkinId,
  }) async {
    if (lanternSkinId != null) {
      _equippedSkin = widgetEligibleSkinId(lanternSkinId);
    }
    final payload = WidgetNamePayload(
      mode: personalized ? 'personalized' : 'daily',
      nameKey: widgetNameKeyFor(name),
      name: name.transliteration,
      nameEnglish: name.english,
      arabic: name.arabic,
      transliteration: name.transliteration,
      anchor: anchor,
      checkedInToday: checkedInToday,
      streak: streak,
      // UTC + trailing 'Z' so the Swift ISO8601DateFormatter can parse it; the
      // extension compares it against the current LOCAL day (§10.7).
      updatedAtIso: _clock().toUtc().toIso8601String(),
      lanternSkin: _equippedSkin,
    );
    await _write(payload.encode());
  }
```

Update the doc comment above `syncWidget` by appending this line to it:

```dart
  /// [lanternSkinId] is the user's equipped skin; pass null to keep the last
  /// known one (an equip may have set it since the previous sync).
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/widget_data_service_test.dart`

Expected: `00:0X +9: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/services/widget_data_service.dart test/services/widget_data_service_test.dart
git commit -m "feat(widget): add lantern_skin to the App-Group payload"
```

---

### Task 3: Immediate refresh — `setEquippedLanternSkin` + sign-out reset

The equip path knows the skin but not the Name/streak, so it re-pushes the *last* payload with the skin swapped. `clearWidget` must reset the remembered skin, or a second user on the device inherits the first user's lantern.

**Files:**
- Modify: `lib/services/widget_data_service.dart` (`_lastPayload` field, `setEquippedLanternSkin`, `clearWidget`, `_write`)
- Test: `test/services/widget_data_service_test.dart`

- [ ] **Step 1: Write the failing test**

Append these four tests inside the existing `void main() { ... }` of `test/services/widget_data_service_test.dart`, after the tests added in Task 2:

```dart
  test('setEquippedLanternSkin re-pushes the last payload with the new skin',
      () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 7,
        checkedInToday: true, personalized: true);
    expect(client.updates, 2);

    await svc.setEquippedLanternSkin('emerald_jade');

    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['lantern_skin'], 'emerald_jade');
    expect(json['streak'], 7, reason: 'the rest of the payload is preserved');
    expect(json['name_key'], 'al-malik');
    expect(client.updates, 4, reason: 'the equip re-pushed and reloaded');
  });

  test('equipping the same skin twice is a no-op', () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 7,
        checkedInToday: true, personalized: true);
    await svc.setEquippedLanternSkin('emerald_jade');
    await svc.setEquippedLanternSkin('emerald_jade');
    expect(client.updates, 4, reason: 'the second equip must not reload');
  });

  test('equipping a skin with no bundled frames reverts to classic_gold',
      () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 7, checkedInToday: true,
        personalized: true, lanternSkinId: 'emerald_jade');
    await svc.setEquippedLanternSkin('skin_from_a_future_catalog');
    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['lantern_skin'], 'classic_gold');
  });

  test('an equip before the first sync is carried by the next sync', () async {
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    await svc.setEquippedLanternSkin('moonlit_silver');
    expect(client.saved, isEmpty, reason: 'nothing to patch yet');

    await svc.syncWidget(
        name: name, anchor: 'a', streak: 1,
        checkedInToday: true, personalized: true);
    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['lantern_skin'], 'moonlit_silver');
  });

  test('clearWidget resets the skin so the next user starts on classic_gold',
      () async {
    SharedPreferences.setMockInitialValues({});
    final client = _FakeHomeWidgetClient();
    final svc = build(client);
    await svc.syncWidget(
        name: name, anchor: 'a', streak: 7, checkedInToday: true,
        personalized: true, lanternSkinId: 'emerald_jade');
    await svc.clearWidget();

    await svc.syncWidget(
        name: name, anchor: 'a', streak: 1,
        checkedInToday: true, personalized: true);
    final json = jsonDecode(client.lastSavedValue!) as Map<String, dynamic>;
    expect(json['lantern_skin'], 'classic_gold');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/widget_data_service_test.dart`

Expected: FAIL at compile time — `Error: The method 'setEquippedLanternSkin' isn't defined for the class 'WidgetDataService'.`

- [ ] **Step 3: Write minimal implementation**

In `lib/services/widget_data_service.dart`, add this field directly below the `_equippedSkin` field added in Task 2:

```dart
  /// The last payload written this process. Kept so [setEquippedLanternSkin]
  /// can re-push with only the skin changed — the [HomeWidgetClient] seam is
  /// write-only, so there is nothing to read back.
  WidgetNamePayload? _lastPayload;
```

In `syncWidget`, record it — insert this line immediately before `await _write(payload.encode());`:

```dart
    _lastPayload = payload;
```

Add the new method directly after `saveDuaTimesSchedule`:

```dart
  /// Push the newly equipped lantern skin to the companion widget immediately.
  ///
  /// Called by `equipCosmetic` on a successful `lantern_skin` equip so the
  /// home-screen lantern changes while the user is still looking at the
  /// wardrobe, instead of waiting for the next sync. Unbundled ids are filtered
  /// to [kDefaultWidgetLanternSkinId] — the widget can only render frames this
  /// build actually ships.
  ///
  /// Before the first [syncWidget] of the process there is no payload to patch;
  /// the skin is remembered and the next sync carries it.
  Future<void> setEquippedLanternSkin(String skinId) async {
    final eligible = widgetEligibleSkinId(skinId);
    if (eligible == _equippedSkin) return;
    _equippedSkin = eligible;

    final last = _lastPayload;
    if (last == null) return;
    final patched =
        last.withLanternSkin(eligible, _clock().toUtc().toIso8601String());
    _lastPayload = patched;
    await _write(patched.encode());
  }
```

In `clearWidget`, reset the skin state — replace the two lines `_lastWritten = null;` / `_lastDuaTimesWritten = null;` with:

```dart
    _lastWritten = null;
    _lastDuaTimesWritten = null;
    // A second user on this device must not inherit the first user's lantern.
    _equippedSkin = kDefaultWidgetLanternSkinId;
    _lastPayload = null;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/widget_data_service_test.dart`

Expected: `00:0X +14: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/services/widget_data_service.dart test/services/widget_data_service_test.dart
git commit -m "feat(widget): immediate companion reload on lantern-skin equip"
```

---

### Task 4: Sync reads the equipped skin from the cosmetics cache

`syncHomeWidget()` runs on foreground/data-sync completion. It must feed the equipped skin so a cold start shows the right lantern.

**Files:**
- Modify: `lib/services/widget_sync.dart`
- Test: `test/services/widget_sync_lantern_skin_test.dart` (create)

> **Note on coverage:** `syncHomeWidget()` itself has no existing test — it reads `rootBundle`, the check-in cache, and the streak cache. Rather than fake three services for one line, this task introduces `resolveWidgetLanternSkin` as an injectable seam and tests *that*; the one-line call site is covered by `flutter analyze` and the manual verification in Task 10.

- [ ] **Step 1: Write the failing test**

Create `test/services/widget_sync_lantern_skin_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/widget_data_service.dart';
import 'package:sakina/services/widget_sync.dart';

CosmeticsState _state(String skinId) => CosmeticsState(
      noorBalance: 0,
      equippedLanternSkin: skinId,
      equippedBackdrop: 'default',
      ownedLanternSkins: <String>{skinId},
      ownedBackdrops: <String>{},
    );

void main() {
  test('returns the equipped skin from the cosmetics cache', () async {
    final skin = await resolveWidgetLanternSkin(
      readCosmetics: () async => _state('emerald_jade'),
    );
    expect(skin, 'emerald_jade');
  });

  test('an unreadable cosmetics cache falls back to the widget default',
      () async {
    final skin = await resolveWidgetLanternSkin(
      readCosmetics: () async => throw StateError('prefs unavailable'),
    );
    expect(skin, kDefaultWidgetLanternSkinId);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/widget_sync_lantern_skin_test.dart`

Expected: FAIL at compile time — `Error: The method 'resolveWidgetLanternSkin' isn't defined`.

- [ ] **Step 3: Write minimal implementation**

In `lib/services/widget_sync.dart`, add the import next to the existing ones:

```dart
import 'cosmetics_service.dart';
```

Add this function directly above `Future<void> syncHomeWidget(...)`:

```dart
/// The lantern skin the widget payload should carry. Reads the cosmetics cache
/// (hydrated from `sync_all_user_data`); a failed read must never stop a widget
/// refresh, so it degrades to the widget default rather than throwing.
///
/// [readCosmetics] is injectable for tests; production uses [getCosmeticsState].
Future<String> resolveWidgetLanternSkin({
  Future<CosmeticsState> Function()? readCosmetics,
}) async {
  try {
    final state = await (readCosmetics ?? getCosmeticsState)();
    return state.equippedLanternSkin;
  } catch (_) {
    return kDefaultWidgetLanternSkinId;
  }
}
```

Then wire it into `syncHomeWidget` — replace the `await widgetDataService.syncWidget(...)` call with:

```dart
    final lanternSkinId = await resolveWidgetLanternSkin();
    await widgetDataService.syncWidget(
      name: inputs.name,
      anchor: anchor,
      streak: streak,
      checkedInToday: inputs.checkedInToday,
      personalized: inputs.personalized,
      lanternSkinId: lanternSkinId,
    );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/widget_sync_lantern_skin_test.dart test/services/widget_sync_test.dart`

Expected: `00:0X +5: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/services/widget_sync.dart test/services/widget_sync_lantern_skin_test.dart
git commit -m "feat(widget): sync the equipped lantern skin into the payload"
```

---

### Task 5: `equipCosmetic` refreshes the widget

The mutation point. Skin equips refresh; backdrop equips do not (backdrops are out of scope for the widget); failed equips do not.

**Files:**
- Modify: `lib/services/cosmetics_service.dart` (`equipCosmetic`)
- Test: `test/services/cosmetics_equip_widget_refresh_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/services/cosmetics_equip_widget_refresh_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/cosmetics_service.dart';
import 'package:sakina/services/supabase_sync_service.dart';
import 'package:sakina/services/widget_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_supabase_sync_service.dart';

/// Records the skin pushes instead of touching the platform channel.
class _RecordingWidgetData extends WidgetDataService {
  final List<String> pushed = <String>[];

  @override
  Future<void> setEquippedLanternSkin(String skinId) async => pushed.add(skinId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseSyncService fakeSync;
  late _RecordingWidgetData widgetData;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSync = FakeSupabaseSyncService(userId: 'user-1');
    SupabaseSyncService.debugSetInstance(fakeSync);
    widgetData = _RecordingWidgetData();
  });

  tearDown(SupabaseSyncService.debugReset);

  test('a successful skin equip pushes the skin to the widget', () async {
    fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

    final result = await equipCosmetic(
      itemType: itemTypeLanternSkin,
      itemId: 'emerald_jade',
      widgetData: widgetData,
    );

    expect(result.success, isTrue);
    expect(widgetData.pushed, <String>['emerald_jade']);
  });

  test('a backdrop equip never touches the widget (backdrops are in-app only)',
      () async {
    fakeSync.rpcHandlers['equip_cosmetic'] = (params) async => true;

    await equipCosmetic(
      itemType: itemTypeBackdrop,
      itemId: 'laylat_night',
      widgetData: widgetData,
    );

    expect(widgetData.pushed, isEmpty);
  });

  test('a rejected equip does not push a skin the server refused', () async {
    // No handler → callRpc returns null (the RPC raised).
    final result = await equipCosmetic(
      itemType: itemTypeLanternSkin,
      itemId: 'emerald_jade',
      widgetData: widgetData,
    );

    expect(result.success, isFalse);
    expect(widgetData.pushed, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/cosmetics_equip_widget_refresh_test.dart`

Expected: FAIL at compile time — `Error: No named parameter with the name 'widgetData'.`

- [ ] **Step 3: Write minimal implementation**

In `lib/services/cosmetics_service.dart`, add the import next to the existing service imports (this file uses the `package:` form, unlike `widget_sync.dart`):

```dart
import 'package:sakina/services/widget_data_service.dart';
```

Replace the signature and tail of `equipCosmetic` (leave the RPC call and rejection branch exactly as they are). The signature becomes:

```dart
Future<CosmeticActionResult> equipCosmetic({
  required String itemType,
  required String itemId,
  WidgetDataService? widgetData,
}) async {
```

and the success tail — everything from `final prefs = await SharedPreferences.getInstance();` to `return CosmeticActionResult.ok;` — becomes:

```dart
  final prefs = await SharedPreferences.getInstance();
  final key =
      itemType == itemTypeBackdrop ? _equippedBackdropKey : _equippedSkinKey;
  await prefs.setString(supabaseSyncService.scopedKey(key), itemId);

  // Push the new lantern to the iOS home-screen widget right away, so the
  // cosmetic promise doesn't visibly break on the home screen until the next
  // sync. Skins only — backdrops are in-app surfaces and never reach the widget
  // (spec §5). Best-effort: a widget failure must never fail the equip.
  if (itemType == itemTypeLanternSkin) {
    try {
      await (widgetData ?? widgetDataService).setEquippedLanternSkin(itemId);
    } catch (_) {
      // Widget refresh is cosmetic; the next syncHomeWidget will catch up.
    }
  }

  CosmeticsAnalytics.emit(AnalyticsEvents.cosmeticEquipped, {
    AnalyticsEvents.propItemType: itemType,
    AnalyticsEvents.propItemId: itemId,
  });
  return CosmeticActionResult.ok;
}
```

Also extend the doc comment above `equipCosmetic` by appending:

```dart
/// On a successful `lantern_skin` equip it also pushes the skin to the iOS
/// companion widget ([WidgetDataService.setEquippedLanternSkin]); [widgetData]
/// is injectable for tests, production uses the global `widgetDataService`.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/cosmetics_equip_widget_refresh_test.dart test/services/cosmetics_service_test.dart`

Expected: `00:0X +N: All tests passed!` (the existing `cosmetics_service_test.dart` equip tests must still pass — they omit `widgetData`, so they hit the real global service, whose `setEquippedLanternSkin` short-circuits with `_lastPayload == null` and performs no platform call).

- [ ] **Step 5: Commit**

```bash
git add lib/services/cosmetics_service.dart test/services/cosmetics_equip_widget_refresh_test.dart
git commit -m "feat(cosmetics): refresh the iOS widget on lantern-skin equip"
```

---

### Task 6: PNG export harness + on-disk frame-set guard

Two files with distinct jobs: a generator you run on purpose, and a fast guard that runs in every suite.

The generator is gated behind `GEN_WIDGET_FRAMES=1` deliberately. The legacy generator (`gen_companion_widget_frames_test.dart`) is *not* gated, which is why its seven PNGs are permanently dirty in `git status`; a 54-file version of that churn would be unbearable. **Do not modify the legacy generator** — see "Pre-existing conditions".

**Files:**
- Create: `test/widgets/gen_companion_skin_frames_test.dart`
- Create: `test/widgets/companion_widget_frame_set_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/widgets/companion_widget_frame_set_test.dart`:

```dart
// Guard: every widget-eligible skin must have a COMPLETE set of exported frames
// committed under ios/SakinaWidget/. This is what stops kWidgetBundledSkinIds
// from outrunning the PNGs on disk (which would show a fallback lantern, or on
// a broken fallback chain, nothing at all).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/services/widget_data_service.dart';

void main() {
  test('every bundled skin has a complete widget frame set on disk', () {
    final dir = Directory('ios/SakinaWidget');
    expect(dir.existsSync(), isTrue,
        reason: 'run from the flutter/ project root');

    final missing = <String>[];
    for (final skinId in kWidgetBundledSkinIds) {
      for (final brightness in kWidgetCompanionBrightnesses) {
        final file =
            File('${dir.path}/${companionWidgetFrameAsset(skinId, brightness)}');
        if (!file.existsSync() || file.lengthSync() == 0) {
          missing.add(file.path);
        }
      }
    }

    expect(missing, isEmpty,
        reason: 'regenerate with: GEN_WIDGET_FRAMES=1 flutter test '
            'test/widgets/gen_companion_skin_frames_test.dart');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/companion_widget_frame_set_test.dart`

Expected: FAIL — `Expected: empty / Actual: [ios/SakinaWidget/companion_classic_gold_endowedDim.png, ...54 paths...]` with the regenerate hint.

- [ ] **Step 3: Write minimal implementation**

Create `test/widgets/gen_companion_skin_frames_test.dart`:

```dart
// Regenerates the per-SKIN lantern frames the iOS companion widget composites.
// WidgetKit can't run LanternPainter, so each equippable skin ships as one PNG
// per widget-reachable brightness, written straight into the extension's
// file-system-synchronized group (ios/SakinaWidget/) so they auto-bundle.
//
//   GEN_WIDGET_FRAMES=1 flutter test test/widgets/gen_companion_skin_frames_test.dart
//
// Gated behind the env var on purpose: it writes ~54 binaries, and an ungated
// generator dirties them on every full `flutter test` run. Re-run it whenever a
// skin's palette/form changes, whenever kWidgetBundledSkinIds changes, and
// whenever LanternPainter's geometry changes; then commit the PNGs.
//
// Rendering deliberately mirrors gen_companion_widget_frames_test.dart (same
// painter, same params, pulse: 0.0 for a neutral resting pose, transparent
// background) so a skinned frame is pixel-comparable to the legacy default
// frame — only the size (360 vs 660) and the skin differ.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/streaks/models/companion_state.dart';
import 'package:sakina/features/streaks/models/lantern_skin.dart';
import 'package:sakina/features/streaks/widgets/lantern_painter.dart';
import 'package:sakina/services/widget_data_service.dart';

/// Widget-resolution export size (spec §5: ~360px). The in-app avatar stays
/// full-res because it is code-drawn; only these static frames are sized down.
const double _frameSize = 360.0;

Future<void> _renderFrame(
  String outPath,
  LanternSkin skin,
  CompanionBrightness brightness,
) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final p = CompanionState(brightness: brightness, protected: false).params;
  LanternPainter(
    illumination: p.illum,
    glow: p.glow,
    wear: p.wear,
    dormant: p.dormant,
    protected: false,
    pulse: 0.0, // neutral resting pose (no bob/sway extreme) for a static frame
    skin: skin,
  ).paint(canvas, const Size(_frameSize, _frameSize));
  final img = await rec
      .endRecording()
      .toImage(_frameSize.toInt(), _frameSize.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(outPath).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  final skinsById = <String, LanternSkin>{
    for (final s in [...LanternSkin.all, ...LanternSkin.sculpted]) s.id: s,
  };

  test(
    'export companion widget frames for every bundled skin',
    () async {
      final dir = Directory('ios/SakinaWidget');
      expect(dir.existsSync(), isTrue,
          reason: 'run from the flutter/ project root');

      var written = 0;
      for (final skinId in kWidgetBundledSkinIds) {
        final skin = skinsById[skinId];
        expect(skin, isNotNull,
            reason: 'kWidgetBundledSkinIds names an unknown skin: $skinId');
        for (final brightness in kWidgetCompanionBrightnesses) {
          final out =
              '${dir.path}/${companionWidgetFrameAsset(skinId, brightness)}';
          await _renderFrame(out, skin!, brightness);
          expect(File(out).lengthSync(), greaterThan(0));
          written++;
        }
      }
      expect(written,
          kWidgetBundledSkinIds.length * kWidgetCompanionBrightnesses.length);
      // ignore: avoid_print
      print('wrote $written companion frames into ${dir.path}');
    },
    skip: Platform.environment['GEN_WIDGET_FRAMES'] == null
        ? 'set GEN_WIDGET_FRAMES=1 to regenerate the widget frames'
        : false,
  );
}
```

- [ ] **Step 4: Run the generator, then the guard**

Run: `GEN_WIDGET_FRAMES=1 flutter test test/widgets/gen_companion_skin_frames_test.dart`

Expected: `wrote 54 companion frames into ios/SakinaWidget` then `00:0X +1: All tests passed!`

Run: `flutter test test/widgets/companion_widget_frame_set_test.dart`

Expected: `00:0X +1: All tests passed!`

Confirm the generator is skipped without the env var — Run: `flutter test test/widgets/gen_companion_skin_frames_test.dart`

Expected: `00:0X +0 ~1: All tests skipped.`

- [ ] **Step 5: Commit (code only — PNGs land in Task 7)**

```bash
git add test/widgets/gen_companion_skin_frames_test.dart test/widgets/companion_widget_frame_set_test.dart
git commit -m "feat(widget): per-skin frame export harness + on-disk frame guard"
```

---

### Task 7: Measure the bundle cost, apply the gate, commit the frames

**Files:**
- Create (generated): `ios/SakinaWidget/companion_<skinId>_<brightness>.png` × 54
- Modify (only if the gate trips): `lib/services/widget_data_service.dart` (`kWidgetBundledSkinIds`)

- [ ] **Step 1: Count and measure**

```bash
ls ios/SakinaWidget/companion_*_*.png | wc -l
du -ch ios/SakinaWidget/companion_*_*.png | tail -1
```

Expected: `54`, and a total in the **2.9–3.8 MB** range (derived in "Decisions already made": 1,095,110 B per skin at 660 px × `(360/660)² = 0.2975`, times a 1.0–1.35 PNG-entropy factor, times 9 skins).

Note the glob `companion_*_*.png` matches only the new per-skin files: every legacy name (`companion_dim.png`, `companion_atRiskUnlit.png`, …) has exactly one underscore.

- [ ] **Step 2: Apply the gate**

- Total **≤ 4.0 MB** → no change; proceed to Step 3. (Expected path.)
- Total **> 4.0 MB** → trim to the curated four. Replace `kWidgetBundledSkinIds` in `lib/services/widget_data_service.dart` with:

```dart
const Set<String> kWidgetBundledSkinIds = <String>{
  // Trimmed to fit the widget-asset budget (see the Lane E plan, Task 7).
  // The default plus the three a-la-carte real-money skins: a paid skin must
  // never silently fall back on the home screen. Earned skins fall back to
  // classic_gold on the widget only; they still render fully in-app.
  'classic_gold',
  'obsidian_gold',
  'masjid_brass',
  'crystal_star',
};
```

then delete the now-unbundled frames and re-run the generator + guard:

```bash
rm ios/SakinaWidget/companion_moonlit_silver_*.png \
   ios/SakinaWidget/companion_emerald_jade_*.png \
   ios/SakinaWidget/companion_rose_quartz_*.png \
   ios/SakinaWidget/companion_ramadan_gold_*.png \
   ios/SakinaWidget/companion_ramadan_royal_*.png
flutter test test/widgets/companion_widget_frame_set_test.dart test/services/widget_lantern_frame_contract_test.dart
```

Expected: `00:0X +7: All tests passed!`

- [ ] **Step 3: Verify nothing else in the widget folder changed**

```bash
git status --short ios/SakinaWidget/
```

Expected: only `??` (untracked) lines for the new `companion_<skin>_<brightness>.png` files. The seven legacy `companion_<brightness>.png` files may still show as ` M` — that is the pre-existing dirt described in "Pre-existing conditions"; **leave it alone and do not stage them.**

- [ ] **Step 4: Run the Dart gates**

```bash
flutter test test/services/widget_data_service_test.dart test/services/widget_lantern_frame_contract_test.dart test/services/widget_sync_lantern_skin_test.dart test/services/cosmetics_equip_widget_refresh_test.dart test/widgets/companion_widget_frame_set_test.dart
flutter analyze lib/services test/services test/widgets
```

Expected: `All tests passed!` and no new analyzer errors (the repo baseline has ~54 pre-existing infos/warnings).

- [ ] **Step 5: Commit**

```bash
git add ios/SakinaWidget/companion_*_*.png lib/services/widget_data_service.dart
git commit -m "feat(widget): export 360px lantern frames for the bundled skins"
```

---

### Task 8: Foundation-only Swift resolver + `swiftc` harness

`SakinaCompanionWidget.swift` imports SwiftUI/WidgetKit and cannot be compiled by a CLI harness. So the testable core moves into a Foundation-only file, exactly as `DuaScheduleResolver.swift` does for the duʿā-times widget.

**Files:**
- Create: `ios/SakinaWidget/CompanionSkinResolver.swift`
- Create: `ios/SakinaWidgetTests/CompanionSkin/main.swift`

> Requires the Xcode command-line tools (`swiftc`) — macOS only, and not part of `flutter test`.

- [ ] **Step 1: Write the failing test**

Create `ios/SakinaWidgetTests/CompanionSkin/main.swift`:

```swift
// Standalone TDD harness for the companion widget's lantern-skin resolution.
//
// The widget extension can't run under XCTest without a full Xcode target
// (there isn't one), so we compile the Foundation-only resolver together with
// this file via `swiftc` and run it directly — same pattern as
// ios/SakinaWidgetTests/main.swift:
//
//   swiftc ios/SakinaWidget/CompanionSkinResolver.swift \
//          ios/SakinaWidgetTests/CompanionSkin/main.swift \
//          -o /tmp/companion_skin_tests && /tmp/companion_skin_tests
//
// Lives in a subdirectory because top-level executable code is only legal in a
// file named main.swift, and ios/SakinaWidgetTests/main.swift is taken.
// Exits non-zero if any check fails.

import Foundation

var failures = 0
func check(_ cond: Bool, _ msg: String) {
    if cond {
        print("PASS: \(msg)")
    } else {
        print("FAIL: \(msg)")
        failures += 1
    }
}

func payload(skinLine: String) -> String {
    """
    {
      "mode": "personalized",
      "name_key": "al-malik",
      "checked_in_today": true,
      "streak": 12,
      "updated_at": "2026-07-26T09:00:00.000Z"\(skinLine)
    }
    """
}

// ---------------------------------------------------------------------------
// Backward compatibility: a payload written by an app build older than Lane E
// has no lantern_skin key. It must still decode, and resolve to the default.
// ---------------------------------------------------------------------------
do {
    let p = decodeCompanionPayload(payload(skinLine: ""))
    check(p != nil, "a payload without lantern_skin still decodes")
    check(p?.streak == 12, "the rest of the payload decodes normally")
    check(sanitizedLanternSkinId(p?.lantern_skin) == kDefaultLanternSkinId,
          "a missing lantern_skin resolves to classic_gold")
}

// ---------------------------------------------------------------------------
// Forward path: an equipped skin is carried through verbatim.
// ---------------------------------------------------------------------------
do {
    let p = decodeCompanionPayload(payload(skinLine: ",\n  \"lantern_skin\": \"emerald_jade\""))
    check(sanitizedLanternSkinId(p?.lantern_skin) == "emerald_jade",
          "an equipped skin id is used as-is")
}

// ---------------------------------------------------------------------------
// Hostile / garbled ids must never reach a Bundle resource lookup.
// ---------------------------------------------------------------------------
do {
    check(sanitizedLanternSkinId("../../etc/passwd") == kDefaultLanternSkinId,
          "a path-traversal id falls back to the default")
    check(sanitizedLanternSkinId("") == kDefaultLanternSkinId,
          "an empty id falls back to the default")
    check(sanitizedLanternSkinId("Emerald_Jade") == kDefaultLanternSkinId,
          "asset names are lowercase; a mixed-case id falls back")
    check(sanitizedLanternSkinId(nil) == kDefaultLanternSkinId,
          "a nil id falls back to the default")
    check(decodeCompanionPayload("not json at all") == nil,
          "garbage JSON decodes to nil, not a crash")
    check(decodeCompanionPayload(nil) == nil, "a nil raw payload decodes to nil")
}

// ---------------------------------------------------------------------------
// The asset fallback chain: specific skin -> classic_gold -> legacy frame.
// A widget must never be able to render blank.
// ---------------------------------------------------------------------------
do {
    let c = companionAssetCandidates(skinId: "emerald_jade", brightness: "fullyLit")
    check(c == ["companion_emerald_jade_fullyLit",
                "companion_classic_gold_fullyLit",
                "companion_fullyLit"],
          "a non-default skin gets the full three-step fallback chain")

    let d = companionAssetCandidates(skinId: "classic_gold", brightness: "dim")
    check(d == ["companion_classic_gold_dim", "companion_dim"],
          "the default skin does not repeat itself in the chain")

    let u = companionAssetCandidates(skinId: "!!bad!!", brightness: "glowing")
    check(u == ["companion_classic_gold_glowing", "companion_glowing"],
          "a rejected id resolves to the default skin's chain")
}

print(failures == 0 ? "\nALL PASSED" : "\n\(failures) CHECK(S) FAILED")
exit(failures == 0 ? 0 : 1)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
swiftc ios/SakinaWidget/CompanionSkinResolver.swift \
       ios/SakinaWidgetTests/CompanionSkin/main.swift \
       -o /tmp/companion_skin_tests && /tmp/companion_skin_tests
```

Expected: FAIL — `error: no such file or directory: 'ios/SakinaWidget/CompanionSkinResolver.swift'`

- [ ] **Step 3: Write minimal implementation**

Create `ios/SakinaWidget/CompanionSkinResolver.swift`:

```swift
// Foundation-only core of the companion widget's lantern-skin resolution.
//
// Split out of SakinaCompanionWidget.swift (which imports SwiftUI/WidgetKit and
// therefore can't be compiled by a CLI test harness) so the payload decoding,
// id sanitisation, and asset fallback chain are unit-testable — same split as
// DuaScheduleResolver.swift. Tested by ios/SakinaWidgetTests/CompanionSkin/main.swift.
//
// Auto-bundled: ios/SakinaWidget/ is a Xcode-16 file-system-synchronized group,
// so this file compiles into the widget target with no manual "add to target".

import Foundation

/// The skin the widget falls back to. MUST match `kDefaultWidgetLanternSkinId`
/// in `lib/services/widget_data_service.dart` and `LanternSkin.classicGold.id`.
let kDefaultLanternSkinId = "classic_gold"

/// The subset of the shared widget payload the companion widget reads.
///
/// `lantern_skin` is optional ON PURPOSE: payloads written by an app build older
/// than Lane E have no such key, and `Decodable` must not fail on them (the
/// widget would fall back to its logged-out state and lose the streak).
/// Unknown keys are ignored by `Decodable`, so the reverse direction — an old
/// widget reading a new payload — is safe too.
struct CompanionPayload: Decodable {
    let checked_in_today: Bool
    let streak: Int
    let updated_at: String
    let mode: String
    let lantern_skin: String?
}

/// Decode the raw App-Group JSON. Returns nil for a missing/garbled blob.
func decodeCompanionPayload(_ raw: String?) -> CompanionPayload? {
    guard let raw = raw,
          let data = raw.data(using: .utf8),
          let payload = try? JSONDecoder().decode(CompanionPayload.self, from: data)
    else { return nil }
    return payload
}

/// Accept only ids that can safely address a bundled asset: lowercase ASCII,
/// digits, and underscores. Anything else (a path fragment, mixed case, an
/// empty string, a nil) resolves to the default rather than being interpolated
/// into a `Bundle.main.url(forResource:)` lookup.
func sanitizedLanternSkinId(_ raw: String?) -> String {
    guard let raw = raw, !raw.isEmpty, raw.count <= 64 else {
        return kDefaultLanternSkinId
    }
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")
    guard raw.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
        return kDefaultLanternSkinId
    }
    return raw
}

/// Asset base names to try, most specific first:
///   1. the equipped skin's frame            (`companion_<skin>_<brightness>`)
///   2. the default skin's frame             (`companion_classic_gold_<brightness>`)
///   3. the legacy un-prefixed frame         (`companion_<brightness>`)
///
/// Step 2 covers a skin equipped on a newer app build than the installed widget
/// has frames for (the Dart writer already filters those, but the widget must
/// not depend on the writer being current). Step 3 is the last resort that keeps
/// pre-Lane-E installs and any missed export from rendering blank.
func companionAssetCandidates(skinId: String, brightness: String) -> [String] {
    let skin = sanitizedLanternSkinId(skinId)
    var names = ["companion_\(skin)_\(brightness)"]
    if skin != kDefaultLanternSkinId {
        names.append("companion_\(kDefaultLanternSkinId)_\(brightness)")
    }
    names.append("companion_\(brightness)")
    return names
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
swiftc ios/SakinaWidget/CompanionSkinResolver.swift \
       ios/SakinaWidgetTests/CompanionSkin/main.swift \
       -o /tmp/companion_skin_tests && /tmp/companion_skin_tests
```

Expected: 13 `PASS:` lines then `ALL PASSED`, exit code 0.

- [ ] **Step 5: Commit**

```bash
git add ios/SakinaWidget/CompanionSkinResolver.swift ios/SakinaWidgetTests/CompanionSkin/main.swift
git commit -m "feat(widget): Foundation-only lantern-skin resolver + swiftc harness"
```

---

### Task 9: Wire the resolver into `SakinaCompanionWidget.swift`

Replace the hardcoded `companion_<brightness>.png` lookup with the skin-aware chain.

**Files:**
- Modify: `ios/SakinaWidget/SakinaCompanionWidget.swift`

- [ ] **Step 1: Delete the now-duplicated payload struct and decoder**

Remove the `// MARK: - Payload (subset of the shared widget payload)` block's `private struct CompanionPayload { ... }` (lines 38–43) — it now lives in `CompanionSkinResolver.swift` as an internal type. Replace `loadCompanionPayload()` (lines 45–52) with:

```swift
private func loadCompanionPayload() -> CompanionPayload? {
    guard let defaults = UserDefaults(suiteName: kAppGroupId) else { return nil }
    return decodeCompanionPayload(defaults.string(forKey: kPayloadKey))
}
```

- [ ] **Step 2: Carry the skin on `CompanionDisplay`**

Replace the `CompanionDisplay` struct (lines 66–72) with:

```swift
private struct CompanionDisplay {
    let brightness: String   // frame key: "endowedDim", "dim", ...
    let skin: String         // lantern skin id: "classic_gold", "emerald_jade", ...
    let streak: Int
    let checkedIn: Bool
    let loggedOut: Bool
    let atRisk: Bool
}
```

- [ ] **Step 3: Resolve the skin in `resolveCompanion`**

In `resolveCompanion(at:phase:)`, the logged-out early return becomes:

```swift
    guard let p = payload else {
        return CompanionDisplay(brightness: "endowedDim", skin: kDefaultLanternSkinId,
                                streak: 0, checkedIn: false, loggedOut: true,
                                atRisk: false)
    }
```

and the final return becomes:

```swift
    return CompanionDisplay(brightness: brightness,
                            skin: sanitizedLanternSkinId(p.lantern_skin),
                            streak: streak, checkedIn: checkedIn,
                            loggedOut: false, atRisk: atRisk)
```

- [ ] **Step 4: Resolve the image through the candidate chain**

Replace `companionImage(_:)` (lines 108–115) with:

```swift
private func companionImage(skinId: String, brightness: String) -> Image? {
    for name in companionAssetCandidates(skinId: skinId, brightness: brightness) {
        if let url = Bundle.main.url(forResource: name, withExtension: "png"),
           let data = try? Data(contentsOf: url),
           let ui = UIImage(data: data) {
            return Image(uiImage: ui)
        }
    }
    return nil
}
```

Update both call sites. In `CompanionSmallView.body`:

```swift
            if let img = companionImage(skinId: display.skin,
                                        brightness: display.brightness) {
                img.resizable().scaledToFit().frame(maxHeight: 92)
```

In `CompanionMediumView.body`:

```swift
            if let img = companionImage(skinId: display.skin,
                                        brightness: display.brightness) {
                img.resizable().scaledToFit().frame(maxWidth: 118, maxHeight: 118)
```

(`CompanionAccessoryView` deliberately renders an SF Symbol, not the lantern — the Lock Screen tints everything monochrome. Leave it unchanged.)

- [ ] **Step 5: Update the file header comment**

Replace the second paragraph of the header comment (the one beginning "WidgetKit can't run the Flutter CustomPainter") with:

```swift
// WidgetKit can't run the Flutter CustomPainter or animate, so the lantern is a
// set of PRE-RENDERED PNG frames — one per (skin × brightness), named
// companion_<skinId>_<brightness>.png and generated by
// `GEN_WIDGET_FRAMES=1 flutter test test/widgets/gen_companion_skin_frames_test.dart`.
// The widget picks the frame for the current streak state AND the equipped skin
// (read from the payload's `lantern_skin` key), then composites the live streak
// number + a reverent label as SwiftUI on top. Skin resolution and the asset
// fallback chain live in CompanionSkinResolver.swift (unit-tested); backdrops
// are in-app only and never reach the widget (spec §5).
```

- [ ] **Step 6: Verify the resolver harness still passes and nothing else regressed**

```bash
swiftc ios/SakinaWidget/CompanionSkinResolver.swift \
       ios/SakinaWidgetTests/CompanionSkin/main.swift \
       -o /tmp/companion_skin_tests && /tmp/companion_skin_tests
grep -n "companionImage(" ios/SakinaWidget/SakinaCompanionWidget.swift
```

Expected: `ALL PASSED`, and exactly three `companionImage(` hits — the definition plus the two view call sites, all using the `skinId:brightness:` label form.

> There is no compile gate here short of an Xcode build. `swiftc` cannot compile the SwiftUI/WidgetKit file standalone, and `flutter build ios` is out of scope for this plan. The real compile check happens in the MANUAL step in Task 10 — do not claim this file compiles until then.

- [ ] **Step 7: Commit**

```bash
git add ios/SakinaWidget/SakinaCompanionWidget.swift
git commit -m "feat(widget): render the equipped lantern skin in the companion widget"
```

---

### Task 10: Documentation + manual verification checklist

**Files:**
- Modify: `ios/SakinaWidget/SETUP.md`

- [ ] **Step 1: Document the new asset contract**

In `ios/SakinaWidget/SETUP.md`, under the `## Third widget — SakinaCompanionWidget` section, add this subsection immediately after the existing bullet that mentions `gen_companion_widget_frames_test.dart`:

```markdown
### Lantern skins on the widget (Lane E, 2026-07-26)

- The widget renders the **equipped lantern skin**, read from the `lantern_skin`
  key of the shared `sakina_widget_payload` blob. Backdrops are in-app only and
  never reach the widget (spec §5).
- Frames are named `companion_<skinId>_<brightness>.png` (e.g.
  `companion_emerald_jade_fullyLit.png`), 360 px, six brightnesses per skin —
  `dormant` is excluded because `resolveCompanion` can never emit it.
- Regenerate after any skin palette/form change or `LanternPainter` geometry
  change, then commit the PNGs:

  ```bash
  GEN_WIDGET_FRAMES=1 flutter test test/widgets/gen_companion_skin_frames_test.dart
  ```

  The generator is env-gated so a normal `flutter test` doesn't churn ~54
  binaries. `test/widgets/companion_widget_frame_set_test.dart` runs in every
  suite and fails if a bundled skin is missing frames.
- Which skins are widget-eligible is the hand-maintained `kWidgetBundledSkinIds`
  in `lib/services/widget_data_service.dart`. Adding a skin to `LanternSkin` or
  to the server `cosmetic_catalog` does NOT make it widget-eligible — export and
  commit its frames, then add the id. An equipped-but-unbundled skin is written
  to the payload as `classic_gold`, so an installed build can never be asked for
  a PNG it doesn't have.
- Asset lookup falls back `companion_<skin>_<b>` → `companion_classic_gold_<b>` →
  `companion_<b>` (`CompanionSkinResolver.swift`), so the widget can't render
  blank. The legacy un-prefixed 660 px frames are kept as that last resort.
- Swift-side unit tests (no XCTest target exists for the extension):

  ```bash
  swiftc ios/SakinaWidget/CompanionSkinResolver.swift \
         ios/SakinaWidgetTests/CompanionSkin/main.swift \
         -o /tmp/companion_skin_tests && /tmp/companion_skin_tests
  ```
```

- [ ] **Step 2: Run the full gate**

```bash
flutter test test/services test/widgets/companion_widget_frame_set_test.dart
flutter analyze lib/services test/services test/widgets
```

Expected: `All tests passed!` apart from the known-flaky `purchase_service_premium_started` baseline noted in "Pre-existing conditions"; no new analyzer errors.

- [ ] **Step 3: Commit**

```bash
git add ios/SakinaWidget/SETUP.md
git commit -m "docs(widget): document the lantern-skin frame contract"
```

- [ ] **Step 4: MANUAL — Xcode / device verification (cannot be automated here)**

Hand this checklist to whoever has the device. None of it is a `flutter test` gate.

1. **Target membership.** Open `ios/Runner.xcworkspace`, select the new files, and confirm **Target Membership** shows `SakinaWidgetExtension` for `CompanionSkinResolver.swift` and every `companion_<skin>_<brightness>.png`. They should be ticked automatically (the folder is a `PBXFileSystemSynchronizedRootGroup` with empty `exceptions`), **but verify** — a missed PNG is invisible until the widget silently falls back, and this repo has a documented history of widget-asset target-membership surprises (`SETUP.md` §"Manual Xcode target membership"). `ios/SakinaWidgetTests/` must NOT be a member of any target.
2. **Build.** `flutter build ios --debug --dart-define-from-file=env.json` (first real compile of `SakinaCompanionWidget.swift` + the resolver).
3. **Install + add the "Your Lantern" widget** (Small and Medium) to the home screen.
4. **Baseline:** the lantern renders as before (`classic_gold`) for a user who has never equipped anything.
5. **Equip:** in-app, open the wardrobe (Lane D) and equip `emerald_jade`. The home-screen widget should switch to the jade lantern **without** backgrounding/foregrounding the app. If it lags, that's WidgetKit's reload budget, not a bug — confirm it flips within a minute.
6. **Cold start:** force-quit and relaunch; the widget must still show jade (this exercises Task 4's sync path, not Task 3's in-memory patch).
7. **Fallback:** temporarily equip a skin id not in `kWidgetBundledSkinIds` (easiest via a direct `equip_cosmetic` RPC call in the Supabase SQL editor for the test user, then re-sync). The widget must show `classic_gold` — **never** a blank/black frame.
8. **Sign-out:** sign out, sign in as a second account. The widget must show `classic_gold`, not the first user's skin.
9. **Lock Screen:** the `accessoryRectangular` family still renders the SF Symbol layout unchanged (no lantern PNG, by design).
10. **Bundle size:** compare the `.app` size before/after against the measurement from Task 7.

---

## Open questions for the maintainer

1. **Legacy 660 px frames are now redundant (~1.35 MB).** Once `companion_classic_gold_<b>.png` exists, the seven un-prefixed frames are only reachable as the third fallback link. Deleting them would recover ~1.35 MB, but they're the "can never render blank" backstop and they're currently dirty in the working tree from another lane. This plan **keeps** them. Worth a follow-up decision after the first device verification.
2. **The legacy generator churns binaries on every full `flutter test`.** `gen_companion_widget_frames_test.dart` is ungated, which is why those seven PNGs are permanently modified. Adding the same `GEN_WIDGET_FRAMES` gate would fix it in three lines, but it's another lane's file and outside Lane E's scope. Flagging, not doing.
3. **PNG crush is not applied.** Spec §5 says "360px + PNG-crush", but `oxipng`/`pngquant` aren't in this repo's toolchain and adding a required external binary to a `flutter test` harness is a bad trade. If Task 7's measurement lands uncomfortably close to the gate, run `oxipng -o 4 --strip safe ios/SakinaWidget/companion_*_*.png` manually once and commit the result — output is deterministic, so the guard test still passes, but a regenerate would undo it.
4. **`min_app_version` is client-side only here.** Spec §13 item 9 mentions gating widget eligibility by `min_app_version` from `cosmetic_catalog`. This plan implements the guarantee with a **bundled-set constant compiled into the build**, which is strictly stronger for the failure mode that matters (a server catalog change can't reference PNGs an installed build doesn't have). If the wardrobe should also *tell* the user "this skin won't show on your widget yet", that's a Lane D surface and needs the catalog column read — out of scope here.

## Cross-lane dependencies

- **Lane C (render)** — done. `LanternPainter` already takes `skin:`; the exporter depends on that and on `LanternSkin.all`/`.sculpted` being final. If skin palettes or `LanternForm` geometry change after Task 7, the frames must be regenerated and re-committed.
- **Lane B (client services)** — done. `CosmeticsState.equippedLanternSkin` and `equipCosmetic` are the two contact points (Tasks 4 and 5).
- **Lane D (wardrobe UI)** — no code dependency in either direction, but Lane D is what makes this user-visible; the manual verification in Task 10 step 5 needs the wardrobe to exist.
- **Lane A (backend)** — none. This lane touches no migration, RPC, or economy table.

---

## Self-Review

**Spec coverage** (§5 "iOS widget", §13 item 9):

| Requirement | Task |
|---|---|
| Pre-rendered PNG per skin × brightness | 6, 7 |
| Export at ~360 px | 6 (`_frameSize = 360.0`) |
| Backdrops excluded from the widget | Stated in "Decisions"; enforced in Task 5 (skins-only refresh) |
| Bundle-size fallback: cap to a curated subset | 7 Step 2 (explicit gate + the exact replacement constant) |
| Frame generator loops skins | 6 |
| Skin field in the App-Group payload, written on sync | 2, 4 |
| Swift `TimelineProvider` reads the equipped skin | 9 |
| Replace the hardcoded `companion_<brightness>.png` lookup | 8, 9 |
| Immediate refresh on equip | 3, 5 |
| Only bundled skins are widget-eligible | 1 (`kWidgetBundledSkinIds` + `widgetEligibleSkinId`), 6 (disk guard) |
| PNG-crush | Not done — Open question 3, with the exact command and the reason |

**Placeholder scan:** every code step contains complete, runnable code; no "TBD", no "similar to Task N", no "add error handling" hand-waves. The two places where behaviour is genuinely conditional (Task 7's byte gate) spell out both branches in full.

**Type/signature consistency, checked against the real files read:**
- `LanternPainter({illumination, glow, dormant, protected, pulse, wear, ambientShader, ambient, skin})` — Task 6 passes exactly these, matching `gen_companion_widget_frames_test.dart` plus `skin:`.
- `CompanionState({brightness, protected}).params` → `CompanionParams{illum, glow, dormant, wear}` — matches `companion_state.dart`.
- `HomeWidgetClient{setAppGroupId, saveWidgetData, updateWidget}` — unchanged; Tasks 2–3 add no new seam method, which is why `setEquippedLanternSkin` patches an in-memory payload instead of reading back.
- `WidgetDataService({client, clock, locationService})` — the test double in Task 5 subclasses it with all-default construction, valid because every parameter is optional.
- `equipCosmetic({itemType, itemId})` → `+ widgetData` in Task 5; the three existing tests in `cosmetics_service_test.dart` omit it and still compile.
- `CosmeticsState({noorBalance, equippedLanternSkin, equippedBackdrop, ownedLanternSkins, ownedBackdrops})` — Task 4's test constructs exactly these five.
- Swift `CompanionPayload` field names are the raw JSON keys (`checked_in_today`, `lantern_skin`, …) with no `CodingKeys`, matching the existing file's style and `WidgetNamePayload.toJson()`.
- Naming is one function on each side — Dart `companionWidgetFrameAsset` and Swift `companionAssetCandidates` — and Task 8's harness pins the Swift strings against the exact names the Dart exporter writes.
