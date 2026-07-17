# Duʿā Times — Rain Window (Phase 2) — Implementation Plan

**Status:** 🅿️ **PARKED** (eng-reviewed 2026-07-16; deliberately not built now)
**Date:** 2026-07-16
**Park rationale:** lowest-priority Phase 2 item; fires rarely; value inversely correlated with the core (arid) audience; costs a permanent on-device-privacy concession + a standing Apple 5.2.5 compliance surface + unproven WeatherKit-JWT risk. All fixable, none fatal — un-park only on a product signal (rainy-market push / seasonal campaign). Prerequisites to address on un-park are in the "If un-parked" section below.
**Depends on:** shipped Duʿā Times engine; spec `docs/superpowers/specs/2026-07-15-dua-acceptance-times-widget-design.md`; a Supabase Edge Function proxy (see §8 — shared dependency with the pending OpenAI proxy in `TODO.md`)

## 1. Goal & Islamic basis

Surface a duʿā prompt when it is **currently raining at the user's location** — one of the authentic times duʿā is not turned back. The Prophet ﷺ said supplication is answered "at the time of the call (to prayer) and under the rain" (Abu Dawud 2540; al-Hakim, graded authentic). This is a real-time, opportunistic window (unlike the calendar/prayer windows), so it must be detected live.

> **Content rule:** the hadith reference is carried verbatim as a `sourceRef`; no fabricated scripture (per `CLAUDE.md`).

## 2. The core problem: rain breaks the on-device invariant

Every other Duʿā Times window is computed **on-device** (prayer astronomy + a seeded calendar) — location never leaves the phone (`lib/services/location_service.dart`). "Is it raining at this lat/lon right now" is a real-time atmospheric observation the phone **cannot** derive locally. It requires sending coordinates to a weather backend. **This feature is the first crack in the "location never leaves the device" invariant** — that is its true cost, not the code (see §6, §9).

## 3. Detection options

| Provider | Key? | Cost / free tier | Location off-device to… | Fit |
|---|---|---|---|---|
| **Apple WeatherKit** (REST) | Restricted **entitlement** + **JWT** (ES256, signed server-side) | **500k calls/mo FREE per Apple Developer *Team*** (shared pool); then $0.50/1k | **Apple** (platform vendor) | ✅ **Recommended** — first-party, best `conditionCode`, most privacy-palatable |
| OpenWeatherMap | API key | ~1k/day free (One Call 3.0 needs a card) | third-party | ⚠️ adds a third-party data-recipient to the privacy label |
| Open-Meteo | none | free tier is **non-commercial only** → **disqualified** for a paid/subscription app | third-party | ❌ license blocker |
| Tomorrow.io | key | rate-limited free, enterprise pricing | third-party | ❌ overkill |

**Decision:** **Apple WeatherKit via a Supabase Edge Function proxy.** First-party keeps the request inside Apple's trust boundary (privacy-label story = "weather comes from Apple Weather, same as the iOS Weather app"), gives the highest-quality current-conditions signal, and the JWT-signing key lives only in Edge Function secrets — never in the IPA (same discipline as `SUPABASE_SERVICE_ROLE_KEY` / the pending OpenAI key).

## 4. Architecture

```
Duʿā card foreground / rebuild  (throttled: ≤1 weather call / 30 min / location cell)
        │  coarse lat/lon (existing LocationService.getCoarseLocation)
        ▼
Supabase Edge Function  `weather-is-raining`  (Deno)
        │  Deno.env WEATHERKIT_KEY (.p8) + KEY_ID + TEAM_ID + SERVICE_ID
        │  sign ES256 JWT → GET weatherkit.apple.com/api/v1/weather/{lang}/{lat}/{lon}?dataSets=currentWeather
        ▼
returns minimal { isRaining: bool, conditionCode: string, asOfUtc }
        │
        ▼
DuaWindowEngine  →  injects DuaWindow(type: rain, tier: special, start=now, end=now+cacheTTL)
        │  priority: below ʿArafah/Laylat/night-third; a transient "happening now" overlay
        ▼
Duʿā card renders the rain window + MANDATORY Apple Weather attribution mark + legal link
```

