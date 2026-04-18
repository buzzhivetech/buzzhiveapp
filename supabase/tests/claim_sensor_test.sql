-- Integration test for the claim_sensor RPC.
--
-- Run against a local Supabase stack (or a dedicated test project):
--   psql "$SUPABASE_DB_URL" -f supabase/tests/claim_sensor_test.sql
--
-- All assertions happen inside a single transaction that gets rolled back
-- at the end so repeat runs stay idempotent.

\set ON_ERROR_STOP on

begin;

do $$
declare
  v_user_a uuid := gen_random_uuid();
  v_user_b uuid := gen_random_uuid();
  v_code text := 'TEST-1234';
  v_device_id text := 'TEST_DEVICE_' || substr(gen_random_uuid()::text, 1, 8);
  v_result public.claim_result;
begin
  -- Seed auth users (claim_sensor requires an existing auth.uid()).
  insert into auth.users (id, email, instance_id)
    values (v_user_a, 'a@test.local', '00000000-0000-0000-0000-000000000000'),
           (v_user_b, 'b@test.local', '00000000-0000-0000-0000-000000000000');

  -- Seed a factory sensor with a known claim code.
  insert into public.sensors (firebase_sensor_id, status, claim_code_hash)
    values (v_device_id, 'factory', extensions.crypt(v_code, extensions.gen_salt('bf', 10)));

  -- Impersonate user A.
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_a)::text, true);

  -- 1) Wrong code should fail with wrong_code.
  v_result := public.claim_sensor(v_device_id, 'WRONG');
  assert v_result.ok = false, 'wrong code should not succeed';
  assert v_result.error_code = 'wrong_code', 'expected wrong_code, got ' || coalesce(v_result.error_code, 'null');

  -- 2) Unknown device should fail with unknown_device.
  v_result := public.claim_sensor('NOPE_' || v_device_id, v_code);
  assert v_result.ok = false, 'unknown device should not succeed';
  assert v_result.error_code = 'unknown_device', 'expected unknown_device, got ' || coalesce(v_result.error_code, 'null');

  -- 3) Correct code should succeed and link the sensor.
  v_result := public.claim_sensor(v_device_id, v_code);
  assert v_result.ok = true, 'correct code should succeed; error=' || coalesce(v_result.error_code, 'null');
  assert v_result.sensor_id is not null, 'success should return a sensor_id';

  assert (select status from public.sensors where firebase_sensor_id = v_device_id) = 'claimed',
    'sensor should be marked claimed';
  assert (select claimed_by from public.sensors where firebase_sensor_id = v_device_id) = v_user_a,
    'sensor should be owned by user A';
  assert exists(select 1 from public.user_sensor_links where user_id = v_user_a and sensor_id = v_result.sensor_id),
    'user A should have a link row';

  -- 4) Re-claiming by user A should fail with already_claimed.
  v_result := public.claim_sensor(v_device_id, v_code);
  assert v_result.ok = false, 'already-claimed sensor should not be re-claimed';
  assert v_result.error_code = 'already_claimed', 'expected already_claimed, got ' || coalesce(v_result.error_code, 'null');

  -- 5) Another user attempting to claim should also get already_claimed.
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_b)::text, true);
  v_result := public.claim_sensor(v_device_id, v_code);
  assert v_result.ok = false, 'user B should not claim an already-claimed sensor';
  assert v_result.error_code = 'already_claimed', 'expected already_claimed for user B';

  -- 6) Disabled device should return disabled_device.
  update public.sensors set status = 'disabled'
    where firebase_sensor_id = v_device_id;
  -- Need a fresh factory device to actually hit the disabled path, since the
  -- disabled-vs-claimed check fires before disabled when status=claimed.
  declare
    v_disabled_id text := 'DIS_' || substr(gen_random_uuid()::text, 1, 8);
  begin
    insert into public.sensors (firebase_sensor_id, status, claim_code_hash)
      values (v_disabled_id, 'disabled', extensions.crypt(v_code, extensions.gen_salt('bf', 10)));
    v_result := public.claim_sensor(v_disabled_id, v_code);
    assert v_result.ok = false, 'disabled device should not be claimed';
    assert v_result.error_code = 'disabled_device', 'expected disabled_device, got ' || coalesce(v_result.error_code, 'null');
  end;

  raise notice 'claim_sensor_test: all assertions passed';
end $$;

rollback;
