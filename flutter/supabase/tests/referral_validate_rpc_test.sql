-- Regression test for:
--   * 20260523000000_referral_validate_rpc.sql
--
-- Verifies validate_referral_code():
--   * returns false for null / empty / whitespace input
--   * returns false for malformed input (length < 8, length > 16,
--     confusable chars I/O/0/1)
--   * returns true for a valid 8-char uppercase foreign code
--   * returns true for a valid 8-char lowercase foreign code (the
--     uppercase normalization works)
--   * returns false when caller owns the code (self-redeem rejection)
--   * returns false when no row matches
--   * returns true for an anon caller (auth.uid() is null) with a valid
--     foreign code — pins the pre-signup onboarding-field code path
--
-- Pattern matches referrals_test.sql / backend_rls_test.sql: one
-- transaction, assertions inside a DO block, rollback at end. Run via:
--   mcp__supabase__execute_sql query=$(cat referral_validate_rpc_test.sql)

begin;

create or replace function pg_temp.expect(cond boolean, name text)
returns void language plpgsql as $$
begin
  perform set_config('test.total',
    (coalesce(current_setting('test.total', true)::int, 0) + 1)::text, true);
  if not cond then
    perform set_config('test.failed',
      coalesce(current_setting('test.failed', true), '') || ' | ' || name, true);
  end if;
end
$$;

create or replace function pg_temp.test_insert_auth_user(
  p_id uuid,
  p_email text
) returns void
language sql
as $$
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  values (
    '00000000-0000-0000-0000-000000000000'::uuid,
    p_id, 'authenticated', 'authenticated', p_email, '',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', split_part(p_email, '@', 1)),
    now(), now()
  );
$$;

-- Two users:
--   owner_id  — owns a known referral_code (the "foreign" code from the
--               perspective of caller_id)
--   caller_id — the authenticated caller in self-check tests; also owns
--               a separate code so we can test the self-redeem path
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005301', 'owner-vrc@test.sakina.local');
select pg_temp.test_insert_auth_user(
  '00000000-0000-0000-0000-000000005302', 'caller-vrc@test.sakina.local');

do $body$
declare
  owner_id  constant uuid := '00000000-0000-0000-0000-000000005301';
  caller_id constant uuid := '00000000-0000-0000-0000-000000005302';
  owner_code  text;
  caller_code text;
  failures text;
  total int := 0;
  failed_count int := 0;
  failed_list text;
