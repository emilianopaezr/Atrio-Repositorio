-- =============================================
-- 029_servicio_atrio_pricing.sql
-- Replaces the legacy "tarifa promo / comisión host" model with a
-- single transparent "Servicio Atrio" fee paid BY the customer, ON
-- TOP of base price. Host always receives 100% of base price.
--
-- Rules (encoded in calculate_atrio_pricing):
--   verified host, < 5 paid+confirmed+non-refunded reservas → 5%
--   any other case                                          → 9%
--   minimum servicio_atrio                                  → $1.490
--
-- Idempotent: safe to re-run.
-- =============================================

-- 0. Config keys (so the constants can be tweaked without redeploying)
INSERT INTO pricing_config (key, value, description, active) VALUES
  ('PLATFORM_FEE_PERCENTAGE',       '0.09', 'Servicio Atrio normal rate',            true),
  ('INITIAL_HOST_FEE_PERCENTAGE',   '0.05', 'Servicio Atrio inicial rate (first 5)', true),
  ('SERVICE_FEE_MIN_CLP',           '1490', 'Mínimo Servicio Atrio en CLP',          true),
  ('INITIAL_HOST_RESERVATION_LIMIT','5',    'Reservas con beneficio inicial',        true)
ON CONFLICT (key) DO UPDATE
  SET value = EXCLUDED.value,
      description = EXCLUDED.description,
      active = EXCLUDED.active;

-- 1. New columns on bookings (nullable for backward compat) ------
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS precio_base                            INTEGER,
  ADD COLUMN IF NOT EXISTS porcentaje_atrio                       NUMERIC(4,3),
  ADD COLUMN IF NOT EXISTS servicio_atrio_calculado               INTEGER,
  ADD COLUMN IF NOT EXISTS servicio_atrio_amount                  INTEGER,
  ADD COLUMN IF NOT EXISTS servicio_atrio_minimo_aplicado         BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS precio_total                           INTEGER,
  ADD COLUMN IF NOT EXISTS host_expected_amount                   INTEGER,
  ADD COLUMN IF NOT EXISTS host_paid_reservation_count_at_booking INTEGER,
  ADD COLUMN IF NOT EXISTS initial_benefit_applied                BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS host_payout_status                     TEXT
    CHECK (host_payout_status IS NULL OR host_payout_status IN
      ('host_funds_pending','host_funds_available','host_payout_paid','host_payout_failed'));

COMMENT ON COLUMN bookings.precio_base IS
  'Snapshot del base_price del listing al momento de la reserva (CLP).';
COMMENT ON COLUMN bookings.porcentaje_atrio IS
  '0.05 (inicial) o 0.09 (normal). NO incluye efecto del mínimo.';
COMMENT ON COLUMN bookings.servicio_atrio_calculado IS
  'round(precio_base * porcentaje_atrio). Sin aplicar mínimo.';
COMMENT ON COLUMN bookings.servicio_atrio_amount IS
  'GREATEST(calculado, 1490). Es lo que el cliente realmente paga sobre el base.';
COMMENT ON COLUMN bookings.servicio_atrio_minimo_aplicado IS
  'true cuando se usó el piso de $1.490 en vez del % puro.';
COMMENT ON COLUMN bookings.precio_total IS
  'precio_base + servicio_atrio_amount — lo que se cobra al cliente.';
COMMENT ON COLUMN bookings.host_expected_amount IS
  'Lo que debería recibir el host: siempre = precio_base.';
COMMENT ON COLUMN bookings.host_paid_reservation_count_at_booking IS
  'Contador del host AL MOMENTO de crear esta reserva (no se incluye a sí misma).';
COMMENT ON COLUMN bookings.initial_benefit_applied IS
  'true cuando esta reserva consume una de las 5 primeras del beneficio inicial.';
COMMENT ON COLUMN bookings.host_payout_status IS
  'Estado del payout al host. NULL = aún no procesado.';

-- 2. Helper: cuenta reservas pagadas + confirmadas + no reembolsadas
--    (no cuenta pending, rejected, cancelled, refunded)
CREATE OR REPLACE FUNCTION host_paid_reservation_count(p_host_id UUID)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::int
  FROM bookings
  WHERE host_id = p_host_id
    AND payment_status = 'paid'
    AND status IN ('confirmed','completed','active')
    -- A booking is "refunded" if its status is cancelled with refund OR
    -- if a refund row exists in payment_events. Use a robust OR.
    AND NOT EXISTS (
      SELECT 1 FROM payment_events e
      WHERE e.booking_id = bookings.id
        AND e.event_type IN ('payment_refunded','refund')
    );
$$;

COMMENT ON FUNCTION host_paid_reservation_count IS
  'Cuenta reservas paid + confirmadas/completadas/activas + sin refund. Usado para el beneficio inicial de 5 reservas.';

