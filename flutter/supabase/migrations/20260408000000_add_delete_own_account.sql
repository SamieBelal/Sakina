-- RPC function that lets an authenticated user delete their own account.
-- All 15 user tables have ON DELETE CASCADE, so this cascades automatically.
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  DELETE FROM auth.users WHERE id = auth.uid();
$$;

-- Lock down access: only authenticated users may call this.
REVOKE ALL ON FUNCTION public.delete_own_account() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
