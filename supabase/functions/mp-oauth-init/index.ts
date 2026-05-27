// =============================================
// Edge Function: mp-oauth-init
// Returns the MP OAuth authorize URL for the calling host. The mobile
// app opens this URL in the system browser; MP redirects back to
// mp-oauth-callback with the auth code.
//
// State token includes host_id + nonce + signature so the callback
// can verify the request is genuine and avoid CSRF.
// =============================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { createHmac, randomBytes } from "node:crypto";

const SUPA_URL = Deno.env.get("SUPABASE_URL")!;
const SUPA_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
// REQUIRED: created in the MP marketplace dashboard.
const MP_CLIENT_ID = Deno.env.get("MP_CLIENT_ID") ?? "";
// REQUIRED: this URL must match what's configured in MP dashboard.
const MP_REDIRECT_URI = Deno.env.get("MP_OAUTH_REDIRECT_URI") ?? "";
// Used to HMAC the state token so the callback can verify it.
const MP_OAUTH_STATE_SECRET = Deno.env.get("MP_OAUTH_STATE_SECRET") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

function signState(payload: string): string {
  return createHmac("sha256", MP_OAUTH_STATE_SECRET)
    .update(payload)
    .digest("hex");
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });

  if (!MP_CLIENT_ID || !MP_REDIRECT_URI || !MP_OAUTH_STATE_SECRET) {
    return json(500, {
      error:
        "MP marketplace not configured. Set MP_CLIENT_ID, MP_OAUTH_REDIRECT_URI, MP_OAUTH_STATE_SECRET.",
    });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json(401, { error: "Missing bearer token" });

    const userClient = createClient(SUPA_URL, SUPA_ANON, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: u, error: uErr } = await userClient.auth.getUser();
    if (uErr || !u?.user) return json(401, { error: "Invalid token" });

    const hostId = u.user.id;
    const nonce = randomBytes(12).toString("hex");
    const issuedAt = Math.floor(Date.now() / 1000);
    // ttl: state token valid for 10 min.
    const expiresAt = issuedAt + 600;
    const payload = `${hostId}.${nonce}.${expiresAt}`;
    const signature = signState(payload);
    const state = `${payload}.${signature}`;

    // MP OAuth authorize URL
    // https://www.mercadopago.com/mlc/authorization?
    //   response_type=code&client_id=...&redirect_uri=...&state=...&platform_id=mp
    const url = new URL("https://auth.mercadopago.com/authorization");
    url.searchParams.set("response_type", "code");
    url.searchParams.set("client_id", MP_CLIENT_ID);
    url.searchParams.set("redirect_uri", MP_REDIRECT_URI);
    url.searchParams.set("state", state);
    url.searchParams.set("platform_id", "mp");

    return json(200, {
      authorize_url: url.toString(),
      expires_at: expiresAt,
    });
  } catch (e) {
    console.error("[mp-oauth-init] uncaught", e);
    return json(500, { error: String(e) });
  }
});
