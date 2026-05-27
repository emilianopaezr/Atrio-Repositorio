-- =============================================
-- 030_mp_marketplace.sql
-- Mercado Pago Marketplace (split payment) support.
-- Each host connects their own MP account via OAuth; the resulting
-- tokens live here. The Edge Function reads `mp_user_id` to set the
-- collector when creating a payment preference, and the
-- `marketplace_fee` parameter equals the booking's
-- `servicio_atrio_amount`.
--
-- Money flow once MP marketplace is enabled:
--   guest pays precio_total
--   ─→ MP routes precio_base + cleaning_fee → host.mp_user_id
--   ─→ MP routes servicio_atrio_amount      → Atrio (the marketplace)
--
-- Idempotente.
-- =============================================

-- 1. host_payment_accounts table ---------------------------------
CREATE TABLE IF NOT EXISTS host_payment_accounts (
  host_id           UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  provider          TEXT NOT NULL DEFAULT 'mercadopago',
  -- MP-specific OAuth payload. Kept verbatim so the refresh logic can
  -- introspect scope/live_mode/etc. without re-deserializing every time.
  mp_user_id        TEXT NOT NULL,
  mp_access_token   TEXT NOT NULL,
  mp_refresh_token  TEXT,
  mp_public_key     TEXT,
  mp_scope          TEXT,
  mp_live_mode      BOOLEAN DEFAULT false,
  expires_at        TIMESTAMPTZ,
  connected_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_refreshed_at TIMESTAMPTZ,
  -- Soft-disconnect: when the host revokes consent on MP side, we
  -- keep the row but flip this to false. Re-connect overwrites the
  -- whole row.
  is_active         BOOLEAN NOT NULL DEFAULT true,
  raw_payload       JSONB
);

CREATE INDEX IF NOT EXISTS idx_host_payment_accounts_active
  ON host_payment_accounts(host_id) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_host_payment_accounts_mp_user
  ON host_payment_accounts(mp_user_id) WHERE is_active = true;

ALTER TABLE host_payment_accounts ENABLE ROW LEVEL SECURITY;

-- 2. RLS policies -------------------------------------------------
-- The host can read their own row. NO direct writes from the client —
-- the OAuth callback (service_role) is the only writer.
DROP POLICY IF EXISTS "host_payment_accounts_owner_read" ON host_payment_accounts;
CREATE POLICY "host_payment_accounts_owner_read"
  ON host_payment_accounts FOR SELECT
  USING (auth.uid() = host_id);

DROP POLICY IF EXISTS "host_payment_accounts_no_client_writes" ON host_payment_accounts;
CREATE POLICY "host_payment_accounts_no_client_writes"
  ON host_payment_accounts FOR INSERT
  WITH CHECK (false);

DROP POLICY IF EXISTS "host_payment_accounts_no_client_updates" ON host_payment_accounts;
CREATE POLICY "host_payment_accounts_no_client_updates"
  ON host_payment_accounts FOR UPDATE
  USING (false);

DROP POLICY IF EXISTS "host_payment_accounts_no_client_deletes" ON host_payment_accounts;
CREATE POLICY "host_payment_accounts_no_client_deletes"
  ON host_payment_accounts FOR DELETE
  USING (false);

-- 3. Public-safe view of the host's MP status --------------------
-- Avoids leaking the access token even though RLS would block it —
-- defence in depth. The view exposes ONLY what the UI needs to render
-- the "Conectado ✓" badge.
CREATE OR REPLACE VIEW host_payment_status AS
SELECT
  host_id,
  provider,
  mp_user_id,
  mp_live_mode,
  is_active,
  connected_at,
  last_refreshed_at,
  CASE
    WHEN expires_at IS NULL THEN false
    WHEN expires_at < NOW() THEN true
    ELSE false
  END AS is_expired
FROM host_payment_accounts;

GRANT SELECT ON host_payment_status TO authenticated;

-- 4. Helper RPC: my_payment_status() -----------------------------
-- Owner-only read of the redacted status. The view above already
-- redacts but this RPC enforces auth.uid() = host_id.
CREATE OR REPLACE FUNCTION my_payment_status()
RETURNS host_payment_status
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM host_payment_status WHERE host_id = auth.uid();
$$;

GRANT EXECUTE ON FUNCTION my_payment_status() TO authenticated;

-- 5. host_has_payment_account(host_id) ---------------------------
-- Cheap boolean used by booking flow + listing publish to gate
-- payments when the host isn't connected.
CREATE OR REPLACE FUNCTION host_has_payment_account(p_host_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM host_payment_accounts
    WHERE host_id = p_host_id
      AND is_active = true
      AND (expires_at IS NULL OR expires_at > NOW())
  );
$$;

GRANT EXECUTE ON FUNCTION host_has_payment_account(UUID)
  TO authenticated, anon;

-- 6. mp_split_data(booking_id) — used by the Edge Function -------
-- Returns the JSON the preference endpoint needs:
--   { collector_id, marketplace_fee, host_total, can_split }
-- `can_split = false` when the host hasn't connected MP yet — the
-- Edge Function then falls back to collect-and-payout mode.
CREATE OR REPLACE FUNCTION mp_split_data(p_booking_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_host_id       UUID;
  v_precio_base   INTEGER;
  v_atrio_amount  INTEGER;
  v_cleaning      INTEGER;
  v_account       host_payment_accounts%ROWTYPE;
  v_host_total    INTEGER;
BEGIN
  SELECT host_id, precio_base, servicio_atrio_amount,
         COALESCE(cleaning_fee, 0)::int
    INTO v_host_id, v_precio_base, v_atrio_amount, v_cleaning
    FROM bookings WHERE id = p_booking_id;

  IF v_host_id IS NULL THEN
    RETURN jsonb_build_object('can_split', false, 'reason', 'booking_not_found');
  END IF;

  SELECT * INTO v_account
    FROM host_payment_accounts
    WHERE host_id = v_host_id AND is_active = true;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'can_split', false,
      'reason', 'host_not_connected',
      'host_id', v_host_id,
      'host_total', COALESCE(v_precio_base, 0) + v_cleaning,
      'marketplace_fee', COALESCE(v_atrio_amount, 0)
    );
  END IF;

  v_host_total := COALESCE(v_precio_base, 0) + v_cleaning;

  RETURN jsonb_build_object(
    'can_split',       true,
    'host_id',         v_host_id,
    'collector_id',    v_account.mp_user_id,
    'marketplace_fee', COALESCE(v_atrio_amount, 0),
    'host_total',      v_host_total,
    'host_mp_live_mode', v_account.mp_live_mode
  );
END;
$$;

GRANT EXECUTE ON FUNCTION mp_split_data(UUID) TO authenticated;

-- 7. Verification ------------------------------------------------
SELECT
  (SELECT EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'host_payment_accounts')) AS table_ok,
  (SELECT EXISTS(SELECT 1 FROM pg_views  WHERE viewname  = 'host_payment_status'))   AS view_ok,
  (SELECT EXISTS(SELECT 1 FROM pg_proc   WHERE proname   = 'host_has_payment_account')) AS rpc_has_ok,
  (SELECT EXISTS(SELECT 1 FROM pg_proc   WHERE proname   = 'mp_split_data'))         AS rpc_split_ok,
  (SELECT EXISTS(SELECT 1 FROM pg_proc   WHERE proname   = 'my_payment_status'))     AS rpc_status_ok;
