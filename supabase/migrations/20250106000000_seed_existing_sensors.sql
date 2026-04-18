-- Seed claim codes for pre-existing sensors so the new onboarding flow has
-- something to claim end-to-end in dev.
--
-- Sensors 5 and 8 already stream to Firebase RTDB. Sensors 10001-10005 are
-- reserved IDs that may or may not exist in public.sensors today; we upsert
-- all of them as status='factory' so the RPC can find them.
--
-- RAISE NOTICE lines surface the plaintext codes during `supabase db push` so
-- the developer can record them. In production, factory provisioning would
-- write codes to a vault at print time and discard the plaintext.

do $$
declare
  v_device_ids text[] := array['5', '8', '10001', '10002', '10003', '10004', '10005'];
  v_device_id text;
  v_code text;
  v_hash text;
  -- Crockford base32: no I, L, O, U. Gives 32^8 ~ 1.1 trillion codes.
  v_alphabet text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  v_rand int;
  i int;
begin
  foreach v_device_id in array v_device_ids loop
    -- Generate an 8-char code. pgcrypto.gen_random_bytes gives us strong
    -- randomness; we map each byte mod 32 onto the alphabet.
    v_code := '';
    for i in 1..8 loop
      v_rand := get_byte(extensions.gen_random_bytes(1), 0);
      v_code := v_code || substr(v_alphabet, (v_rand % 32) + 1, 1);
    end loop;

    v_hash := extensions.crypt(v_code, extensions.gen_salt('bf', 10));

    insert into public.sensors (firebase_sensor_id, status, claim_code_hash)
      values (v_device_id, 'factory', v_hash)
    on conflict (firebase_sensor_id) do update
      set status = case
            -- Don't clobber already-claimed sensors in production reruns.
            when public.sensors.status = 'claimed' then public.sensors.status
            else excluded.status
          end,
          claim_code_hash = case
            when public.sensors.status = 'claimed' then public.sensors.claim_code_hash
            else excluded.claim_code_hash
          end;

    -- Only emit the notice when we actually (re)set the code.
    if (select status from public.sensors where firebase_sensor_id = v_device_id) = 'factory' then
      raise notice 'seed claim code for device_id=% : %', v_device_id, v_code;
    else
      raise notice 'device_id=% already claimed; claim code unchanged', v_device_id;
    end if;
  end loop;
end $$;
