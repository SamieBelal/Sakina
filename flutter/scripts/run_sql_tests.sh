#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

for file in $(find supabase/tests -maxdepth 1 -type f -name '*.sql' | sort); do
  echo "::group::SQL test: $file"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"
  echo "::endgroup::"
done
