# Duʿā Times — Rain Window (Phase 2) — Implementation Plan

**Status:** Draft (pending `/plan-eng-review`)
**Date:** 2026-07-16
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
**Phase 3 — degrade + tests**: mock WeatherKit responses; lat/lon spoofing; assert rain injection/priority; assert failure → `{isRaining:false}` never breaks the card; verify attribution renders whenever the rain window shows. ~1d.

## 8. Risks / blockers

1. **Privacy-label regression is the real cost** — breaks the on-device invariant. Escalate as a deliberate product/privacy call, not an engineering detail.
2. **Attribution enforcement (5.2.5)** — forgetting the Apple Weather mark + legal link is a known rejection; must be designed into the UI.
3. **Depends on Edge Function proxy infra** — `TODO.md` notes the OpenAI proxy isn't shipped yet. The rain window needs the same proxy substrate (secret handling + a deployed function); either land that infra first or ship this function standalone. Secondary: rain is rare, so caching + the shared 500k/team quota guard are essential to avoid burning calls on repeated foregrounds.

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
