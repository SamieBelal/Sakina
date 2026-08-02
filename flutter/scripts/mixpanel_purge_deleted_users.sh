#!/usr/bin/env bash
#
# Purge Mixpanel event data for deleted Supabase accounts.
#
# Submits the distinct_ids in docs/qa/mixpanel-orphaned-distinct-ids.json to
# Mixpanel's GDPR/CCPA Data Deletion API. This is IRREVERSIBLE — once the
# deletion task completes (can take up to ~30 days), the events are gone.
#
# These distinct_ids were produced by reconciling Mixpanel's `user_id`
# breakdown against Supabase `auth.users`: every id here had analytics in
# Mixpanel but no longer exists in auth.users, i.e. a deleted account.
#
# Prereqs:
#   - jq, curl
#   - A Mixpanel OAuth token for data deletion (Project Settings ->
#     "Privacy & Compliance" / "Data Deletion" -> generate an OAuth token).
#     Requires Owner/Admin on the project.
#   - The project's TOKEN (Project Settings -> Overview -> "Project Token").
#
# Usage:
#   export MIXPANEL_PROJECT_TOKEN=xxxx
#   export MIXPANEL_GDPR_OAUTH_TOKEN=xxxx
#   ./scripts/mixpanel_purge_deleted_users.sh           # dry-run: prints payload
#   ./scripts/mixpanel_purge_deleted_users.sh --execute  # actually submits
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IDS_FILE="$HERE/docs/qa/mixpanel-orphaned-distinct-ids.json"
PROJECT_ID=4013350

: "${MIXPANEL_PROJECT_TOKEN:?Set MIXPANEL_PROJECT_TOKEN}"
: "${MIXPANEL_GDPR_OAUTH_TOKEN:?Set MIXPANEL_GDPR_OAUTH_TOKEN}"

# Build the request body: { "distinct_ids": [...], "compliance_type": "GDPR" }
PAYLOAD="$(jq '{distinct_ids: .distinct_ids, compliance_type: "GDPR"}' "$IDS_FILE")"
COUNT="$(jq '.distinct_ids | length' "$IDS_FILE")"

echo "Project: $PROJECT_ID"
echo "distinct_ids to purge: $COUNT"
echo "Payload:"
echo "$PAYLOAD" | jq .

if [[ "${1:-}" != "--execute" ]]; then
  echo
  echo "DRY RUN. Re-run with --execute to submit the deletion task."
  exit 0
fi

echo
echo "Submitting deletion task to Mixpanel..."
curl --fail --silent --show-error \
  -X POST "https://mixpanel.com/api/app/data-deletions/v3.0/?token=${MIXPANEL_PROJECT_TOKEN}" \
  -H "Authorization: Bearer ${MIXPANEL_GDPR_OAUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" | jq .

echo
echo "Deletion task created. Track its status under Project Settings -> Data Deletion,"
echo "or GET https://mixpanel.com/api/app/data-deletions/v3.0/<task_id>/?token=...".
