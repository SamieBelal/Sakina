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

### Template: `win_back_tour_replay`

- **Title:** Want me to show you around?
- **Body:** Tap to retake the Sakina tour — 30 seconds.
- **Deep link:** `sakina://settings?action=replay_tour`
- **Locale:** English only at launch (i18n deferred — see TODO.md).

### Schedule

Daily, 4pm local time of the user's timezone. Sent to the
`tour_skipped_no_checkin_3d` segment.

Owner: PM. Manual setup post-PR-3 deploy.
