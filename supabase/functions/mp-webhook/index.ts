// =============================================
// Edge Function: mp-webhook
// Receives Mercado Pago IPN/webhook notifications, verifies the signature,
// fetches authoritative payment status from MP, and updates the booking.
// The DB trigger trg_booking_payment_paid handles cascade effects:
//   - Auto-confirms booking on first paid event
//   - Inserts earnings transaction
//   - Bumps host pending_balance
// =============================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { createHmac } from "node:crypto";

const MP_BASE = "https://api.mercadopago.com";
const MP_TOKEN = Deno.env.get("MP_ACCESS_TOKEN")!;
const MP_WEBHOOK_SECRET = Deno.env.get("MP_WEBHOOK_SECRET") ?? "";
const SUPA_URL = Deno.env.get("SUPABASE_URL")!;
const SUPA_SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function mapStatus(mpStatus: string): string {
  switch (mpStatus) {
    case "approved":
      return "paid";
    case "rejected":
    case "cancelled":
      return "failed";
    case "refunded":
    case "charged_back":
      return "refunded";
    case "in_process":
    case "pending":
    case "authorized":
    default:
      return "pending";
  }
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const url = new URL(req.url);
    const rawBody = await req.text();
    const body = rawBody ? JSON.parse(rawBody) : {};

    // Resolve payment id (MP sends it in body.data.id, sometimes in query).
    const paymentId =
      body?.data?.id ??
      body?.resource?.split("/").pop() ??
      url.searchParams.get("data.id") ??
      url.searchParams.get("id");

    if (!paymentId) {
      console.warn("[mp-webhook] no payment id", { body });
      return new Response("ignored", { status: 200 });
    }

    // Optional but strongly recommended: verify x-signature.
    if (MP_WEBHOOK_SECRET) {
      const xSignature = req.headers.get("x-signature") ?? "";
      const xRequestId = req.headers.get("x-request-id") ?? "";
      const parts = Object.fromEntries(
        xSignature.split(",").map((p) => {
          const [k, v] = p.split("=");
          return [k?.trim() ?? "", v?.trim() ?? ""];
        }),
      );
      const ts = parts["ts"];
      const v1 = parts["v1"];
      if (!ts || !v1) {
        console.error("[mp-webhook] missing signature parts");
        return new Response("Invalid signature", { status: 401 });
      }
      const manifest = `id:${paymentId};request-id:${xRequestId};ts:${ts};`;
      const expected = createHmac("sha256", MP_WEBHOOK_SECRET)
        .update(manifest)
        .digest("hex");
      if (expected !== v1) {
        console.error("[mp-webhook] signature mismatch", { expected, v1 });
        return new Response("Invalid signature", { status: 401 });
      }
    }

    // Only handle payment.* events; ignore plan/subscription/etc.
    const type = body?.type ?? body?.action?.split(".")[0] ?? "payment";
    if (type !== "payment") {
      return new Response("ignored type=" + type, { status: 200 });
    }

    // Fetch authoritative payment from MP — the body alone is not trusted.
    const pRes = await fetch(`${MP_BASE}/v1/payments/${paymentId}`, {
      headers: { Authorization: `Bearer ${MP_TOKEN}` },
    });
    if (!pRes.ok) {
      console.error("[mp-webhook] MP fetch failed", pRes.status);
      return new Response("MP fetch failed", { status: 502 });
    }
    const payment = await pRes.json();
    const bookingId: string | null = payment.external_reference ?? null;
    if (!bookingId) {
      console.warn("[mp-webhook] no external_reference in payment");
      return new Response("ok-no-ref", { status: 200 });
    }
    const dbStatus = mapStatus(payment.status);

    const admin = createClient(SUPA_URL, SUPA_SERVICE);
    const { error } = await admin
      .from("bookings")
      .update({
        payment_status: dbStatus,
        mp_payment_id: String(payment.id),
      })
      .eq("id", bookingId);

    if (error) {
      console.error("[mp-webhook] DB update failed", error);
      return new Response("DB error", { status: 500 });
    }

    console.log(
      `[mp-webhook] booking=${bookingId} mp_status=${payment.status} -> ${dbStatus}`,
    );
    return new Response("ok", { status: 200 });
  } catch (e) {
    console.error("[mp-webhook] uncaught", e);
    return new Response("error", { status: 500 });
  }
});
