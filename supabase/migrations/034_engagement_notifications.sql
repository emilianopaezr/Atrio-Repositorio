-- ============================================================
-- Migration 034 — Engagement notifications (pg_cron + send-push)
-- ------------------------------------------------------------
-- Sends periodic, personalised pushes so users come back to the app.
-- Three campaigns:
--   1. Daily inactivity reminder — users with no app activity in
--      the last 7 days (and who haven't opted out of `reminders`).
--   2. Weekly digest — every Sunday 7 pm CLT to all active users:
--      a quick summary of new listings near their last city.
--   3. Pending bookings nudge — every morning at 9 am: hosts with
--      pending bookings older than 12 h.
--
-- All campaigns:
--   • Respect the per-category toggle stored on the device (the
--     mobile NotificationPrefs layer filters them client-side too,
--     so a user who turned reminders off won't get noise).
--   • Use the `notifications` table for inbox surfacing AND fire
--     a real push via the send-push Edge Function (pg_net).
--   • Are idempotent within their window (won't re-send the same
--     reminder twice in the same 7-day inactivity bucket).
--
-- Requires:
--   • pg_net (already enabled by 017_push_on_notification)
--   • pg_cron (already enabled by 018_auto_complete_bookings)
--   • app.edge_function_url + app.edge_function_key as ALTER DATABASE
--     settings (same as 017_push_on_notification's setup).
-- ============================================================

-- Tracks which engagement pushes we've already sent so we don't spam.
CREATE TABLE IF NOT EXISTS engagement_log (
  id           BIGSERIAL PRIMARY KEY,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  campaign     TEXT NOT NULL,             -- 'inactive_7d', 'weekly_digest', 'pending_bookings'
  sent_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  payload      JSONB
);

CREATE INDEX IF NOT EXISTS idx_engagement_log_user_campaign
  ON engagement_log (user_id, campaign, sent_at DESC);

ALTER TABLE engagement_log ENABLE ROW LEVEL SECURITY;

-- Only admins or the user themselves can read their log.
CREATE POLICY engagement_log_read ON engagement_log
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM profiles
               WHERE id = auth.uid() AND is_admin = TRUE)
  );

-- ============================================================
-- Helper: fire a push for a notification we just inserted.
-- Mirrors the logic in 017_push_on_notification but parameterised
-- so we can call it from any engagement function.
-- ============================================================
CREATE OR REPLACE FUNCTION send_engagement_push(
  p_user_id      UUID,
  p_title        TEXT,
  p_body         TEXT,
  p_route        TEXT,
  p_type         TEXT,
  p_campaign     TEXT,
  p_data         JSONB DEFAULT '{}'::jsonb
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, net
AS $$
DECLARE
  v_url        TEXT := current_setting('app.edge_function_url', TRUE);
  v_key        TEXT := current_setting('app.edge_function_key', TRUE);
  v_notif_id   UUID;
BEGIN
  -- Idempotency window: skip if we sent the same campaign to this
  -- user in the last 20 hours.
  IF EXISTS (
    SELECT 1 FROM engagement_log
    WHERE user_id = p_user_id
      AND campaign = p_campaign
      AND sent_at > NOW() - INTERVAL '20 hours'
  ) THEN
    RETURN;
  END IF;

  -- Inbox row (so the user sees it in /notifications even if push
  -- delivery fails). The existing trigger trg_notify_push from
  -- migration 017 also fires send-push from this INSERT, so the
  -- explicit net.http_post below is belt-and-suspenders for the
  -- engagement-log idempotency layer.
  -- NOTE: `notifications` has no `route` column — the route is stored inside
  -- the `data` JSONB (data->>'route'), which is the convention the FCM handler
  -- and trigger 017 (trg_notify_push) read. Merge it in here.
  INSERT INTO notifications (
    user_id, type, title, body, data, created_at
  )
  VALUES (
    p_user_id,
    p_type,
    p_title,
    p_body,
    COALESCE(p_data, '{}'::jsonb) || jsonb_build_object('route', p_route),
    NOW()
  )
  RETURNING id INTO v_notif_id;

  -- Skip the explicit push if DB settings are missing — trigger 017
  -- will still try (and also no-op cleanly). Lets the DB work even
  -- before the one-time setup is done.
  IF v_url IS NULL OR v_url = '' OR v_key IS NULL OR v_key = '' THEN
    INSERT INTO engagement_log (user_id, campaign, payload)
    VALUES (
      p_user_id,
      p_campaign,
      jsonb_build_object('title', p_title, 'route', p_route, 'push_skipped', true)
    );
    RETURN;
  END IF;

  PERFORM net.http_post(
    url     := v_url,
    headers := jsonb_build_object(
      'content-type',   'application/json',
      'authorization',  'Bearer ' || v_key
    ),
    body    := jsonb_build_object(
      'user_id', p_user_id,
      'title',   p_title,
      'body',    p_body,
      'data',    jsonb_build_object(
        'route', p_route,
        'type',  p_type,
        'notification_id', v_notif_id::text
      )
    )
  );

  INSERT INTO engagement_log (user_id, campaign, payload)
  VALUES (
    p_user_id,
    p_campaign,
    jsonb_build_object('title', p_title, 'route', p_route)
  );
EXCEPTION WHEN OTHERS THEN
  -- Never let a push delivery error break a campaign run.
  INSERT INTO engagement_log (user_id, campaign, payload)
  VALUES (
    p_user_id,
    p_campaign,
    jsonb_build_object('title', p_title, 'route', p_route, 'error', SQLERRM)
  );
END;
$$;

-- ============================================================
-- Campaign 1 — Inactive 7d
-- Users who haven't created a booking, sent a message or updated
-- their profile in the last 7 days, and registered > 3 days ago.
-- ============================================================
CREATE OR REPLACE FUNCTION campaign_inactive_users()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR v_user IN
    SELECT p.id, p.display_name
      FROM profiles p
     WHERE p.created_at < NOW() - INTERVAL '3 days'
       AND NOT EXISTS (
         SELECT 1 FROM bookings b
          WHERE b.guest_id = p.id
            AND b.created_at > NOW() - INTERVAL '7 days'
       )
       AND NOT EXISTS (
         SELECT 1 FROM messages m
          WHERE m.sender_id = p.id
            AND m.sent_at > NOW() - INTERVAL '7 days'
       )
       -- Don't pester users who already got this push in the last 6 days.
       AND NOT EXISTS (
         SELECT 1 FROM engagement_log e
          WHERE e.user_id = p.id
            AND e.campaign = 'inactive_7d'
            AND e.sent_at > NOW() - INTERVAL '6 days'
       )
     LIMIT 200  -- safety net
  LOOP
    PERFORM send_engagement_push(
      v_user.id,
      'Hace tiempo que no te vemos por Atrio',
      COALESCE(v_user.display_name, '') ||
        ', hay nuevas experiencias y espacios que podrían gustarte.',
      '/guest/home',
      'reminder',
      'inactive_7d'
    );
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

-- ============================================================
-- Campaign 2 — Weekly digest (Sundays)
-- Sends a "this week on Atrio" summary to all users active in the
-- last 30 days. Body counts new listings posted in the last 7 days
-- so the message feels fresh and personalised.
-- ============================================================
CREATE OR REPLACE FUNCTION campaign_weekly_digest()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user        RECORD;
  v_new_count   INTEGER;
  v_count       INTEGER := 0;
BEGIN
  SELECT COUNT(*) INTO v_new_count
    FROM listings
   WHERE status = 'published'
     AND created_at > NOW() - INTERVAL '7 days';

  IF v_new_count < 1 THEN
    RETURN 0;  -- nothing to brag about
  END IF;

  FOR v_user IN
    SELECT DISTINCT p.id
      FROM profiles p
     WHERE EXISTS (
       SELECT 1 FROM bookings b
        WHERE b.guest_id = p.id
          AND b.created_at > NOW() - INTERVAL '30 days'
     )
     OR EXISTS (
       SELECT 1 FROM messages m
        WHERE m.sender_id = p.id
          AND m.sent_at > NOW() - INTERVAL '30 days'
     )
  LOOP
    PERFORM send_engagement_push(
      v_user.id,
      'Tu semana en Atrio',
      v_new_count || ' espacios y experiencias nuevos esta semana. Echa un vistazo.',
      '/guest/home',
      'reminder',
      'weekly_digest'
    );
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

-- ============================================================
-- Campaign 3 — Pending bookings nudge (hosts)
-- Reminds hosts with pending bookings older than 12 hours that
-- guests are waiting for a decision.
-- ============================================================
CREATE OR REPLACE FUNCTION campaign_pending_bookings_nudge()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_host RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR v_host IN
    SELECT b.host_id, COUNT(*) AS pending_count
      FROM bookings b
     WHERE b.status = 'pending'
       AND b.payment_status = 'paid'
       AND b.created_at < NOW() - INTERVAL '12 hours'
     GROUP BY b.host_id
     LIMIT 200
  LOOP
    PERFORM send_engagement_push(
      v_host.host_id,
      'Tienes reservas esperando respuesta',
      v_host.pending_count || ' reserva(s) pendiente(s) de confirmar. No dejes a tus huéspedes esperando.',
      '/host/dashboard',
      'booking',
      'pending_bookings'
    );
    v_count := v_count + 1;
  END LOOP;
  RETURN v_count;
END;
$$;

-- ============================================================
-- pg_cron schedules
-- ------------------------------------------------------------
-- atrio-engagement-inactive   — daily 11:00 CLT (14:00 UTC)
-- atrio-engagement-weekly     — Sundays 19:00 CLT (22:00 UTC)
-- atrio-engagement-pending    — daily 09:00 CLT (12:00 UTC)
-- ============================================================

-- Drop & recreate the jobs idempotently.
DO $$
DECLARE
  j RECORD;
BEGIN
  FOR j IN
    SELECT jobid FROM cron.job
     WHERE jobname IN (
       'atrio-engagement-inactive',
       'atrio-engagement-weekly',
       'atrio-engagement-pending'
     )
  LOOP
    PERFORM cron.unschedule(j.jobid);
  END LOOP;
END $$;

SELECT cron.schedule(
  'atrio-engagement-inactive',
  '0 14 * * *',
  $$ SELECT campaign_inactive_users(); $$
);

SELECT cron.schedule(
  'atrio-engagement-weekly',
  '0 22 * * 0',
  $$ SELECT campaign_weekly_digest(); $$
);

SELECT cron.schedule(
  'atrio-engagement-pending',
  '0 12 * * *',
  $$ SELECT campaign_pending_bookings_nudge(); $$
);

COMMENT ON FUNCTION campaign_inactive_users IS
  'Sends a re-engagement push to users inactive 7+ days. Run daily.';
COMMENT ON FUNCTION campaign_weekly_digest IS
  'Sends a weekly "new on Atrio" summary push. Run Sundays.';
COMMENT ON FUNCTION campaign_pending_bookings_nudge IS
  'Reminds hosts of paid bookings still pending after 12 h. Run daily morning.';
