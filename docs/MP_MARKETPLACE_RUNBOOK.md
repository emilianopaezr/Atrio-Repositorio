# Mercado Pago Marketplace — Setup Runbook

This document is the **only thing standing between the code that's
already merged and a working split-payment marketplace**. Everything
below happens OUTSIDE the repo (MP dashboard + EasyPanel secrets).
None of the steps require new code.

---

## 0. State of play

What's already implemented (and idle until you complete this runbook):

| Layer | File | Status |
|---|---|---|
| SQL: `host_payment_accounts` + RPCs + RLS | `supabase/migrations/030_mp_marketplace.sql` | merged |
| Edge Fn: `mp-oauth-init` | `supabase/functions/mp-oauth-init/index.ts` | merged |
| Edge Fn: `mp-oauth-callback` | `supabase/functions/mp-oauth-callback/index.ts` | merged |
| Edge Fn: `mp-create-preference` (now reads `mp_split_data`) | `supabase/functions/mp-create-preference/index.ts` | merged |
| Flutter: host connect screen + Settings tile | `lib/features/profile/.../host_payment_connect_screen.dart` | merged |
| Flutter: `HostPaymentService` (OAuth init + status RPC) | `lib/core/services/host_payment_service.dart` | merged |

While the env vars below are empty, the app stays in **collect mode**
(Atrio receives everything, manual payout to host). As soon as the
vars are populated and a host connects, that host's payments switch to
**split mode** transparently.

---

## 1. MP-side setup (you do this in mercadopago.com)

### 1.1 Convert your account to Marketplace

1. Log in to <https://www.mercadopago.cl/developers> with the account
   that owns the current Atrio access token.
2. **Create a new application** (or pick the existing one).
3. **Application type: Marketplace**. If your account doesn't expose
   this option, open a ticket via
   <https://www.mercadopago.cl/developers/panel/support>.
4. Configure:
   - Industry: `Lodging / Services` (closest match — adjust to local
     options).
   - Integration: `Pago Online (Checkout Pro)`.
   - **OAuth Redirect URI**: paste the URL of your deployed
     `mp-oauth-callback` Edge Function. Example:
     `https://<easypanel-host>/functions/v1/mp-oauth-callback`.
5. Once approved (can take 1-3 business days on first request), MP
   issues:
   - `Client ID`
   - `Client Secret`
   - A new pair of `Public Key` + `Access Token` (production)

### 1.2 Authorize your TEST account

While waiting for production approval you can iterate against MP's
test environment:

1. Create two test users in
   <https://www.mercadopago.cl/developers/panel/test-users>:
   - One **seller** (acts as a host).
   - One **buyer** (acts as a guest).
2. Use the test seller's user-id to validate the OAuth flow before
   prod is live.

---

## 2. EasyPanel — set environment variables

Add these to **all three Edge Functions** (`mp-oauth-init`,
`mp-oauth-callback`, `mp-create-preference`):

| Variable | Value | Notes |
|---|---|---|
| `MP_CLIENT_ID` | From step 1.1 | Treat as semi-public. |
| `MP_CLIENT_SECRET` | From step 1.1 | **Secret**. Never commit. |
| `MP_OAUTH_REDIRECT_URI` | `https://<host>/functions/v1/mp-oauth-callback` | Must match MP dashboard exactly. |
| `MP_OAUTH_STATE_SECRET` | Run `openssl rand -hex 32` | Used to HMAC-sign the OAuth state token. |
| `MP_ACCESS_TOKEN` | Already set | The marketplace's own (Atrio) token. |
| `MP_WEBHOOK_PUBLIC_URL` | Already set | Used by webhook handler. |
| `MP_WEBHOOK_SECRET` | Already set (optional) | HMAC for webhook verification. |

Then in the Flutter `.env` (mobile app side):

| Variable | Value |
|---|---|
| `MP_OAUTH_INIT_URL` | `https://<host>/functions/v1/mp-oauth-init` |
| `MP_PUBLIC_KEY` | The marketplace public key (already set) |
| `MP_SANDBOX` | `true` while testing, `false` for production |

