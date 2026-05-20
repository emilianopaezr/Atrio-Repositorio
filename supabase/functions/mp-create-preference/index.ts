// =============================================
// Edge Function: mp-create-preference
// Creates a Mercado Pago Checkout Pro preference for a booking.
// The MP access token lives ONLY here, never in the mobile app.
// =============================================

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const MP_BASE = "https://api.mercadopago.com";
const MP_TOKEN = Deno.env.get("MP_ACCESS_TOKEN")!;
const SUPA_URL = Deno.env.get("SUPABASE_URL")!;
const SUPA_ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPA_SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_URL = Deno.env.get("MP_WEBHOOK_PUBLIC_URL") ?? "";
const SUCCESS_URL = Deno.env.get("MP_BACK_SUCCESS") ?? "https://atrio.app/payment/success";
const FAILURE_URL = Deno.env.get("MP_BACK_FAILURE") ?? "https://atrio.app/payment/failure";
const PENDING_URL = Deno.env.get("MP_BACK_PENDING") ?? "https://atrio.app/payment/pending";

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

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json(401, { error: "Missing bearer token" });

    const userClient = createClient(SUPA_URL, SUPA_ANON, {
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { data: u, error: uErr } = await userClient.auth.getUser();
    if (uErr || !u?.user) return json(401, { error: "Invalid token" });
    const userId = u.user.id;
    const userEmail = u.user.email ?? "";

    const body = await req.json().catch(() => ({}));
    const bookingId: string | undefined = body.bookingId;
    if (!bookingId) return json(400, { error: "bookingId required" });

    // Service-role read so we get a fresh, RLS-bypassed view.
    const admin = createClient(SUPA_URL, SUPA_SERVICE);
    const { data: booking, error: bErr } = await admin
      .from("bookings")
      .select(
        "id, guest_id, total, payment_status, listing:listings(title, city, type)"
      )
      .eq("id", bookingId)
      .single();
    if (bErr || !booking) return json(404, { error: "Booking not found" });
    if (booking.guest_id !== userId) return json(403, { error: "Forbidden" });
    if (booking.payment_status === "paid") {
      return json(409, { error: "Already paid" });
    }
    if (!booking.total || booking.total <= 0) {
      return json(400, { error: "Invalid total" });
    }

    const title = `Atrio: ${booking.listing?.title ?? "Reserva"}`;
    const description = [
      booking.listing?.city ?? "",
      booking.listing?.type ?? "",
    ]
      .filter(Boolean)
      .join(" - ");

    const prefBody: Record<string, unknown> = {
      items: [
        {
          title,
          description,
          quantity: 1,
          unit_price: Math.round(Number(booking.total)),
          currency_id: "CLP",
        },
      ],
      payer: { email: userEmail },
      back_urls: {
        success: SUCCESS_URL,
        failure: FAILURE_URL,
        pending: PENDING_URL,
      },
      auto_return: "approved",
      external_reference: booking.id,
      statement_descriptor: "ATRIO",
      expires: true,
      expiration_date_to: new Date(Date.now() + 2 * 3600 * 1000).toISOString(),
    };
    if (WEBHOOK_URL) prefBody.notification_url = WEBHOOK_URL;

    const mpRes = await fetch(`${MP_BASE}/checkout/preferences`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${MP_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(prefBody),
    });

    if (!mpRes.ok) {
      const details = await mpRes.text();
      console.error("[mp] preference error", mpRes.status, details);
      return json(502, { error: "MP error", status: mpRes.status, details });
    }

    const pref = await mpRes.json();

    // Persist preference id; ignore failure (the response is what matters).
    await admin
      .from("bookings")
      .update({ mp_preference_id: pref.id })
      .eq("id", bookingId);

    return json(200, {
      id: pref.id,
      init_point: pref.init_point,
      sandbox_init_point: pref.sandbox_init_point,
    });
  } catch (e) {
    console.error("[mp-create-preference] uncaught", e);
    return json(500, { error: String(e) });
  }
});
