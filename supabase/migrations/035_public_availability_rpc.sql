-- ============================================================
-- Migration 035 — Public availability RPC (rental-mode aware)
-- ------------------------------------------------------------
-- Bug fix: the public listing calendar was marking entire days as
-- BOOKED (red) when a single hour slot was reserved on that day.
--
-- Root cause: `get_booked_dates` (migration 006) treats EVERY booking
-- as a multi-day stay — it generates a series of dates from check_in
-- to check_out for every booking, regardless of rental_mode. But for
-- 'hours' bookings, check_out is set to (booking_date + 1 day) in the
-- checkout flow purely as a calendar marker; the actual time window
-- is in start_time / end_time. The result: a 1-hour booking blocked
-- the whole day for every other potential guest.
--
-- Fix: introduce `get_public_booked_dates`, used by the listing
-- detail's mini-calendar. For 'hours' rental mode it only marks a
-- date as booked when the SUM of all booked duration_hours on that
-- date is >= the listing's operating window (check_out_time -
-- check_in_time). The host calendar continues to use the original
-- `get_booked_dates` so hosts still see every partial-day booking
-- on their own grid.
-- ============================================================

CREATE OR REPLACE FUNCTION get_public_booked_dates(
  p_listing_id UUID,
  p_start_date DATE,
  p_end_date DATE
) RETURNS TABLE(
  booked_date     DATE,
  is_blocked      BOOLEAN,
  booking_id      UUID,
  booking_status  TEXT
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_check_in       TIME;
  v_check_out      TIME;
  v_operating_h    NUMERIC;
BEGIN
  -- Resolve the listing's daily operating window (used for hours mode).
  -- Falls back to a 9-hour day if the values are missing.
  SELECT check_in_time, check_out_time
    INTO v_check_in, v_check_out
    FROM listings
   WHERE id = p_listing_id;

  IF v_check_in IS NULL OR v_check_out IS NULL THEN
    v_operating_h := 9;
  ELSE
    v_operating_h := EXTRACT(EPOCH FROM (v_check_out - v_check_in)) / 3600.0;
    IF v_operating_h <= 0 THEN
      v_operating_h := 9;
    END IF;
  END IF;

  RETURN QUERY
    -- ── 1) Multi-night and full-day bookings ────────────────────────
    --     Each covered date is fully unavailable to other guests.
    SELECT
      d::DATE                       AS booked_date,
      FALSE                         AS is_blocked,
      b.id                          AS booking_id,
      b.status                      AS booking_status
    FROM bookings b,
      generate_series(
        b.check_in::DATE,
        b.check_out::DATE - INTERVAL '1 day',
        '1 day'
      ) AS d
    WHERE b.listing_id = p_listing_id
      AND b.status IN ('pending', 'confirmed', 'active')
      AND COALESCE(b.rental_mode, 'nights') IN ('nights', 'full_day')
      AND d::DATE BETWEEN p_start_date AND p_end_date

    UNION ALL

    -- ── 2) Hours bookings — only mark the day as taken when EVERY
    --     hour in the listing's operating window is booked.
    --     Other guests can still book remaining slots otherwise.
    SELECT
      agg.bd                        AS booked_date,
      FALSE                         AS is_blocked,
      NULL::UUID                    AS booking_id,
      'confirmed'::TEXT             AS booking_status
    FROM (
      SELECT
        b.booking_date              AS bd,
        SUM(COALESCE(b.duration_hours, 0)) AS total_booked_hours
      FROM bookings b
      WHERE b.listing_id = p_listing_id
        AND b.status IN ('pending', 'confirmed', 'active')
        AND b.rental_mode = 'hours'
        AND b.booking_date IS NOT NULL
        AND b.booking_date BETWEEN p_start_date AND p_end_date
      GROUP BY b.booking_date
    ) agg
    WHERE agg.total_booked_hours >= v_operating_h

    UNION ALL

    -- ── 3) Manually blocked availability rows ───────────────────────
    SELECT
      a.date,
      TRUE,
      a.booking_id,
      NULL::TEXT
    FROM availability a
    WHERE a.listing_id = p_listing_id
      AND a.is_available = FALSE
      AND a.date BETWEEN p_start_date AND p_end_date;
END;
$$;

COMMENT ON FUNCTION get_public_booked_dates IS
  'Public-facing booked dates for a listing. For hours-mode bookings, a date is only reported as booked when SUM(duration_hours) on that date equals or exceeds the listing''s operating window (check_out_time - check_in_time). Used by the listing detail mini-calendar; the host calendar continues to use get_booked_dates so partial-day activity stays visible to the host.';
