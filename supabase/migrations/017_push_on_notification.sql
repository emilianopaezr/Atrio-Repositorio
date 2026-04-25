-- =============================================
-- 017: Push notifications on `notifications` insert
-- =============================================
-- When a row is inserted into `notifications`, call the `send-push` Edge
-- Function asynchronously via pg_net. The Edge Function looks up FCM tokens
-- for the user and delivers the push.
--
-- Prerequisites (one-time setup):
--   1. pg_net extension enabled                      CREATE EXTENSION pg_net;
--   2. DB settings with Edge Function URL + key:
--        ALTER DATABASE postgres SET app.edge_function_url =
--          'https://<project>.functions.supabase.co/send-push';
--        ALTER DATABASE postgres SET app.edge_function_key =
--          '<SUPABASE_SERVICE_ROLE_KEY>';
--      (reconnect after ALTER DATABASE for settings to apply)
--   3. Edge Function deployed (see supabase/functions/send-push).
--
-- If either setting is empty the trigger is a no-op, so the app keeps working
-- without push while setup is in progress.

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION notify_push_on_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, net
AS $func$
DECLARE
  v_url  TEXT := current_setting('app.edge_function_url', TRUE);
  v_key  TEXT := current_setting('app.edge_function_key', TRUE);
  v_body JSONB;
BEGIN
  -- Skip quietly if config is missing — lets the DB work even before setup.
  IF v_url IS NULL OR v_url = '' OR v_key IS NULL OR v_key = '' THEN
    RETURN NEW;
  END IF;

  v_body := jsonb_build_object(
    'user_id', NEW.user_id,
    'title',   COALESCE(NEW.title, 'Atrio'),
    'body',    COALESCE(NEW.body, ''),
    'data',    COALESCE(NEW.data, '{}'::jsonb)
              || jsonb_build_object(
                   'notification_id', NEW.id::text,
                   'type',            COALESCE(NEW.type, '')
                 )
  );

  -- Fire and forget. pg_net queues the HTTP call; failures do not roll back.
  PERFORM net.http_post(
    url     := v_url,
    body    := v_body,
    headers := jsonb_build_object(
      'content-type',   'application/json',
      'authorization',  'Bearer ' || v_key
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Never let a push failure block a notification insert.
  RETURN NEW;
END;
$func$;

DROP TRIGGER IF EXISTS trg_notify_push ON notifications;
CREATE TRIGGER trg_notify_push
AFTER INSERT ON notifications
FOR EACH ROW EXECUTE FUNCTION notify_push_on_notification();

COMMENT ON FUNCTION notify_push_on_notification IS
  'Fans out a push via send-push Edge Function whenever a notification row is inserted.';