begin
  perform set_config('test.total', '0', true);
  perform set_config('test.failed', '', true);

  -- Provision codes via the real RPC so we get the canonical 8-char
  -- A-HJ-NP-Z2-9 shape.
  owner_code  := public.ensure_referral_code(owner_id);
  caller_code := public.ensure_referral_code(caller_id);

  perform pg_temp.expect(
    owner_code is not null and length(owner_code) = 8,
    '0.1 owner_code provisioned (8 chars)');
  perform pg_temp.expect(
    caller_code is not null and length(caller_code) = 8 and caller_code <> owner_code,
    '0.2 caller_code provisioned, distinct from owner_code');

  -- =========================================================================
  -- 1. Null / empty / whitespace input.
  -- =========================================================================
  perform pg_temp.expect(
    public.validate_referral_code(null) = false,
    '1.1 null input returns false');
  perform pg_temp.expect(
    public.validate_referral_code('') = false,
    '1.2 empty string returns false');
  perform pg_temp.expect(
    public.validate_referral_code('   ') = false,
    '1.3 whitespace-only returns false');

  -- =========================================================================
  -- 2. Malformed: too short (< 8 chars).
  -- =========================================================================
  perform pg_temp.expect(
    public.validate_referral_code('AB23') = false,
    '2.1 4-char input returns false');
  perform pg_temp.expect(
    public.validate_referral_code('AB234') = false,
    '2.2 5-char input returns false');
  perform pg_temp.expect(
    public.validate_referral_code('AB2345') = false,
    '2.3 6-char input returns false');
  perform pg_temp.expect(
    public.validate_referral_code('AB23456') = false,
    '2.4 7-char input returns false');

  -- =========================================================================
  -- 3. Malformed: too long (> 16 chars).
  -- =========================================================================
  perform pg_temp.expect(
    public.validate_referral_code('ABCDEFGHJKLMNPQRS') = false,
    '3.1 17-char input returns false');

  -- =========================================================================
  -- 4. Malformed: contains confusables I / O / 0 / 1.
  -- =========================================================================
  perform pg_temp.expect(
    public.validate_referral_code('ABCDEFGI') = false,
    '4.1 contains I returns false');
  perform pg_temp.expect(
    public.validate_referral_code('ABCDEFGO') = false,
    '4.2 contains O returns false');
  perform pg_temp.expect(
    public.validate_referral_code('ABCDEFG0') = false,
    '4.3 contains 0 returns false');
  perform pg_temp.expect(
    public.validate_referral_code('ABCDEFG1') = false,
    '4.4 contains 1 returns false');

  -- =========================================================================
  -- 5. Unknown code (well-formed but no row matches).
  -- =========================================================================
  perform pg_temp.expect(
    public.validate_referral_code('ZZZZZZZZ') = false,
    '5.1 well-formed but no matching row returns false');

  -- =========================================================================
  -- 6. Valid 8-char uppercase foreign code — caller is anonymous (no JWT).
  --    auth.uid() is null here so the self-check short-circuits via
  --    `v_caller is null or id <> v_caller`.
  -- =========================================================================
  perform pg_temp.expect(
    public.validate_referral_code(owner_code) = true,
    '6.1 anon caller + valid uppercase foreign code returns true');

  -- =========================================================================
  -- 7. Lowercase normalization — same foreign code, lowercased.
  -- =========================================================================
  perform pg_temp.expect(
    public.validate_referral_code(lower(owner_code)) = true,
    '7.1 anon caller + valid lowercase foreign code returns true (normalized)');

  -- Whitespace trim normalization.
  perform pg_temp.expect(
    public.validate_referral_code('  ' || owner_code || '  ') = true,
    '7.2 anon caller + valid code with surrounding whitespace returns true');

  -- =========================================================================
  -- 8. Self-redeem rejection: switch to authenticated as caller_id, then
  --    try to validate caller_id's own code.
  -- =========================================================================
  set local role authenticated;
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', caller_id::text, 'role', 'authenticated')::text, true);

  perform pg_temp.expect(
    public.validate_referral_code(caller_code) = false,
    '8.1 authenticated caller validating own code returns false (self-redeem rejection)');

  -- Same authenticated caller validating someone ELSE's code should still
  -- return true.
  perform pg_temp.expect(
    public.validate_referral_code(owner_code) = true,
    '8.2 authenticated caller validating foreign code returns true');

  -- =========================================================================
  -- 9. Pre-signup anon path pin (T from plan): unset JWT and role, prove
  --    the function returns true for a valid foreign code with no caller.
  -- =========================================================================
  perform set_config('request.jwt.claims', '', true);
  reset role;
  -- Now back to postgres role; auth.uid() returns null when no JWT claim
  -- is set. Same shape as the anon role from PostgREST.
  perform pg_temp.expect(
    public.validate_referral_code(owner_code) = true,
    '9.1 caller with no JWT (auth.uid()=null) + valid foreign code returns true');

  total := coalesce(current_setting('test.total', true)::int, 0);
  failures := coalesce(current_setting('test.failed', true), '');
  if failures = '' then
    raise notice 'PASS: % checks', total;
  else
    failed_list := failures;
    failed_count := array_length(string_to_array(failed_list, ' | '), 1) - 1;
    raise exception 'FAIL: % of % checks failed:%', failed_count, total, failed_list;
  end if;
end
$body$;

rollback;
