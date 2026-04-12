-- Reduce the starting token balance for new users from 100 to 50 to better
-- align with the redesigned daily reward economy. Existing users keep their
-- current balance — only the column default for newly inserted rows changes.
alter table public.user_tokens
  alter column balance set default 50;
