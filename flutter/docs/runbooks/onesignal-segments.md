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

> ⚠️ **TURN THIS AUTOMATION OFF. Its deep link is a no-op.**
>
> The guided tour was deleted from the app on 2026-07-28 (One Ship W2, plan
> §F1a) after it was measured costing ~48% of signups. `sakina://settings?action=replay_tour`
> now lands on a Settings row with no overlay to render, so anyone who taps this
> push gets nothing. Turning the automation off beats shipping users into a dead
> end.
>
> Note the ordering: **retire the automation first, then delete its copy.** The
> strings below were the automation's only in-repo source of truth. They lived
> in `lib/services/tour_service.dart`, whose header carried this same warning
> until that file was deleted in the 2026-08-02 cleanup — the copy was
> unreferenced by any Dart code precisely *because* its consumer is external,
> and an "is it imported?" check could not see that. Copy preserved here so the
> warning outlives the file.
>
> Also still open: `TODO.md` lists `win_back_tour_replay` as pending i18n. If
> the automation is retired, drop that item rather than translating copy for a
> push that goes nowhere.

- **Title:** Want me to show you around?
- **Body:** Tap to retake the Sakina tour — 30 seconds.
- **Additional data:** `type=tour_replay`
- **App route:** `/settings?action=replay_tour`
- **Locale:** English only at launch (i18n deferred — see TODO.md).

### Schedule

Daily, 4pm local time of the user's timezone. Sent to the
`tour_skipped_no_checkin_3d` segment.

Owner: PM. Manual setup post-PR-3 deploy.
