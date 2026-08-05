# OneSignal segments + templates

This runbook documents non-code OneSignal configuration: segments and push
templates managed in the OneSignal dashboard. The dashboard is the source of
truth — this file is a backup spec for rebuild.

## Win-back push: tour skippers

### Segment: `tour_skipped_no_checkin_3d`

Filters (AND):
1. User property `tour_home_skipped_at` is set AND `< 3 days ago`
2. User property `last_checkin_at` (or equivalent — confirm field name in app
   schema) is `> 3 days ago`

Before activating the segment, verify the dashboard ingestion path exposes the
Mixpanel people property `tour_home_skipped_at` to OneSignal.

### Template: `win_back_tour_replay`

> ⚠️ **RETIRE THIS WITH THE 1.3.0 RELEASE — not before.**
>
> It works today and breaks the moment 1.3.0 ships.
>
> | | |
> |---|---|
> | **On 1.2.0 — what everyone is running** | The tour exists, the Settings Replay row renders it, `sakina://settings?action=replay_tour` **works**. This push does its job. |
> | **On 1.3.0 — unshipped** | Wave F deleted the tour (`b05c174`, 2026-07-28), so the deep link lands on a Settings row with no overlay to render. Every tap gets nothing. |
>
> So switching it off now would break a working re-engagement push for the whole
> install base, and leaving it on past the 1.3.0 rollout ships users into a dead
> end. Turn it off **as part of the 1.3.0 cutover** — see `TODO.md` bucket 4.
>
> An earlier version of this warning said "turn it off, the deep link is a
> no-op," full stop. That was read off a code comment on master and master is
> 1.3.0. Same trap as `guided_tour_enabled`: **a comment describes the branch it
> lives on, not the binary your users are running.**
>
> Note the ordering when you do retire it: **automation first, then its copy.**
> The strings below were its only in-repo source of truth. They lived in
> `lib/services/tour_service.dart`, deleted in the 2026-08-02 cleanup because no
> Dart code imported them — which was true precisely *because* the consumer is
> OneSignal, not Dart. Copy preserved here so it outlives the file.
>
> Also open: `TODO.md` lists `win_back_tour_replay` as pending i18n. When it is
> retired, drop that item rather than translating copy for a push going nowhere.
>
> **Unverified:** whether this automation was ever actually created. The Schedule
> section below says "Owner: PM. Manual setup post-PR-3 deploy" — a manual step
> with no confirmation recorded anywhere in this repo. Check the OneSignal
> dashboard before planning either the retirement or its i18n; there may be
> nothing there.

- **Title:** Want me to show you around?
- **Body:** Tap to retake the Sakina tour — 30 seconds.
- **Additional data:** `type=tour_replay`
- **App route:** `/settings?action=replay_tour`
- **Locale:** English only at launch (i18n deferred — see TODO.md).

### Schedule

Daily, 4pm local time of the user's timezone. Sent to the
`tour_skipped_no_checkin_3d` segment.

Owner: PM. Manual setup post-PR-3 deploy.
