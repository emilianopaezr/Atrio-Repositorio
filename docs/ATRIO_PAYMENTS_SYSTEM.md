# 💰 ATRIO - Sistema de Pagos & Monetización

## Descripción General
**ATRIO** es un marketplace premium de espacios, experiencias y servicios dirigido al mercado chileno. Usa un modelo de comisión progresiva donde:
- **Huéspedes** pagan una tarifa de servicio
- **Anfitriones** reciben un pago después de comisión
- **Plataforma** (ATRIO) gana comisión en cada transacción

---

## 🎯 Modelos de Precio y Comisiones

### Fase Early Adopter (Primeras 5 reservas)
| Concepto | Valor | Nota |
|---|---|---|
| **Comisión Host** | 1% | Tarifa promocional para incentivar anfitriones nuevos |
| **Tarifa Servicio Huésped** | 7% del subtotal | Capped a $90.000 CLP máx |
| **Payout Host** | Precio base + Limpieza - Comisión (1%) | |
| **Total Guest** | Precio base + Limpieza + Tarifa (7%) | |

**Ejemplo:**
- Precio base: $200.000 CLP/noche × 2 noches = $400.000
- Limpieza: $50.000
- Subtotal: $450.000
- Comisión Host (1%): $4.500 → **Host recibe: $445.500**
- Tarifa Guest (7%): $31.500 → **Guest paga: $481.500 total**
- **Ingresos Plataforma: $4.500 + $31.500 = $36.000**

### Después de 5 Reservas (Estándar)
| Concepto | Valor | Nota |
|---|---|---|
| **Comisión Host** | 9% | Tarifa estándar después fase promo |
| **Tarifa Servicio Huésped** | 7% del subtotal | Capped a $90.000 CLP máx |
| **Payout Host** | Precio base + Limpieza - Comisión (9%) | |
| **Total Guest** | Precio base + Limpieza + Tarifa (7%) | |

**Ejemplo (misma reserva):**
- Comisión Host (9%): $40.500 → **Host recibe: $409.500**
- Tarifa Guest (7%): $31.500 → **Guest paga: $481.500 total**
- **Ingresos Plataforma: $40.500 + $31.500 = $72.000**

---

## 📊 Estructura de Ingresos Plataforma

**Fuente 1: Comisión Host** (1-9%)
- Del monto base + servicios (antes de tarifa guest)
- Varía según número de reservas del anfitrión
- Máximo cap: $90.000 CLP por transacción

**Fuente 2: Tarifa Servicio Guest** (7%)
- Del subtotal (precio + limpieza)
- Máximo cap: $90.000 CLP por transacción
- Incluye: procesamiento de pago, soporte, seguros básicos, garantía de transacción

---

## 🏆 Tipos de Listados

| Tipo | Unidad | Ejemplo | Comisión |
|---|---|---|---|
| **Spaces** | Noches | Airbnb-like, departamentos/casas | 1-9% + 7% tarifa guest |
| **Experiences** | Horas/Eventos | Tours, clases, eventos | 1-9% + 7% tarifa guest |
| **Quick Services** | Horas | Mudanzas, limpiezas, armado | 1-9% + 7% tarifa guest |

---

## 💳 Flujo de Transacción

```
1. RESERVA CREADA (Guest crea booking)
   ↓
2. CÁLCULO DE PRECIOS (Server-side Postgres)
   - Base Price × Noches/Horas
   - + Cleaning Fee (si aplica)
   - + Guest Service Fee (7% capped $90k)
   ↓
3. PAGO PROCESADO (Guest paga a plataforma)
   ↓
4. DINERO ENTRA A ESCROW (Temporal en billetera plataforma)
   ↓
5. RESERVA CONFIRMADA (Host y Guest confirman)
   ↓
6. HOST PAYOUT (72h después, menos comisión)
   - Payout = (Base + Limpieza) - Host Commission (1-9%)
   - Persiste en tabla transactions
   ↓
7. ESTADO FINAL: completed ✅
```

---

## 📈 Indicadores Clave (Host Dashboard)

| Métrica | Cálculo | Visibilidad |
|---|---|---|
| **Earnings** | Sum de payouts completados (este mes) | Host Dashboard |
| **Pending Balance** | Reservas confirmadas - sin payout (48h) | Host Wallet |
| **Total Earnings** | Sum histórico de todos los payouts | Host Stats |
| **Response Rate** | % de mensajes respondidos en chat | Host Profile Badge |
| **Superhost Status** | Rating ≥ 4.8 + >10 reservas + 90% response | Host Profile Badge |

---

## 🔐 Validaciones & Seguridad

✅ **Prevención de Manipulación:**
- Cálculos se hacen **server-side** (Postgres RPC) — source of truth
- Client-side pricing es solo para **preview UI**, no se persiste
- Trigger DB valida que pricing coincida antes de marcar como "completed"

✅ **Anti-Fraude:**
- Limpieza de datos: mock data removido antes de producción
- Email de hosts/guests auditado
- Transacciones marcadas con `status: pending|processing|completed`

---

## 🌍 Moneda & Localización

- **Moneda Oficial:** CLP (Peso Chileno)
- **Región:** Chile
- **Tasa Conversión:** Dinámico (futuro integración con API de tipo de cambio)
- **Formato:** $XX.XXX CLP (ej: $450.000 CLP)

---

## 📱 Interfaz Guest

**Checkout Screen:**
1. Muestra desglose de precios en tiempo real
2. Tarifa de servicio 7% claramente visible
3. Total final antes de pagar
4. Método de pago integrado (Stripe/Mercado Pago)

**Booking Confirmation:**
- Descarga de recibo digital (PDF)
- Cronograma de payout para anfitrión
- Política de cancelación en CLP

---

## 🔄 Configuración Global (Constants)

```dart
// lib/core/utils/constants.dart
static const standardCommissionRate = 0.09;  // 9% (estándar)
static const promoCommissionRate = 0.01;     // 1% (early adopter)
static const promoBookingThreshold = 5;      // Primeras 5 reservas

// lib/core/services/pricing_engine_service.dart
static const double standardFeeRate = 0.07;  // 7% guest fee
static const double promoFeeRate = 0.01;     // 1% early adopter
static const double maxFeeCap = 90000.0;     // $90k CLP cap
```

---

## 🎨 Contexto para Carruseles Cowork

**Brand Colors:**
- 🟩 Neon Lime Dark: `#D4FF00` (CTAs, badges)
- ⬛ Host Mode: Black/Dark theme
- ⚪ Guest Mode: White/Light theme

**Tone:**
- Transparencia en costos (desglose claro)
- Confianza (validaciones server-side, garantías)
- Facilidad (one-click checkout, instant confirmations)

**Key Messages:**
- "Primeras 5 reservas: comisión especial 1% 🎁"
- "Tarifa de servicio 7% (máx $90.000 CLP)"
- "Payout en 72h a tu billetera ATRIO"
- "Todas las transacciones protegidas"

---

## 📋 Tablas Supabase Relacionadas

| Tabla | Función |
|---|---|
| `bookings` | Reservas, base_total, cleaning_fee, service_fee, status |
| `transactions` | Registro de ingresos/egresos, host_id, amount, status |
| `host_profiles` | current_balance, pending_balance, total_earnings |
| `host_stats` | current_commission_rate, booking_count |
| `pricing_config` | Configuración global de tasas y caps (futuro) |

---

**Última actualización:** 2026-04-08 | **Versión App:** 1.1.5