The Flutter app reads `MP_OAUTH_INIT_URL` via
`HostPaymentService.oauthInitUrl`. When empty, the connect screen
shows the orange "MP Marketplace aún no está habilitado" banner and
disables the button — so it degrades cleanly.

---

## 3. Deploy

```bash
# From repo root
supabase functions deploy mp-oauth-init     --project-ref <YOUR_REF>
supabase functions deploy mp-oauth-callback --project-ref <YOUR_REF>
supabase functions deploy mp-create-preference --project-ref <YOUR_REF>
# Webhook already deployed; redeploy if you changed env vars:
supabase functions deploy mp-webhook --project-ref <YOUR_REF>
```

If you're on self-hosted Supabase via EasyPanel, the equivalent is
restarting each function container after updating its env vars.

Rebuild and reinstall the Flutter APK so it picks up the new
`MP_OAUTH_INIT_URL`:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 4. End-to-end smoke test

### As the host

1. Open the app → sign in as your host test user.
2. Profile → **Cobros (Mercado Pago)**.
3. Tap **"Conectar Mercado Pago"** → external browser opens.
4. Sign in with the **test seller** account.
5. Authorize Atrio.
6. MP redirects to `mp-oauth-callback`. You see "¡Conectado!" page.
7. Return to the app. The status card switches to "**CONECTADO**".

### Verify in DB

```sql
SELECT host_id, mp_user_id, mp_live_mode, is_active, expires_at
FROM host_payment_accounts
ORDER BY connected_at DESC LIMIT 5;
```

You should see your host's row, `mp_live_mode = false` for sandbox,
`expires_at` in the future.

### As the guest

1. Log in as the **test buyer**.
2. Book the host's listing.
3. Pay via MP. The preference body in EasyPanel logs should now show:
   ```json
   {
     "marketplace": "MP-MKT-ATRIO",
     "marketplace_fee": <servicio_atrio_amount>,
     "collector_id": <host mp_user_id>
   }
   ```
4. After payment, the booking row has `payment_status = 'paid'`,
   `host_payout_status = 'host_funds_pending'`, and a row in
   `payment_events` with `event_type = 'payment_approved'`.
5. Money distribution shows on MP:
   - `precio_base + cleaning_fee` → host's MP wallet
   - `servicio_atrio_amount` → Atrio's MP wallet

### Confirm in DB

```sql
SELECT
  b.id,
  b.precio_base,
  b.servicio_atrio_amount,
  b.precio_total,
  b.host_expected_amount,
  b.payment_status,
  b.host_payout_status,
  json_agg(e.event_type ORDER BY e.created_at) AS events
FROM bookings b
LEFT JOIN payment_events e ON e.booking_id = b.id
WHERE b.created_at > NOW() - INTERVAL '1 hour'
GROUP BY b.id
ORDER BY b.created_at DESC;
```

---

## 5. Rollback plan

If anything goes wrong (e.g. MP rejects the marketplace_fee parameter
on the live merchant), you can switch back to collect-only mode
**without redeploying any code** by:

1. Disconnecting every host:
   ```sql
   UPDATE host_payment_accounts SET is_active = false;
   ```
2. The `mp_split_data` RPC will then return `can_split: false`, and
   `mp-create-preference` will skip the marketplace block and route
   everything to Atrio's account again.

You can also flip a single host back by deleting their row, no harm
to historical bookings (the snapshot lives on the `bookings` row).

---

## 6. Open follow-ups

These are NOT blockers for marketplace going live, but worth doing
once everything is stable:

- [ ] **Refresh-token rotation**: MP access tokens expire ~6 months.
      Add a cron that picks rows where `expires_at < NOW() + INTERVAL '7 days'`
      and calls MP's refresh endpoint using `mp_refresh_token`.
- [ ] **Re-connect prompts**: when a host's token expires, surface a
      red banner on the host listings screen with a one-tap re-connect.
- [ ] **Block listing publish** when the host has no MP account.
      Add a guard in `DatabaseService.publishListing` or in the
      `Publicar` button using `hostHasPaymentAccount`.
- [ ] **Settlement report**: once the marketplace is producing
      revenue, generate a monthly statement aggregating the
      `payment_events` ledger by host.
