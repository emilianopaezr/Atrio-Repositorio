// =============================================
// Edge Function: mp-oauth-callback
// Receives the OAuth code from MP's redirect, verifies the state
// token, exchanges code → access_token + refresh_token + mp_user_id,
// and persists into host_payment_accounts as service_role.
//
// On success returns an HTML page that closes the browser tab and
// hints the user to return to the Atrio app. The app picks up the
// new state via my_payment_status() on resume.
// =============================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { createHmac, timingSafeEqual } from "node:crypto";

const SUPA_URL = Deno.env.get("SUPABASE_URL")!;
const SUPA_SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const MP_BASE = "https://api.mercadopago.com";
const MP_CLIENT_ID = Deno.env.get("MP_CLIENT_ID") ?? "";
const MP_CLIENT_SECRET = Deno.env.get("MP_CLIENT_SECRET") ?? "";
const MP_REDIRECT_URI = Deno.env.get("MP_OAUTH_REDIRECT_URI") ?? "";
const MP_OAUTH_STATE_SECRET = Deno.env.get("MP_OAUTH_STATE_SECRET") ?? "";

function verifyState(state: string): { ok: boolean; hostId?: string; reason?: string } {
  const parts = state.split(".");
  if (parts.length !== 4) return { ok: false, reason: "malformed" };
  const [hostId, nonce, expiresAtStr, signature] = parts;
  const expiresAt = Number(expiresAtStr);
  if (!Number.isFinite(expiresAt)) return { ok: false, reason: "bad_expiry" };
  if (expiresAt < Math.floor(Date.now() / 1000)) {
    return { ok: false, reason: "expired" };
  }
  const payload = `${hostId}.${nonce}.${expiresAt}`;
  const expected = createHmac("sha256", MP_OAUTH_STATE_SECRET)
    .update(payload)
    .digest("hex");
  // Constant-time compare to prevent timing attacks.
  const a = Buffer.from(expected, "hex");
  const b = Buffer.from(signature, "hex");
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    return { ok: false, reason: "signature_mismatch" };
  }
  return { ok: true, hostId };
}

function htmlResponse(title: string, message: string, success: boolean): Response {
  // Inline page — no external assets needed; works on any phone browser.
  const body = `<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>${title}</title>
    <style>
      body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; background: #0E0E0E; color: #fff; font-family: 'Inter', system-ui, sans-serif; }
      .card { max-width: 420px; padding: 48px 28px; text-align: center; }
      .dot { width: 14px; height: 14px; border-radius: 50%; margin: 0 auto 18px; background: ${success ? "#D7F03A" : "#FF5C5C"}; box-shadow: 0 0 18px ${success ? "rgba(215,240,58,0.5)" : "rgba(255,92,92,0.5)"}; }
      h1 { font-size: 22px; font-weight: 800; letter-spacing: -0.5px; margin: 0 0 10px; }
      p { font-size: 14px; color: #B5B5B5; line-height: 1.5; margin: 0; }
      .hint { margin-top: 22px; font-size: 12px; color: #6E6E6E; }
    </style>
  </head>
  <body>
    <div class="card">
      <div class="dot"></div>
      <h1>${title}</h1>
      <p>${message}</p>
      <p class="hint">Puedes cerrar esta pestaña y volver a Atrio.</p>
    </div>
  </body>
</html>`;
  return new Response(body, {
    status: success ? 200 : 400,
    headers: { "Content-Type": "text/html; charset=utf-8" },
  });
}

serve(async (req) => {
  if (req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (!MP_CLIENT_ID || !MP_CLIENT_SECRET || !MP_REDIRECT_URI || !MP_OAUTH_STATE_SECRET) {
    return htmlResponse(
      "Configuración faltante",
      "MP Marketplace aún no está configurado.",
      false,
    );
  }

  try {
    const url = new URL(req.url);
    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");
    const error = url.searchParams.get("error");

    if (error) {
      return htmlResponse("Conexión cancelada", `MP devolvió: ${error}`, false);
    }
    if (!code || !state) {
      return htmlResponse(
        "Parámetros incompletos",
        "Faltó el código o el state token. Vuelve a Atrio e intenta de nuevo.",
        false,
      );
    }

    const verification = verifyState(state);
    if (!verification.ok || !verification.hostId) {
      console.error("[mp-oauth-callback] state failed", verification.reason);
      return htmlResponse(
        "State inválido",
        "El token de seguridad expiró o no es válido. Vuelve a Atrio.",
        false,
      );
    }
    const hostId = verification.hostId;

    // Exchange code for tokens (server-side, with client_secret).
    const tokenRes = await fetch(`${MP_BASE}/oauth/token`, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        client_id: MP_CLIENT_ID,
        client_secret: MP_CLIENT_SECRET,
        code,
        redirect_uri: MP_REDIRECT_URI,
      }).toString(),
    });
    if (!tokenRes.ok) {
      const detail = await tokenRes.text();
      console.error("[mp-oauth-callback] token exchange failed", tokenRes.status, detail);
      return htmlResponse(
        "MP rechazó la conexión",
        "No se pudo intercambiar el código. Intenta de nuevo desde la app.",
        false,
      );
    }
    const tokens = await tokenRes.json();

    const mpUserId = String(tokens.user_id ?? "");
    const accessToken = tokens.access_token as string | undefined;
    const refreshToken = tokens.refresh_token as string | undefined;
    const publicKey = tokens.public_key as string | undefined;
    const scope = tokens.scope as string | undefined;
    const liveMode = tokens.live_mode === true;
    const expiresIn = Number(tokens.expires_in ?? 0);
    const expiresAt = expiresIn > 0
      ? new Date(Date.now() + expiresIn * 1000).toISOString()
      : null;

    if (!mpUserId || !accessToken) {
      console.error("[mp-oauth-callback] invalid token payload", tokens);
      return htmlResponse(
        "Respuesta MP inválida",
        "Los tokens recibidos están incompletos. Intenta de nuevo.",
        false,
      );
    }

    // Upsert. Re-connecting overwrites the row but keeps the host_id.
    const admin = createClient(SUPA_URL, SUPA_SERVICE);
    const { error: upErr } = await admin
      .from("host_payment_accounts")
      .upsert({
        host_id: hostId,
        provider: "mercadopago",
        mp_user_id: mpUserId,
        mp_access_token: accessToken,
        mp_refresh_token: refreshToken ?? null,
        mp_public_key: publicKey ?? null,
        mp_scope: scope ?? null,
        mp_live_mode: liveMode,
        expires_at: expiresAt,
        connected_at: new Date().toISOString(),
        last_refreshed_at: new Date().toISOString(),
        is_active: true,
        raw_payload: tokens,
      }, { onConflict: "host_id" });

    if (upErr) {
      console.error("[mp-oauth-callback] db upsert failed", upErr);
      return htmlResponse(
        "Error al guardar conexión",
        "Vuelve a Atrio e intenta de nuevo.",
        false,
      );
    }

    return htmlResponse(
      "¡Conectado!",
      "Tu cuenta de Mercado Pago quedó conectada a Atrio.",
      true,
    );
  } catch (e) {
    console.error("[mp-oauth-callback] uncaught", e);
    return htmlResponse("Error inesperado", String(e), false);
  }
});
