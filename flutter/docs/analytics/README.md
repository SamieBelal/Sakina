# Onboarding analytics — funnel definitions

This directory holds version-controlled Mixpanel funnel definitions. The JSON
files in here are the source of truth: if Mixpanel's UI deletes or mutates a
funnel, rebuild from the JSON.

## Rebuilding from JSON

1. Open Mixpanel → Funnels → Create new funnel
2. Use the steps listed in the corresponding JSON file
3. Save with the same name as in the JSON `name` field

## Files

- `onboarding_funnel.json` — End-to-end onboarding-to-paywall conversion funnel.
  Updated 2026-05-25 (post onboarding-trim refactor).
