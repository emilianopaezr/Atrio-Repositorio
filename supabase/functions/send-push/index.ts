// Supabase Edge Function — send-push
// ---------------------------------------------------------------------------
// Deploy:
//   supabase functions deploy send-push --no-verify-jwt
//   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)"
//
// Secrets expected:
//   FCM_SERVICE_ACCOUNT  — full JSON of the Firebase service account key
//   SUPABASE_URL         — auto-injected
//   SUPABASE_SERVICE_ROLE_KEY — auto-injected
//
// Request body (JSON):
//   { "user_id": "<uuid>", "title": "...", "body": "...", "data": {...} }
//
// Behaviour:
//   1. Fetch every device_tokens row for the user
//   2. Mint a short-lived OAuth2 access token from the service account
//   3. POST each token to FCM HTTP v1 endpoint
//   4. Delete tokens that come back with UNREGISTERED / INVALID_ARGUMENT
// ---------------------------------------------------------------------------

// @ts-nocheck -- this file runs on Deno, not Node.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v5.9.6/index.ts";

interface PushRequest {
  user_id: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri: string;
}

function json(status: number, payload: unknown): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json" },
  });
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setAudience(sa.token_uri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(await importPKCS8(sa.private_key, "RS256"));

  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`OAuth token exchange failed: ${res.status} ${await res.text()}`);
  }
  const payload = await res.json();
  return payload.access_token as string;
}

async function sendToToken(
  projectId: string,
  accessToken: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean; shouldDelete: boolean; error?: string }> {
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const payload = {
    message: {
      token,
      notification: { title, body },
      data,
      android: {
        priority: "HIGH",
        notification: { channel_id: "atrio_default" },
      },
    },
  };
  const res = await fetch(url, {
    method: "POST",
    headers: {
      authorization: `Bearer ${accessToken}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });
  if (res.ok) return { ok: true, shouldDelete: false };

  const errText = await res.text();
  // FCM v1 returns UNREGISTERED / INVALID_ARGUMENT when a token is dead.
  const shouldDelete = /UNREGISTERED|INVALID_ARGUMENT|NOT_FOUND/i.test(errText);
  return { ok: false, shouldDelete, error: errText };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "POST only" });

  let payload: PushRequest;
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: "invalid json" });
  }
  const { user_id, title, body, data = {} } = payload;
  if (!user_id || !title || !body) {
    return json(400, { error: "user_id, title, body required" });
  }

  const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!saJson) return json(500, { error: "FCM_SERVICE_ACCOUNT not set" });
  const sa: ServiceAccount = JSON.parse(saJson);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: tokens, error } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("user_id", user_id);
  if (error) return json(500, { error: error.message });
  if (!tokens || tokens.length === 0) return json(200, { sent: 0 });

  const accessToken = await getAccessToken(sa);

  let sent = 0;
  const toDelete: string[] = [];
  const errors: string[] = [];

  // Convert data to string-typed record as required by FCM.
  const strData: Record<string, string> = {};
  for (const [k, v] of Object.entries(data)) strData[k] = String(v);

  await Promise.all(
    tokens.map(async ({ token }) => {
      const r = await sendToToken(
        sa.project_id,
        accessToken,
        token,
        title,
        body,
        strData,
      );
      if (r.ok) sent += 1;
      else {
        if (r.shouldDelete) toDelete.push(token);
        if (r.error) errors.push(r.error);
      }
    }),
  );

  if (toDelete.length > 0) {
    await supabase.from("device_tokens").delete().in("token", toDelete);
  }

  return json(200, { sent, pruned: toDelete.length, errors });
});
