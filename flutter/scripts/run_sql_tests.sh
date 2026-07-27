#!/usr/bin/env bash
set -euo pipefail

# Run every pgTAP suite under supabase/tests/ against $DATABASE_URL and FAIL
# on any failed assertion, SQL error, or truncated plan.
#
# WHY THE PARSING IS SO PICKY
# ---------------------------
# pgTAP assertions are ordinary result rows, not SQL errors. A `not ok 7 - ...`
# row leaves psql's exit status at 0, so the old version of this script (plain
# `psql -f`, exit status only) reported a fully green run for a suite whose
# assertions had failed. Three separate rules exist here for that reason:
#
#   1. TAP lines are matched with `^[[:space:]]*not ok` / `^[[:space:]]*ok N`.
#      psql's tuples-only output (-t) is ALIGNED, i.e. every row is indented by
#      a leading space. A `^ok` / `^not ok` matcher silently matches NOTHING and
#      yields a false all-green — that exact mistake has been made twice on this
#      project. Do not "simplify" these regexes.
#   2. Any `ERROR:` / `FATAL:` psql diagnostic fails the file, even if the
#      assertions that did run all passed.
#   3. The `1..N` plan count is compared against the number of TAP result rows.
#      A suite that dies halfway through (e.g. `undefined_column` from a
#      migration referencing a column no migration creates) emits its plan, a
#      handful of `ok`s, and then stops — which looks green if you only count
#      `not ok`.
#
# TWO TEST STYLES LIVE IN supabase/tests/
# ---------------------------------------
#   * pgTAP suites: `select plan(N); ... select * from finish();`. Failures are
#     result ROWS, so rules 1-3 above are what gate them.
#   * raise-on-failure suites: a local `pg_temp.expect(cond, name)` helper that
#     `raise exception`s (activate_trial_test.sql, backend_rls_test.sql, the
#     ai_bypass_* and freemium_guard_* families, …). These emit no TAP at all;
#     psql's exit status is the whole signal.
# The style is detected from the file source (`select plan(`/`no_plan(`), so a
# pgTAP suite that emits NO TAP rows is a hard failure rather than being quietly
# reclassified as a passing raise-on-failure suite.
#
# CLEAN vs CONTAMINATED DATABASES
# -------------------------------
# This script tests whatever database $DATABASE_URL points at. A developer's
# long-lived local Postgres accumulates schema from other branches/worktrees,
# so a migration referencing a column that no migration on THIS branch creates
# can pass locally and explode in production. Use
# `scripts/run_sql_tests_clean.sh` (throwaway container, migrations applied from
# scratch) for the authoritative answer; CI's sql-tests job is clean by
# construction because it boots a fresh `supabase start` stack.
#
# PRE-EXISTING / UNTRACKED SUITES
# -------------------------------
# Some files in supabase/tests/ are UNTRACKED working-copy files that never
# reach CI (as of 2026-07-26: backend_rls_test.sql,
# freemium_gating_lockdown_test.sql, sync_all_user_data_returns_verses_test.sql).
# They are still executed here — an untested file is worse than a noisy one —
# but any file listed in $SQL_TESTS_KNOWN_FAILING (space-separated basenames)
# is reported under "PRE-EXISTING FAILURES" and does not, on its own, fail the
# run. Everything else is strict.
#
# Usage:
#   DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres \
#     ./scripts/run_sql_tests.sh [test_file ...]

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

KNOWN_FAILING="${SQL_TESTS_KNOWN_FAILING:-}"

is_known_failing() {
  local base="$1" known
  for known in $KNOWN_FAILING; do
    [ "$base" = "$known" ] && return 0
  done
  return 1
}

# pgTAP ships with the Supabase Postgres image but isn't enabled by default.
# `if not exists` keeps the call idempotent.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -c 'create extension if not exists pgtap;'

if [ "$#" -gt 0 ]; then
  FILES=("$@")
else
  # LC_ALL=C pins lexicographic order so it can't drift under other locales.
  IFS=$'\n' read -r -d '' -a FILES < <(
    find supabase/tests -maxdepth 1 -type f -name '*.sql' | LC_ALL=C sort && printf '\0'
  )