-- 3. Main RPC: calculate_atrio_pricing -----------------------------
-- Devuelve el desglose canónico que el cliente DEBE mostrar y
-- persistir. Frontend NUNCA recalcula.
DROP FUNCTION IF EXISTS calculate_atrio_pricing(UUID, INTEGER, INTEGER);
CREATE OR REPLACE FUNCTION calculate_atrio_pricing(
  p_host_id      UUID,
  p_precio_base  INTEGER,
  p_units        INTEGER DEFAULT 1   -- nights/sessions/hours multiplier
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_host_verified BOOLEAN;
  v_paid_count    INTEGER;
  v_pct_initial   NUMERIC;
  v_pct_normal    NUMERIC;
  v_min_clp       INTEGER;
  v_limit         INTEGER;
  v_pct           NUMERIC;
  v_base          INTEGER;
  v_calc          INTEGER;
  v_amount        INTEGER;
  v_min_applied   BOOLEAN;
  v_initial       BOOLEAN;
  v_label         TEXT;
  v_total         INTEGER;
BEGIN
  -- Read tunables from pricing_config with safe defaults
  SELECT value::numeric INTO v_pct_initial
    FROM pricing_config WHERE key = 'INITIAL_HOST_FEE_PERCENTAGE';
  v_pct_initial := COALESCE(v_pct_initial, 0.05);

  SELECT value::numeric INTO v_pct_normal
    FROM pricing_config WHERE key = 'PLATFORM_FEE_PERCENTAGE';
  v_pct_normal := COALESCE(v_pct_normal, 0.09);

  SELECT value::int INTO v_min_clp
    FROM pricing_config WHERE key = 'SERVICE_FEE_MIN_CLP';
  v_min_clp := COALESCE(v_min_clp, 1490);

  SELECT value::int INTO v_limit
    FROM pricing_config WHERE key = 'INITIAL_HOST_RESERVATION_LIMIT';
  v_limit := COALESCE(v_limit, 5);

  -- Effective precio_base for this booking (base × units, e.g. nights)
  v_base := GREATEST(0, p_precio_base * GREATEST(1, p_units));

  -- Host verification + paid-reservation counter
  SELECT COALESCE(is_verified, false) INTO v_host_verified
    FROM profiles WHERE id = p_host_id;
  v_host_verified := COALESCE(v_host_verified, false);

  v_paid_count := host_paid_reservation_count(p_host_id);

  -- Decide rate
  IF v_host_verified AND v_paid_count < v_limit THEN
    v_pct     := v_pct_initial;
    v_initial := true;
    v_label   := 'Servicio Atrio inicial';
  ELSE
    v_pct     := v_pct_normal;
    v_initial := false;
    v_label   := 'Servicio Atrio';
  END IF;

  -- Compute fee with floor at v_min_clp
  v_calc        := ROUND(v_base * v_pct)::int;
  v_amount      := GREATEST(v_calc, v_min_clp);
  v_min_applied := (v_calc < v_min_clp);
  v_total       := v_base + v_amount;

  RETURN jsonb_build_object(
    'precio_base',                            v_base,
    'porcentaje_atrio',                       v_pct,
    'servicio_atrio_calculado',               v_calc,
    'servicio_atrio_amount',                  v_amount,
    'servicio_atrio_minimo_aplicado',         v_min_applied,
    'servicio_atrio_minimo_clp',              v_min_clp,
    'precio_total',                           v_total,
    'host_expected_amount',                   v_base,
    'host_paid_reservation_count_at_booking', v_paid_count,
    'initial_benefit_applied',                v_initial,
    'host_verified',                          v_host_verified,
    'service_label',                          v_label
  );
END;
$$;

COMMENT ON FUNCTION calculate_atrio_pricing IS
  'Single source of truth for booking pricing. Returns the canonical JSON breakdown.';

GRANT EXECUTE ON FUNCTION calculate_atrio_pricing(UUID, INTEGER, INTEGER)
  TO authenticated, anon;
GRANT EXECUTE ON FUNCTION host_paid_reservation_count(UUID)
  TO authenticated;

-- 4. payment_events ledger ---------------------------------------
CREATE TABLE IF NOT EXISTS payment_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID REFERENCES bookings(id) ON DELETE CASCADE,
  event_type   TEXT NOT NULL,        -- payment_approved | payment_rejected | payment_refunded | host_funds_available | host_payout_paid | host_payout_failed | etc.
  provider     TEXT,                 -- 'mercadopago'
  provider_id  TEXT,                 -- mp payment id, refund id, etc.
  payload      JSONB,                -- raw webhook body or relevant metadata
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_events_booking
  ON payment_events(booking_id, created_at);
CREATE INDEX IF NOT EXISTS idx_payment_events_type
  ON payment_events(event_type, created_at);

ALTER TABLE payment_events ENABLE ROW LEVEL SECURITY;

-- Only the booking's guest or host can read its events. Inserts are
-- service_role only (Edge Function uses SUPABASE_SERVICE_ROLE_KEY).
DROP POLICY IF EXISTS "payment_events_read_participants" ON payment_events;
CREATE POLICY "payment_events_read_participants"
  ON payment_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.id = payment_events.booking_id
        AND (b.guest_id = auth.uid() OR b.host_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "payment_events_no_client_writes" ON payment_events;
CREATE POLICY "payment_events_no_client_writes"
  ON payment_events FOR INSERT
  WITH CHECK (false);

-- 5. Verification quickcheck -------------------------------------
SELECT
  (SELECT COUNT(*) FROM pricing_config
    WHERE key IN ('PLATFORM_FEE_PERCENTAGE','INITIAL_HOST_FEE_PERCENTAGE',
                  'SERVICE_FEE_MIN_CLP','INITIAL_HOST_RESERVATION_LIMIT'))
    AS pricing_keys_present,
  (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_name = 'bookings' AND column_name LIKE '%atrio%') AS atrio_cols_present,
  (SELECT EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'calculate_atrio_pricing'))
    AS rpc_present,
  (SELECT EXISTS(SELECT 1 FROM pg_tables WHERE tablename = 'payment_events'))
    AS payment_events_present;
