#!/usr/bin/env bash
set -euo pipefail

# Run every supabase/tests/*.sql suite against a CLEAN database built from
# scratch out of supabase/migrations/ and nothing else.
#
# WHY THIS EXISTS
# ---------------
# The shared local Postgres (127.0.0.1:54322) is long-lived and CONTAMINATED:
# other branches and worktrees apply their migrations to it out-of-band, so its
# schema is the union of everything anyone has ever run — not the schema this
# branch produces. On 2026-07-26 a Critical bug reached feat/lantern-cosmetics
# exactly that way: code referenced `user_profiles` columns and a
# `handle_new_user` trigger that only PR #62 creates, and a 26-assertion pgTAP
# suite passed locally while on a clean database every `sync_all_user_data()`
# call raised `undefined_column`.
#
# This script is the guard. It reproduces what CI's `sql-tests` job does — and
# what production will do — on your machine, before you push.
#
# WHY AN ISOLATED `supabase start` STACK
# --------------------------------------
#   * `supabase db reset` is not an option: it would wipe the SHARED local stack
#     that other people and agents are actively using.
#   * A bare `docker run supabase/postgres` container is tempting (one container,
#     ~1s to ready) and it does ship the roles + an `auth` schema — but NOT
#     GoTrue's `auth.users` COLUMNS. `auth.users` exists there as a stub without
#     `email_confirmed_at`, `raw_app_meta_data`, … and ~40 of the 47 suites seed
#     `auth.users` directly, so they all die on `column ... does not exist`.
#     Tried, rejected; don't re-derive it.
#   * So: a second `supabase start` under its own project_id ("sakina-cleandb")
#     with every port remapped and every optional service disabled. Fresh Docker
#     volumes ⇒ genuinely clean; the CLI applies supabase/migrations/ in order
#     and boots GoTrue so `auth.users` is real. ~25s cold. Runs side by side with
#     the shared stack and never touches it.
#
# The generated config.toml lives in a temp dir and symlinks the real
# supabase/migrations/, so it can never drift from the repo.
#
# Usage:
#   ./scripts/run_sql_tests_clean.sh                 # migrations + all suites
#   ./scripts/run_sql_tests_clean.sh supabase/tests/cosmetic_iap_grant_test.sql
#   KEEP_STACK=1 ./scripts/run_sql_tests_clean.sh    # leave the clean DB up
#
# Env knobs:
#   CLEAN_DB_PORT     host port for the clean Postgres      (default 55432)
#   CLEAN_API_PORT    host port for its kong/api            (default 55433)
#   KEEP_STACK=1      don't tear the stack down on exit
#   SQL_TESTS_KNOWN_FAILING  override the pre-existing-failure list below

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="sakina-cleandb"
DB_PORT="${CLEAN_DB_PORT:-55432}"
API_PORT="${CLEAN_API_PORT:-55433}"
SHADOW_PORT="${CLEAN_SHADOW_PORT:-55430}"
DB_URL="postgresql://postgres:postgres@127.0.0.1:${DB_PORT}/postgres"

# EMPTY BY DEFAULT, AND IT SHOULD STAY THAT WAY — this now matches the CI
# workflow exactly (`SQL_TESTS_KNOWN_FAILING: ''`), so a green run here means a
# green run there. That is the entire point of this script.
#
# It used to default to three tolerated failures, all recorded 2026-07-26. All
# three are gone as of 2026-08-02, verified by a clean run at 51 files /
# 348 assertions / 0 failures:
#
#   backend_rls_test.sql              Was never a pgTAP suite — an MCP-run audit
#                                     against a POPULATED database that this
#                                     comment already noted CI had never run,
#                                     because it was untracked. Moved out of the
#                                     glob to supabase/checks/backend_rls_audit.sql;
#                                     see the README there.
#   streak_freeze_premium_cap_test.sql Passes. Fixed sometime after 2026-07-26.
#   push_on_referral_confirm_test.sql  Passes. Same.
#
# The lesson worth keeping: a default allowlist rots silently in the permissive
# direction. Two of these three had been fixed for weeks and the tolerance stayed,
# so this script would have swallowed a genuine regression in either file. If you
# must add an entry, date it and delete it as soon as it passes.
export SQL_TESTS_KNOWN_FAILING="${SQL_TESTS_KNOWN_FAILING-}"