- **New:** `DuaWindowType.rain` + `DuaWindowDefinition` (sourceRef = Abu Dawud 2540). New Edge Function `supabase/functions/weather-is-raining/index.ts`. New `WeatherService` (Flutter, service-layer) calling the function.
- **Injection:** the rain window is transient — when `isRaining`, the engine adds an active `DuaWindow` spanning `[now, now + TTL]`; it does not persist in the 7-day timeline like calendar windows.
- **Card-only, no push, not in the widget** *(review Issues 1 & 2)*: rain is detected only when the app checks weather (on foreground) — there is NO rain notification (background weather polling isn't feasible/battery-safe) and NO rain in the native widget. `DuaWindowType.rain` MUST be stripped before `saveDuaTimesSchedule` serializes to the App Group, so the widget never shows weather-derived content without the Apple Weather attribution (5.2.5). Pinned by a test.
- **Caching (review Issue 1):** the Edge Function keeps a **server-side per-rounded-cell short-TTL cache** (`cell → {isRaining, asOf}`) so all users in a ~city-sized cell share ONE WeatherKit call — protects the 500k/team quota + caps cost at scale. The client also holds a small local TTL to avoid even calling the function. Cell size is a tunable constant (coarser = more dedup but less edge accuracy).
- **Priority:** rain sits **below** the hero calendar/night windows (it's opportunistic, shouldn't bury ʿArafah) but is surfaced when nothing higher is active. Confirm exact `priorityOf` rank in review (D1).
- **Caching / rate-limit guard (protects the 500k/team quota):** cache the last result per coarse location cell for ~30 min; only call on foreground when the cache is stale; never call in a tight loop. `conditionCode ∈ {rain, drizzle, heavyRain, thunderstorms, …}` → `isRaining`.
- **Edge Function pattern** (context7 `/supabase/supabase`): `Deno.serve` with a CORS/OPTIONS handler; secrets via `supabase secrets set`; verify the caller's Supabase JWT (`auth: 'user'`) so the function isn't open; `fetch` WeatherKit with the signed token; return JSON. Degrade to `{isRaining:false}` on any upstream failure (never break the card).

## 5. App Store & Apple Developer setup (every extra step — checklist)

This is the part with the most non-code work. **None of it requires a separate App-Review approval *gate* (unlike CarPlay/HealthKit-clinical), but two items are enforced *at review* and one changes your privacy disclosure.**

- [ ] **Create a WeatherKit key** (Developer portal → Certificates, IDs & Profiles → Keys → enable WeatherKit): download the `.p8` **private key** once; record **Key ID**, **Team ID**, and a **Service ID** (usually the bundle id). These are the JWT signing inputs. Store the `.p8` + ids in **Edge Function secrets only** — never the IPA.
- [ ] **Enable the WeatherKit capability** on the App ID (Xcode → Signing & Capabilities → + WeatherKit, or the portal). This adds the `com.apple.developer.weatherkit` entitlement. **Self-serve — no request/approval wait.** (Only needed if calling the *native* Swift API; the REST-via-proxy path technically only needs the *key*, but enabling the capability is harmless and future-proofs a native fallback — confirm in review, D3.)
- [ ] **Mandatory Apple Weather attribution (App Review Guideline 5.2.5):** display the **Apple Weather trademark () + a legal link** to Apple's weather data-source attribution page wherever weather-derived content appears (the rain window UI). **Omitting it is a known App Review rejection cause.** `WeatherService.attribution` (native) supplies the mark + URL; for the REST path, hardcode the required mark + the documented legal link. Design this into the rain-window card up front.
- [ ] **App Privacy nutrition label update:** coarse location now **leaves the device**. Update App Store Connect → App Privacy: declare **Coarse Location** as **Data Collected → Used for App Functionality**, transmitted to Apple's WeatherKit service. It is **NOT tracking** (not linked to identity for cross-app ads) → **no ATT prompt required** (confirm the label wording says "not used to track you"). This is a **metadata/label change**, submitted with the next version — not a separate review gate.
- [ ] **No new runtime permission prompt.** Weather is not an iOS permission; location is already granted → the user sees **zero** new system dialogs.
- [ ] **Re-review:** shipping this is a normal app-version update (binary + metadata). Enabling a capability / adding the key does **not** trigger a special standalone review — it rides the next submission. asc-mcp can be used read-only to confirm current capabilities/privacy answers before submission.

## 6. Privacy decision (escalate before building)

For an app whose differentiation is on-device privacy, transmitting coarse location off-device is a **product decision**, not just an engineering one. WeatherKit keeps it inside Apple's first-party boundary (far more defensible than onboarding a third-party weather vendor, which would add an external data-recipient to the label). **Recommendation:** proceed with WeatherKit only, framed transparently ("rain detection uses Apple Weather; your location is sent only to Apple to check current conditions, never stored"), gated behind an explicit opt-in so privacy-sensitive users can decline.

## 7. Phased implementation

**Phase 0 — Apple setup** (§5 checklist): WeatherKit key + capability + secrets. ~0.5d (has account-admin dependency).
**Phase 1 — Edge Function** `weather-is-raining`: ES256 JWT signing, WeatherKit `currentWeather` fetch, `{isRaining, conditionCode, asOfUtc}` contract, caller-JWT verification, caching/rate guard, graceful upstream-failure degrade. ~1.5–2d.
**Phase 2 — Flutter**: `WeatherService` → engine hook injecting `DuaWindowType.rain`; reuse `LocationService.getCoarseLocation`; 30-min per-cell cache; opt-in toggle; **mandatory attribution UI** on the rain card. ~1.5–2d.
**Phase 3 — degrade + tests** *(expanded by review)*: mock WeatherKit responses; lat/lon spoofing.
- Flutter: rain=true injects a window at the right `priorityOf`; failure/timeout → `{isRaining:false}`, no window, card never breaks; client TTL fresh → no function call.
- **Compliance (Issue 2):** `DuaWindowType.rain` is STRIPPED from the widget payload; the Apple Weather mark + legal link render whenever rain shows on the card.
- Edge Function (Deno): cell-cache HIT → shared result, no WeatherKit call; upstream 5xx → `{isRaining:false}`; caller without a valid Supabase JWT → rejected; `conditionCode` map (rain/drizzle/heavyRain→true, clear→false). ~1.5d.

## 8. Risks / blockers

1. **Privacy-label regression is the real cost** — breaks the on-device invariant. Escalate as a deliberate product/privacy call, not an engineering detail.
2. **Attribution enforcement (5.2.5)** — forgetting the Apple Weather mark + legal link is a known rejection; must be designed into the UI.
3. **Edge Function platform — already proven (risk downgraded by review).** The Edge Function *platform* is live: 4 functions ship today (`_shared`, `notify-referral-confirmed`, `revenuecat-webhook`, `send-scheduled-notifications`), and `revenuecat-webhook` already handles a secret. So rain ships its OWN `weather-is-raining` function on the proven platform — it does NOT block on the unshipped OpenAI proxy (`TODO.md`). The only net-new secret-handling wrinkle is ES256 JWT *signing* with the WeatherKit `.p8` (vs a static secret). Rain-is-rare + the server cell-cache (Issue 1) protect the 500k/team quota.

## 9. Open decisions (recommendations — confirm in review)

- **D1 — Priority rank:** where does `rain` sit in `priorityOf`? Rec: below all hero calendar/night windows, above nothing-active — an opportunistic overlay.
- **D2 — Cache TTL / window length:** Rec: 30-min per-cell weather cache; rain window shown for the TTL then re-checked on next foreground.
- **D3 — Native capability vs REST-only:** Rec: REST-via-proxy for v1 (key never in IPA); enable the capability anyway to keep a native fallback open.
- **D4 — Opt-in default:** Rec: default OFF, opt-in with the privacy framing in §6 (respect the on-device-privacy brand).

## 10. Effort

**Medium — ~4–6 dev-days**, gated on Apple-side setup (account-admin dependency) and the Edge Function proxy substrate. The engineering is modest; the **privacy-label decision + attribution compliance** are the gating concerns.

## Sources
- Apple WeatherKit — developer.apple.com/weatherkit/ · WeatherKit entitlement (`com.apple.developer.weatherkit`) · WeatherKit REST request authentication (JWT) · `WeatherService.attribution`
- App Review Guidelines 5.2.5 (attribution) · App Privacy Details (nutrition labels)
- Supabase Edge Functions (context7 `/supabase/supabase`): Deno.serve + CORS handler, `supabase secrets set`, external-API fetch pattern, caller-JWT verification
- Islamic: Abu Dawud 2540 (duʿā under the rain)

## If un-parked — prerequisites from eng-review (do these first)

These outside-voice findings are real blockers currently dressed as settled. Address before any build:

1. **Rain as a schedule DECORATOR, not inside the engine (#3).** `DuaWindowEngine.buildSchedule()` is pure/deterministic/test-seam'd. A network weather call must NOT go inside it — wrap the assembled schedule in a decorator that injects the transient rain window, so the engine stays synchronous + testable and transient weather never persists into the widget payload.
2. **Resolve REST attribution (#7).** The native `WeatherService.attribution` serves a dynamic logo + `legalPageURL`; the REST API has no equivalent, and Apple guidance is to fetch attribution from the native API even for REST data. This likely FORCES enabling the native WeatherKit capability (architecture change) — confirm before committing to REST-only.
3. **Kill the identity→location trace (#8).** JWT-auth'd rain checks tie `user_id → cell → timestamp` in Edge Function logs = a server-side location history keyed to identity. Make the cell-cache service-role-only, disable per-request user logging for this function, and reconcile the "location never stored" framing — or the privacy story is worse than a third party.
4. **JWT feasibility spike (#5).** Prove ES256 signing with the `.p8` (PKCS#8 → DER via WebCrypto `importKey`), the `{TeamID}.{ServiceID}` `kid` header, and token caching actually work in a Deno Edge Function before trusting the 1.5–2d estimate.
5. **Smaller items:** `fromCache` guard on `getCoarseLocation` so a traveler doesn't get last-city's weather (#10); the `DuaWindowType.rain` enum fan-out across every exhaustive switch (#4); WeatherKit per-Team quota monitoring/alerting (#6); Arabic dua content + RTL-safe layout with the Latin Apple-Weather mark on the same card (#9, per CLAUDE.md).

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | PARKED | 2 issues folded (server cell-cache, rain card-only/widget-strip) + proxy-risk corrected; outside voice surfaced a strategic "don't build now" → user PARKED |
| Outside Voice | `/plan-eng-review` (Claude subagent; codex broken on host) | Independent 2nd opinion | 1 | ISSUES_FOUND | 10 findings; #1/#2 (strategic) drove the park decision; #3/#7/#8 captured as un-park prerequisites |
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | — |

**Completion summary:** Step 0 scope accepted + proxy-risk corrected (Edge Function platform already proven) · Architecture 1 (server-side shared cell cache) · Code Quality 1 (rain card-only, stripped from widget for 5.2.5) · Test diagram: 8 gaps folded · Performance: no new issue (cell-cache covers it) · Outside voice: 10 findings · Decision: **PARKED** — low/rare value for an arid core audience vs a permanent privacy-brand + compliance cost.

**CROSS-MODEL:** review sharpened the *how*; outside voice challenged the *whether* (#1/#2) — user resolved by deep-parking.

**VERDICT:** PARKED — not building now. The plan is a complete, reviewed record; un-park only on a product signal, and address the 5 "If un-parked" prerequisites first. Not ship-scoped.

**UNRESOLVED DECISIONS:**
- Un-park trigger (what product signal justifies building rain) — open, owned by product
- D1–D4 (priority rank, cache TTL, native-capability-vs-REST, opt-in default) — deferred until un-parked
