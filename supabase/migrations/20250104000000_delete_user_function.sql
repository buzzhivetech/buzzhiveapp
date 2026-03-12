-- Server-side function to delete the current user's account.
-- Removes application data, auth-dependent rows, and finally the auth record.
-- Called via: supabase.rpc('delete_user_account')

create or replace function public.delete_user_account()
returns void language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Application data
  delete from public.user_sensor_links where user_id = uid;
  delete from public.profiles where id = uid;

  -- Auth leaf tables first (depend on sessions / mfa_factors)
  delete from auth.mfa_amr_claims
    where session_id in (select id from auth.sessions where user_id = uid);
  delete from auth.refresh_tokens
    where session_id in (select id from auth.sessions where user_id = uid);

  -- Auth mid-level tables
  delete from auth.sessions where user_id = uid;
  delete from auth.mfa_challenges
    where factor_id in (select id from auth.mfa_factors where user_id = uid);
  delete from auth.mfa_factors where user_id = uid;
  delete from auth.identities where user_id = uid;

  -- Finally delete the user
  delete from auth.users where id = uid;
end;
$$;
