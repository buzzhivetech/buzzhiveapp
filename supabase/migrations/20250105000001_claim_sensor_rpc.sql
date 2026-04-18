-- claim_sensor: atomic ownership claim for a factory-provisioned sensor.
--
-- Returns a typed row instead of raising exceptions so the Dart client can
-- match on error_code without parsing error message strings.
--
-- Error codes:
--   rate_limited       - user has exceeded 10 failed attempts in 10 minutes
--   unknown_device     - no sensor row with the given firebase_sensor_id
--   disabled_device    - sensor.status = 'disabled' (recalled / bricked)
--   already_claimed    - sensor.status = 'claimed'
--   wrong_code         - claim code does not match the bcrypt hash on record
--   not_authenticated  - auth.uid() is null (anon key caller)

create or replace function public.claim_sensor(
  p_device_id text,
  p_claim_code text
) returns public.claim_result
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.sensors%rowtype;
  v_failed_recent int;
begin
  if v_uid is null then
    return (false, 'not_authenticated', null)::public.claim_result;
  end if;

  -- Rate limit: count failed attempts by this user in the last 10 minutes.
  select count(*) into v_failed_recent
    from public.claim_attempts
    where user_id = v_uid
      and succeeded = false
      and attempted_at > now() - interval '10 minutes';

  if v_failed_recent >= 10 then
    insert into public.claim_attempts(user_id, device_id, succeeded)
      values (v_uid, p_device_id, false);
    return (false, 'rate_limited', null)::public.claim_result;
  end if;

  -- Lock the row for the duration of the transaction so two concurrent
  -- claim_sensor calls can't both pass the status check before either writes.
  select * into v_row
    from public.sensors
    where firebase_sensor_id = p_device_id
    for update;

  if not found then
    insert into public.claim_attempts(user_id, device_id, succeeded)
      values (v_uid, p_device_id, false);
    return (false, 'unknown_device', null)::public.claim_result;
  end if;

  if v_row.status = 'disabled' then
    insert into public.claim_attempts(user_id, device_id, succeeded)
      values (v_uid, p_device_id, false);
    return (false, 'disabled_device', null)::public.claim_result;
  end if;

  if v_row.status = 'claimed' then
    insert into public.claim_attempts(user_id, device_id, succeeded)
      values (v_uid, p_device_id, false);
    return (false, 'already_claimed', null)::public.claim_result;
  end if;

  -- Timing-safe-ish bcrypt comparison. pgcrypto.crypt re-hashes p_claim_code
  -- with the salt embedded in claim_code_hash; equality of the results means
  -- the code matches.
  if v_row.claim_code_hash is null
     or extensions.crypt(p_claim_code, v_row.claim_code_hash) <> v_row.claim_code_hash then
    insert into public.claim_attempts(user_id, device_id, succeeded)
      values (v_uid, p_device_id, false);
    return (false, 'wrong_code', null)::public.claim_result;
  end if;

  update public.sensors
    set status = 'claimed',
        claimed_by = v_uid,
        claimed_at = now()
    where id = v_row.id;

  insert into public.user_sensor_links(user_id, sensor_id)
    values (v_uid, v_row.id)
    on conflict (user_id, sensor_id) do nothing;

  insert into public.claim_attempts(user_id, device_id, succeeded)
    values (v_uid, p_device_id, true);

  return (true, null, v_row.id)::public.claim_result;
end;
$$;

-- The anon role must be able to call the RPC so JWT-bearing requests reach
-- it; authorization happens inside the function via auth.uid().
grant execute on function public.claim_sensor(text, text) to anon, authenticated;
revoke execute on function public.claim_sensor(text, text) from public;