fi

FAILED_FILES=()
KNOWN_FAILED_FILES=()
TOTAL_OK=0
TOTAL_NOT_OK=0

for file in "${FILES[@]}"; do
  base="$(basename "$file")"
  echo "::group::SQL test: $file"

  out="$(mktemp)"
  status=0
  # -t: tuples-only, so TAP rows aren't buried under column headers. Output is
  # still ALIGNED (leading space per row) — see regexes below.
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -t -f "$file" >"$out" 2>&1 || status=$?
  cat "$out"

  planned="$(grep -oE '^[[:space:]]*1\.\.[0-9]+' "$out" | head -1 | grep -oE '[0-9]+$' || true)"
  ok_count="$(grep -cE '^[[:space:]]*ok [0-9]+' "$out" || true)"
  not_ok_count="$(grep -cE '^[[:space:]]*not ok [0-9]+' "$out" || true)"
  # Anchored so a diag() line that merely mentions the word can't trip it:
  # psql prints its own diagnostics as `psql:file.sql:12: ERROR:  ...`, and
  # tuples-only rows are indented, so neither anchor can match test output.
  err_count="$(grep -cE '^(psql:[^ ]* )?(ERROR|FATAL|PANIC):' "$out" || true)"

  TOTAL_OK=$((TOTAL_OK + ok_count))
  TOTAL_NOT_OK=$((TOTAL_NOT_OK + not_ok_count))

  reasons=()
  [ "$status" -ne 0 ] && reasons+=("psql exited $status")
  [ "$not_ok_count" -gt 0 ] && reasons+=("$not_ok_count failed assertion(s)")
  [ "$err_count" -gt 0 ] && reasons+=("$err_count SQL error(s)")

  # Source-based, not output-based: if the file declares a pgTAP plan then TAP
  # rows MUST show up. Inferring the style from the output instead would let a
  # pgTAP suite that emitted nothing masquerade as a green raise-on-failure one.
  if grep -qE 'select[[:space:]]+(\*[[:space:]]+from[[:space:]]+)?(plan\(|no_plan\()' "$file"; then
    style="pgtap"
    if [ -z "$planned" ]; then
      reasons+=("declares a pgTAP plan but emitted no 1..N line — suite never started or TAP parsing broke")
    else
      ran=$((ok_count + not_ok_count))
      if [ "$ran" -ne "$planned" ]; then
        reasons+=("plan mismatch: planned $planned, ran $ran (suite died early)")
      fi
    fi
    detail="$ok_count/${planned:-?}"
  else
    # raise-on-failure style (pg_temp.expect / raise exception): exit status and
    # the ERROR: scan above are the only signals available.
    style="raise"
    detail="exit 0"
  fi

  rm -f "$out"
  echo "::endgroup::"

  if [ "${#reasons[@]}" -eq 0 ]; then
    echo "PASS  $base  [$style] ($detail)"
  else
    joined="$(IFS='; '; echo "${reasons[*]}")"
    if is_known_failing "$base"; then
      echo "KNOWN-FAIL  $base  — $joined"
      KNOWN_FAILED_FILES+=("$base — $joined")
    else
      echo "FAIL  $base  — $joined"
      FAILED_FILES+=("$base — $joined")
    fi
  fi
done

echo
echo "==================== pgTAP summary ===================="
echo "files: ${#FILES[@]}   assertions: ok=$TOTAL_OK not_ok=$TOTAL_NOT_OK"

if [ "${#KNOWN_FAILED_FILES[@]}" -gt 0 ]; then
  echo
  echo "PRE-EXISTING FAILURES (declared in SQL_TESTS_KNOWN_FAILING, not gating):"
  printf '  - %s\n' "${KNOWN_FAILED_FILES[@]}"
fi

if [ "${#FAILED_FILES[@]}" -gt 0 ]; then
  echo
  echo "FAILURES:"
  printf '  - %s\n' "${FAILED_FILES[@]}"
  echo "======================================================="
  exit 1
fi

echo "all suites green"
echo "======================================================="
