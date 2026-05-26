# Mercado Pago — Runbook de Switch a LIVE

> **Estado actual:** `MP_SANDBOX=true` con keys `TEST-...`. Los pagos no se
> cobran de verdad — siempre pasan por el sandbox de MP.
>
> **Estado objetivo:** `MP_SANDBOX=false` con keys `APP_USR-...` (live). Los
> pagos cobran de verdad al método del usuario y depositan en tu cuenta de MP.

Este documento es un runbook ordenado para ejecutar el switch sin romper nada
y con un camino de rollback claro.

---

## 0. Pre-flight checklist

Antes de empezar, confirma uno a uno:

- [ ] **Cuenta MP verificada** — En https://www.mercadopago.cl/developers,
  cuenta personal o de empresa con datos bancarios chilenos (RUT + cuenta
  corriente/vista) confirmados. Sin esto, los pagos approve pero el dinero
  no se puede retirar.
- [ ] **App publicada en MP** — Developers → Tus integraciones → tu app
  existe y tiene scope "checkout-api" habilitado.
- [ ] **Webhook URL en producción** — `MP_WEBHOOK_PUBLIC_URL` apunta a
  una Edge Function publicada (no localhost ni ngrok).
- [ ] **Edge Function `mp-create-payment` publicada** en Supabase con su
  secret actual.
- [ ] **Edge Function `mp-webhook` publicada** (o equivalente) procesando
  eventos `payment.created` / `payment.updated`.
- [ ] **Backup del estado actual** — anota los valores actuales de
  `MP_PUBLIC_KEY` y `MP_ACCESS_TOKEN` (sandbox) para poder hacer rollback.

---

## 1. Obtener las credenciales LIVE de Mercado Pago

1. Ir a https://www.mercadopago.cl/developers/panel
2. Seleccionar tu aplicación de Atrio (la misma donde tienes las keys TEST-)
3. En la barra lateral → **Credenciales de producción**

Verás dos valores nuevos:

| Clave | Formato | Para qué |
|---|---|---|
| **Public Key** (producción) | `APP_USR-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Va al cliente (`.env` → `MP_PUBLIC_KEY`). Identifica tu cuenta cuando el SDK pide info pública del checkout. |
| **Access Token** (producción) | `APP_USR-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` | Va al **secret de la Edge Function** (NUNCA al `.env` del cliente ni al repo). Autoriza crear pagos reales y mover dinero. |

> ⚠️ El Access Token live es lo más sensible de todo el sistema. Quien lo
> tenga puede crear charges en tu nombre. Si se filtra, **regenerarlo
> inmediatamente** desde la misma pantalla — invalida el viejo.

---

## 2. Actualizar el secret del Edge Function

El `MP_ACCESS_TOKEN` lo guarda Supabase como un secret aparte del `.env` del
cliente.

```bash
# Desde un terminal con Supabase CLI logueado en tu proyecto:
supabase secrets set MP_ACCESS_TOKEN="APP_USR-XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" \
  --project-ref TU_PROJECT_REF
```

O por dashboard (alternativa):

1. Supabase Dashboard → tu proyecto self-hosted
2. **Edge Functions** → `mp-create-payment` → **Secrets**
3. Edit `MP_ACCESS_TOKEN` → pegar el valor `APP_USR-...` live → Save
4. Repetir si tienes otra Edge Function (`mp-webhook`, `mp-refund`, etc.)
   que también use el mismo token.

> Tras cambiar el secret, las próximas invocaciones a la función usan el
> nuevo token. No hace falta reiniciar nada.

---

## 3. Actualizar `.env` del cliente (Flutter)

Archivo: `atrio/.env`

```diff
- MP_PUBLIC_KEY=TEST-xxxx-xxxx-xxxx-xxxxxxxxxxxx
+ MP_PUBLIC_KEY=APP_USR-xxxx-xxxx-xxxx-xxxxxxxxxxxx
- MP_SANDBOX=true
+ MP_SANDBOX=false
```

El `MP_SANDBOX` flag es usado por `MercadoPagoService.isSandbox` para
mostrar banners de "modo prueba" en la app. Cuando lo pongas en `false`,
esos banners desaparecen y el flujo de checkout se trata como productivo.

> `.env` no se compila en cada build; se carga via `flutter_dotenv` y se
> empaqueta en `assets/`. **Hay que reconstruir el APK** para que el cambio
> llegue al dispositivo.

---

## 4. Re-build del APK release

```bash
flutter clean
flutter pub get
flutter build apk --release
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Verifica
el `MP_PUBLIC_KEY` empaquetado abriéndolo como zip e inspeccionando
`assets/.env` adentro — debe decir `APP_USR-...`.

---

## 5. Test con un pago real PEQUEÑO

Antes de exponer el flujo a usuarios:

1. **Crea un listing de testing** en tu cuenta de host con un precio bajo
   (ej. **$1.000 CLP**, el mínimo razonable). Status: `paused` para que no
   sea visible al público.
2. **Despáusalo** (`published`) temporalmente.
3. **Desde otra cuenta** (o desde la misma con otro email — pero idealmente
   otra), reservalo y paga con **tu propia tarjeta real**.
