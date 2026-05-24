-- 2026-04-16 (filename-sorted to run before the first cron-using migration
-- at 20260416090000): stub the `cron` schema for local-dev environments
-- that don't preload pg_cron.
--
-- Why this exists:
--   Production Supabase has `pg_cron` in shared_preload_libraries, so
--   `CREATE EXTENSION pg_cron;` creates the `cron` schema with the real
--   `cron.job` table + `cron.schedule()` / `cron.unschedule()` functions.
--   Subsequent migrations (20260416090000, 20260512000000,
--   20260523000001) call those functions to set up scheduled jobs.
--
--   The local Supabase stack spun up by `supabase start` for CI does NOT
--   preload pg_cron by default (the extension requires a Postgres restart
--   with shared_preload_libraries set, which the local stack doesn't do).
--   So the cron migrations fail with `relation "cron.job" does not exist`.
--
-- What this does:
--   If pg_cron is absent AND the cron schema doesn't exist, create a
--   no-op stub: an empty cron.job table + stub schedule/unschedule
--   functions that do nothing and return success. The downstream
--   migrations then "schedule" jobs that are silently ignored — fine for
--   running the SQL test suite, which doesn't depend on scheduled
--   execution.
--
-- What this does NOT do:
--   - In production (pg_cron loaded → cron schema exists from the
--     extension): the entire DO block is a no-op. The real cron.job
--     and real cron.schedule/unschedule are untouched.
--   - In production where this migration applies first-time AFTER
--     pg_cron has been installed: the schema-exists check short-circuits,
--     no stubs are created.
--   - In any environment where pg_cron is later installed on top of the
--     stub: behaviour is undefined. Not a concern because local-dev
--     stacks are ephemeral per CI run.

do $$
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron')
     and not exists (
       select 1 from information_schema.schemata where schema_name = 'cron'
     ) then
    create schema cron;
    create table cron.job (
      jobid    bigserial primary key,
      jobname  text unique,
      schedule text,
      command  text
    );
    create or replace function cron.schedule(jobname text, schedule text, command text)
    returns bigint
    language sql
    as $f$
      insert into cron.job (jobname, schedule, command)
        values ($1, $2, $3)
        on conflict (jobname) do update set schedule=excluded.schedule, command=excluded.command
        returning jobid;
    $f$;
    create or replace function cron.unschedule(jobname text)
    returns boolean
    language sql
    as $f$
      delete from cron.job where jobname = $1 returning true;
    $f$;
  end if;
end$$;