WORKDIR="$(mktemp -d -t sakina-cleandb)"

cleanup() {
  if [ "${KEEP_STACK:-0}" = "1" ]; then
    echo
    echo "KEEP_STACK=1 — clean DB left running at $DB_URL"
    echo "  tear down with: supabase stop --no-backup --project-id $PROJECT_ID"
  else
    supabase stop --no-backup --project-id "$PROJECT_ID" >/dev/null 2>&1 || true
    rm -rf "$WORKDIR"
  fi
}
trap cleanup EXIT

mkdir -p "$WORKDIR/supabase"
# Symlink rather than copy: the clean stack must apply the migrations that are
# on disk right now, with no chance of a stale snapshot.
ln -s "$ROOT/supabase/migrations" "$WORKDIR/supabase/migrations"

# Everything optional is off. Kong/[api] cannot be disabled outright (the CLI
# still binds its port), so it gets remapped instead. [auth] must stay ON — its
# GoTrue migrations are what create the real auth.users columns the suites seed.
cat > "$WORKDIR/supabase/config.toml" <<EOF
project_id = "$PROJECT_ID"

[api]
enabled = true
port = $API_PORT
schemas = ["public"]

[db]
port = $DB_PORT
shadow_port = $SHADOW_PORT
major_version = 15

[db.pooler]
enabled = false

[studio]
enabled = false

[inbucket]
enabled = false

[storage]
enabled = false

[auth]
enabled = true
site_url = "http://127.0.0.1:3000"

[realtime]
enabled = false

[analytics]
enabled = false

[edge_runtime]
enabled = false
EOF

echo "==> booting clean stack '$PROJECT_ID' (db :$DB_PORT) and applying supabase/migrations/"
supabase stop --no-backup --project-id "$PROJECT_ID" >/dev/null 2>&1 || true
if ! supabase start --workdir "$WORKDIR" >"$WORKDIR/start.log" 2>&1; then
  echo "clean stack failed to start:" >&2
  tail -40 "$WORKDIR/start.log" >&2
  exit 1
fi
echo "    $(grep -c 'Applying migration' "$WORKDIR/start.log" || echo 0) migrations applied"

# A migration that fails is fatal above, but assert the newest one really landed
# — the same guard CI's "Verify migrations applied" step performs, so a silent
# partial apply can't send the suites against half a schema.
NEWEST="$(find supabase/migrations -maxdepth 1 -name '*.sql' -exec basename {} .sql \; | LC_ALL=C sort | tail -1)"
if [ -n "$NEWEST" ]; then
  APPLIED="$(psql "$DB_URL" -tAc \
    "select 1 from supabase_migrations.schema_migrations
      where name = '$NEWEST' or version = '$(echo "$NEWEST" | sed 's/_.*//')' limit 1;" 2>/dev/null || true)"
  if [ "$APPLIED" != "1" ]; then
    echo "newest migration '$NEWEST' is not in schema_migrations — refusing to run against a partial schema" >&2
    psql "$DB_URL" -c "select name, version from supabase_migrations.schema_migrations order by version desc limit 5;" >&2 || true
    exit 1
  fi
fi

# Same file the CI sql-tests job runs, so the two environments can't drift. See
# its header for why local/CI needs it and what it deliberately does NOT restore.
echo "==> restoring standard role table grants"
psql "$DB_URL" -v ON_ERROR_STOP=1 -q -f scripts/restore_local_role_grants.sql

echo "==> running suites against the CLEAN database"
echo
DATABASE_URL="$DB_URL" ./scripts/run_sql_tests.sh "$@"