4. Confirma:
   - [ ] App muestra "pago aprobado" sin errores
   - [ ] Supabase: `bookings.payment_status = 'paid'` para esa reserva
   - [ ] Supabase: `bookings.mp_payment_id` está poblado
   - [ ] MP Dashboard → **Actividad** → ves el pago de $1.000 CLP como
         "Aprobado"
   - [ ] El monto neto (después de comisión MP) aparece en tu balance de MP
5. **Refund the test payment** desde el MP Dashboard → Pago → "Devolver
   dinero". El monto vuelve a tu tarjeta en ~3-7 días hábiles.
6. **Vuelve a pausar** el listing de testing.

> No saltes este paso. La diferencia entre sandbox y live a veces es una
> respuesta JSON ligeramente distinta, un parámetro requerido en producción
> que no lo era en sandbox, o un timeout de webhook diferente. Detectarlo
> con $1.000 CLP que puedes refundear es trivial; detectarlo con la primera
> reserva real de un usuario no lo es.

---

## 6. Verificar el webhook

El webhook es lo que mantiene `bookings.payment_status` sincronizado cuando
MP cambia el estado del pago de forma asincrónica (ej. una transferencia
bancaria pendiente que se aprueba 1h después).

1. MP Dashboard → tu aplicación → **Notificaciones**
2. Verifica que `MP_WEBHOOK_PUBLIC_URL` está registrado
3. Ve a "Probar" → enviar un POST de prueba → debes ver `200 OK`
4. Re-revisa el pago real del paso 5: el log de la Edge Function `mp-webhook`
   debe mostrar 1+ invocación procesando el evento

Si no llegan webhooks, revisa:
- HTTPS válido en la URL (MP no acepta self-signed)
- El cuerpo del POST se firma con tu `WEBHOOK_SECRET` (si lo usas)
- La Edge Function responde `200` aunque sea ignorando el evento — si
  responde `>= 300`, MP reintenta y termina pausando notificaciones.

---

## 7. Monitorear las primeras 24-72h

Mientras tienes pocos pagos por hora, revisa cada 2-3 horas:

| Dashboard | Qué buscar |
|---|---|
| **Sentry** → events tag `mp` | Errores `MpException`, status code 5xx desde MP |
| **MP Dashboard** → Actividad | Pagos en `rechazado` con razón "status_detail" |
| **Supabase** → tabla `bookings` | Filas con `payment_status='pending'` que llevan >1h sin cambiar |
| **Edge Function logs** | Invocaciones que terminan en error |

Query útil para spot-check en Supabase SQL Editor:

```sql
SELECT id, payment_status, mp_payment_id, total, created_at, updated_at
FROM bookings
WHERE payment_status IN ('pending', 'failed')
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

---

## 8. Rollback (si algo va mal)

Si algo crítico sale mal después del switch (ej. todos los pagos rechazan),
revertir es **fácil**:

```bash
# 1. Volver el secret del Edge Function al token TEST-
supabase secrets set MP_ACCESS_TOKEN="TEST-XXXXXXXX-..." --project-ref TU_PROJECT_REF

# 2. Volver el .env
```
```diff
- MP_PUBLIC_KEY=APP_USR-xxxx
+ MP_PUBLIC_KEY=TEST-xxxx
- MP_SANDBOX=false
+ MP_SANDBOX=true
```
```bash
# 3. Re-build APK
flutter build apk --release

# 4. Subir el APK rollback a la misma rama de release que tenían los usuarios
#    (Play Console internal track / staged rollout / TestFlight).
```

> El rollback en cliente requiere que los usuarios actualicen la app. Si
> usas Play Store con staged rollout al 1%, puedes pausar el rollout — el
> 99% sigue con sandbox y no ves más errores. Si ya pusiste al 100%, hay
> que esperar que los usuarios bajen el rollback.

---

## 9. Estrategia recomendada de roll-out

En vez de cambiar a LIVE al 100% de golpe:

1. **Staged rollout en Play Store al 5%** con el APK live
2. Monitorear Sentry + tabla bookings durante 24h
3. Si todo OK → 20%
4. Otras 24h → 50%
5. Otras 24h → 100%

Esto te da margen para detectar y hacer rollback si algo regresional
aparece, sin afectar a toda la base de usuarios.

---

## 10. Después del switch

Una vez estable:

- [ ] Eliminar el listing de testing si lo dejaste en `paused`
- [ ] Borrar las keys `TEST-` de tu password manager (si las tenías
  guardadas) — ya no sirven, y mantenerlas alrededor es confuso
- [ ] Cerrar este runbook hasta que toque rotar credenciales (típicamente
  anual o ante incident)
- [ ] Documentar la fecha y commit del switch en `CHANGELOG.md` si
  llevas uno

---

## Referencias

- MP Checkout API docs: https://www.mercadopago.cl/developers/es/docs/checkout-api/landing
- MP webhooks: https://www.mercadopago.cl/developers/es/docs/your-integrations/notifications/webhooks
- Edge Function deploy: `supabase functions deploy mp-create-payment`
- Test cards (solo sandbox, NO funcionan en live): https://www.mercadopago.cl/developers/es/docs/checkout-api/integration-test/test-cards
