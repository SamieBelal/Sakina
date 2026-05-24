#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# pgTAP ships with the Supabase Postgres image but isn't enabled by
# default. Several tests call plan()/ok()/is() so create it once before
# iterating. `if not exists` keeps the call idempotent.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c 'create extension if not exists pgtap;'

for file in $(find supabase/tests -maxdepth 1 -type f -name '*.sql' | sort); do
  echo "::group::SQL test: $file"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"
  echo "::endgroup::"
done
