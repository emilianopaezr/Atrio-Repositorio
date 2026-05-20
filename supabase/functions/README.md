# Atrio — Supabase Edge Functions

## Functions

| Name | Purpose | Auth |
|---|---|---|
| `mp-create-preference` | Create a Mercado Pago Checkout Pro preference for a booking | User JWT (verifies guest_id matches auth.uid) |
| `mp-webhook` | Receive payment notifications from Mercado Pago, update `bookings.payment_status` | MP signature (x-signature header) |

## Required secrets (set on the Edge Runtime)

```
SUPABASE_URL                  = https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host
SUPABASE_ANON_KEY             = (the new anon key)
SUPABASE_SERVICE_ROLE_KEY     = (the new service role key — server-only)
MP_ACCESS_TOKEN               = APP_USR-xxxx (server-only access token from Mercado Pago)
MP_WEBHOOK_SECRET             = (optional) signing secret from MP "Webhooks" config
MP_WEBHOOK_PUBLIC_URL         = https://<host>/functions/v1/mp-webhook
MP_BACK_SUCCESS               = https://atrio.app/payment/success
MP_BACK_FAILURE               = https://atrio.app/payment/failure
MP_BACK_PENDING               = https://atrio.app/payment/pending
```

## Deploying on EasyPanel

The default `hello` function already works at `/functions/v1/hello`, which means
the edge runtime is already set up with a mounted volume. To deploy:

### Option 1 — EasyPanel file manager (recommended)
1. EasyPanel → tu servicio Supabase → tab **"Files"** o **"Volumes"**.
2. Navegar a la carpeta donde están las funciones (típicamente
   `volumes/functions/` o `/home/deno/functions/` dentro del contenedor
   `edge-runtime`).
3. Crear carpetas `mp-create-preference/` y `mp-webhook/`.
4. Subir los archivos `index.ts` correspondientes.
5. **Settings** del servicio edge-runtime → **Environment Variables** →
   agregar los secrets listados arriba.
6. Reiniciar el servicio edge-runtime.

### Option 2 — Supabase CLI (si tenés acceso SSH)
```bash
supabase functions deploy mp-create-preference --project-ref <ref>
supabase functions deploy mp-webhook --project-ref <ref>
supabase secrets set MP_ACCESS_TOKEN=APP_USR-... --project-ref <ref>
```

## Verifying deployment

```bash
# Should respond 401 "Missing bearer token" (proves the function is up).
curl -X POST https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host/functions/v1/mp-create-preference

# Webhook health check (should be 405 since GET is not allowed).
curl https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host/functions/v1/mp-webhook
```

## Configuring the Mercado Pago webhook

1. https://www.mercadopago.cl/developers/panel/app → tu app → **Webhooks**.
2. URL de notificación: `https://atrioappcloude-atrioappcloude.2rfeor.easypanel.host/functions/v1/mp-webhook`
3. Eventos a suscribir: **Pagos** (`payment`).
4. Copiar el **Secret** que MP genera y setearlo como `MP_WEBHOOK_SECRET` en
   las variables del edge-runtime.

## Tarjetas de prueba (sandbox)

Usar email `test_user_xxx@testuser.com` (lo creás en MP > Cuentas de prueba).

| Marca | Número | CVV | Vence | Resultado |
|---|---|---|---|---|
| Mastercard | 5031 7557 3453 0604 | 123 | 11/30 | aprobado |
| Visa | 4509 9535 6623 3704 | 123 | 11/30 | aprobado |
| American Express | 3711 803032 57522 | 1234 | 11/30 | aprobado |
| Visa (rechazo) | 4013 5406 8274 6260 | 123 | 11/30 | rechazado por fondos |

Para forzar resultados específicos, en el nombre del titular:
- `APRO` → aprobado
- `OTHE` → rechazado por error general
- `CONT` → pendiente
- `CALL` → rechazado, llamar al banco
- `FUND` → rechazado por fondos
- `SECU` → rechazado por código de seguridad
