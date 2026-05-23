-- 2026-05-23: Refer-to-Unlock — read-only validator for the in-onboarding
-- and Settings referral code entry surfaces.
--
-- See docs/superpowers/plans/2026-05-23-onboarding-referral-code-entry.md.
--
-- Returns true iff (a) p_code matches the 8-16 char A-HJ-NP-Z2-9 charset
-- after uppercasing, (b) a user_profiles row exists with referral_code =
-- upper(trim(p_code)), AND (c) that user is NOT the caller (auth.uid()
-- self-check — required so the UI can show "you can't redeem your own
-- code" without the client having to know the referrer's id).
--
-- 8-char minimum is intentional: ensure_referral_code (see
-- 20260514000000_referrals.sql) always emits 8-char codes from a 32-char
-- alphabet, so a 4-char input has no legitimate origin. Tightening to
-- {8,16} also closes the 32^4 ≈ 1M enumeration surface that {4,16} would
-- expose to the anon role; 32^8 ≈ 1.1T is intractable.
--
-- Does NOT return the referrer's id, name, or any other field — only a
-- boolean. The actual self-referral / chain-referral / duplicate guards
-- still live in apply_referral (the write path); this is purely a UX
-- affordance so the field can give live feedback before submit.
--
-- Granted to BOTH anon and authenticated: the onboarding field fires
-- BEFORE the user has signed up — auth.uid() is null in that window. The
-- function tolerates that (the `v_caller is null or id <> v_caller`
-- clause). Once they sign up via the Settings redeem path, auth.uid() is
-- populated and the self-check kicks in.
--
-- STABLE + SECURITY DEFINER + pinned search_path matches the project-wide
-- convention from 20260510000000_pin_function_search_path.sql. STABLE is
-- correct because we read but never write.

create or replace function public.validate_referral_code(p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
stable
as $$
declare
  v_code text;
  v_caller uuid := auth.uid();
  v_exists boolean;
begin
  if p_code is null then return false; end if;
  v_code := upper(trim(p_code));
  if v_code !~ '^[A-HJ-NP-Z2-9]{8,16}$' then return false; end if;

  select exists(
    select 1 from public.user_profiles
    where referral_code = v_code
      and (v_caller is null or id <> v_caller)
  ) into v_exists;

  return coalesce(v_exists, false);
end;
$$;

revoke all on function public.validate_referral_code(text) from public;
grant execute on function public.validate_referral_code(text) to anon, authenticated;
