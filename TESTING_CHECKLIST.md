# Atrio — Checklist de Testing Manual E2E

> Última verificación: 2026-05-28
> Build: `dedcba3` · APK release 33.0 MB · Honor 400 Lite

---

## ✅ Verificación automática previa (ya hecha por mí)

- `flutter analyze` → **0 errores** (22 issues cosméticos)
- `flutter test` → **30 / 30 PASS**
- `flutter build apk --release` → OK, 33 MB
- APK instalado en Honor 400 Lite vía ADB inalámbrico

---

# 🧪 PARTE 1 — AUTH Y ONBOARDING

### 1.1 Primer arranque (cold start)
1. Cierra completamente la app (Recientes → swipe Atrio fuera).
2. Ábrela.
3. **Esperado:**
   - Splash con logo Atrio (fondo lime, logo negro).
   - Si no estás logueado → ves la pantalla de **Onboarding** (slides con CTA).
   - Si estás logueado → entras directo al home (Guest o Host según último modo).

### 1.2 Registro nuevo
1. Onboarding → tap **"Crear cuenta"** / **"Comenzar"**.
2. Completa: email + password + nombre.
3. Tap **"Crear cuenta"**.
4. **Esperado:**
   - Loading lime breve.
   - Pantalla de **"Verifica tu email"** con código de 6 dígitos.
   - Email llega a la bandeja (puede tomar 5–30 s).
5. Pega el código → tap **"Verificar"**.
6. **Esperado:** Entras directo al home como guest.

### 1.3 Re-signup con email no verificado
*(caso edge — opcional)*
1. Cierra app antes de verificar.
2. Vuelve a registrar con el mismo email.
3. **Esperado:** Permite reintentar — no dice "email ya en uso".

### 1.4 Login con email existente
1. Pantalla de login → email + password.
2. Tap **"Iniciar sesión"**.
3. **Esperado:** Entra al home (guest por defecto).

### 1.5 Forgot password
1. Login → tap **"¿Olvidaste tu contraseña?"**.
2. Ingresa email → **"Enviar enlace"**.
3. **Esperado:** Snackbar de confirmación + llega email con OTP.
4. Tap el link / abre la pantalla de reset → ingresa nueva password.
5. **Esperado:** Login automático con la nueva password.

### 1.6 Volver al login desde verify
1. En la pantalla de "Verifica tu email" → tap **"Volver al login"**.
2. **Esperado:** Te lleva a `/auth/login` sin perder progreso.

### 1.7 Logout
1. Estando logueado → Perfil → tap **"Cerrar sesión"**.
2. **Esperado:** Vuelve a la pantalla de login.

---

# 🧪 PARTE 2 — MODO GUEST (HUÉSPED)

## 2.1 Home
1. Entra como guest.
2. **Esperado:**
   - Header con saludo + foto de perfil (o iniciales).
   - Sección **"Para ti"** o **"Recomendados"** con cards horizontales.
   - Sección **"Cerca de ti"** (si tienes ubicación habilitada).
   - **Sin** stripe verde antiguo arriba (eliminado).

### 2.2 Búsqueda y filtros
1. Bottom nav → **Search**.
2. **Esperado:** Lista de espacios + experiencias + servicios.
3. Tap el icono de filtros → ajusta categoría, precio, ubicación.
4. **Esperado:** Resultados se actualizan en tiempo real.
5. Verifica que las **interest tags** del host (en su perfil) están traducidas si cambias el idioma.

### 2.3 Listing detail
1. Tap cualquier publicación.
2. **Esperado:**
   - Carrusel de imágenes arriba.
   - Título, precio, ubicación.
   - Sección **"Conoce al anfitrión"** con su foto de perfil (real, no placeholder).
   - **Reseñas** con foto del reviewer.
   - Reglas, política de cancelación, mapa.
   - Botón "Reservar" sticky al fondo.

### 2.4 Favoritos
1. En un listing → tap el **♡** arriba a la derecha.
2. **Esperado:** Se llena de lime + snackbar.
3. Ve a Perfil → Favoritos.
4. **Esperado:** Aparece la publicación. Tap → vuelves al detalle.
5. Toggle off → debe desaparecer de favoritos.

## 2.5 BOOKING (pago real con tarjeta de prueba)

### 2.5.1 Iniciar checkout
1. En listing detail → tap **"Reservar"**.
2. Selecciona fechas / unidades / huéspedes.
3. **Esperado:** Pantalla de checkout con desglose:
   - Precio base (host recibe el 100%)
   - Servicio Atrio (5% si host verificado con <5 reservas, 9% normal, mín $1.490 CLP)
   - Total
4. Tap **"Pagar"**.

### 2.5.2 Tarjeta MP de prueba (sandbox)
Usa cualquiera de estas en el checkout MP:
| Tarjeta | Número | CVV | Vencimiento | Resultado |
|---|---|---|---|---|
| Visa **aprobada** | `5031 7557 3453 0604` | `123` | `11/30` | Pago aprobado |
| Visa **rechazada** | `4509 9535 6623 3704` | `123` | `11/30` | Rechazo |
| Master **pendiente** | `5031 4332 1540 6351` | `123` | `11/30` | Pendiente |

Nombre titular: `APRO` (para forzar aprobado) o `OTHE` (rechazo).
RUT: `11.111.111-1` (cualquier formato válido).

### 2.5.3 Confirmación de pago
1. **Esperado:**
   - Pantalla `/booking-confirmed` con check verde + número de booking.
   - Notificación push (si tienes habilitadas).
   - Email de confirmación.

### 2.5.4 Verificar reserva creada
1. Bottom nav → **Mis Reservas**.
2. **Esperado:** Card con foto, fecha, status (Pendiente/Confirmada).
3. Tap la card → ves el detail con info completa.

## 2.6 Mensajería con anfitrión

### 2.6.1 Iniciar chat
1. Listing detail → tap **"Mensaje al anfitrión"** (o desde booking detail).
2. **Esperado:** Pantalla de chat. Header con foto real del anfitrión + nombre.
3. Escribe un mensaje → **enviar**.
4. **Esperado:** Burbuja del mensaje aparece a la derecha en lime.

### 2.6.2 Inbox
1. Bottom nav → **Mensajes**.
2. **Esperado:**
   - Chips horizontales arriba (Todas / Anfitriones / Huéspedes según rol).
   - Lista de conversaciones con foto + nombre + último mensaje + hora.

## 2.7 Reseñas

### 2.7.1 Dejar reseña
1. Después de una reserva completada → entra al booking detail.
2. Si está completada y no has reseñado → aparece botón **"Dejar reseña"**.
3. Califica con estrellas + comentario → **Enviar**.
4. **Esperado:** Snackbar de confirmación + tu reseña aparece en el listing.

### 2.7.2 Respuesta del host a tu reseña
1. Espera a que el host responda (parte 3).
2. Vuelve a las reseñas del listing.
3. **Esperado:** Tu reseña tiene la respuesta del host abajo con su nombre + foto.

## 2.8 Perfil del usuario

### 2.8.1 Editar perfil
1. Profile → tap "Editar perfil".
2. **Verifica que TODO está traducido** si cambias el idioma (titulos, secciones, tags de intereses).
3. Cambia foto, bio, intereses.
4. **Esperado:** Tap "Guardar" → snackbar + cambios persistidos.

### 2.8.2 Tu información (cancelaciones / confiabilidad)
1. Profile → "Tu información".
2. **Esperado:** Stats con cancelaciones, reservas, rating.
3. Cambia idioma → debe traducirse todo.

### 2.8.3 Favoritos
Cubierto en 2.4.

### 2.8.4 Métodos de pago
1. Profile → "Métodos de pago".
2. **Esperado:** Todo en español O en inglés según locale.
3. Verifica: badges TEST/INSTANT, Mercado Pago row, How it works (4 pasos), Security note, Support card.

### 2.8.5 Notificaciones
1. Profile → "Notificaciones".
2. **Esperado:** Toggles para tipos de noti. Verifica que se persisten en SharedPreferences.

### 2.8.6 Configuración (Settings)
1. Profile → "Configuración".
2. **Esperado:**
   - Sección Notificaciones, Privacidad, General (idioma), Cuenta.
   - **NO** debe haber botón "Eliminar cuenta" aquí (movido).
   - Solo debe haber: cambiar contraseña.

### 2.8.7 Cambio de idioma
1. Settings → General → Idioma → Selecciona inglés.
2. **Esperado:** TODA la app cambia a inglés. Cierra y abre — persiste.

### 2.8.8 ELIMINAR CUENTA (⚠️ destructivo)
*Solo si quieres realmente borrar una cuenta de prueba.*

1. Profile → scroll al fondo → tap **"Eliminar cuenta"** (rojo, subrayado).
2. **Esperado:** Pantalla de encuesta con 7 razones:
   - No me sirve
   - Es caro
   - Encontré otra app
   - No tengo tiempo
   - Privacidad
   - Errores / bugs
   - Otro (con campo de texto)
3. Selecciona una razón → **Confirmar**.
4. **Esperado:** Dialog de doble confirmación → "Sí, eliminar".
5. **Esperado:** Logout + cuenta borrada en `auth.users` + tablas relacionadas (cascade).

---

# 🧪 PARTE 3 — MODO HOST (ANFITRIÓN)

## 3.1 Switch a modo Host
1. Profile → tap el switcher **Guest ↔ Host** arriba.
2. **Esperado:** Bottom nav cambia a: Dashboard / Calendar / Listings / Métricas / Profile.
3. Background pasa a oscuro (theme host).

## 3.2 Dashboard
1. Tap **Dashboard**.
2. **Esperado:**
   - Saludo + foto.
   - Cards de stats (Reservas, Ingresos, Mensajes nuevos).
   - Acciones rápidas (Nueva publicación, Ver calendario).

## 3.3 KYC (Verificación de identidad)
1. Si es la primera vez como host → CTA "Verifica tu identidad".
2. Ruta `/identity-verification`.
3. Sube foto del CI/pasaporte (frente + dorso).
4. Selfie con documento.
5. **Esperado:** Estado pasa a "Pendiente revisión".
6. Admins reciben notificación automática (trigger en migración 031).

## 3.4 CALENDARIO (acabado de rediseñar)

### 3.4.1 Empty state
1. Si no tienes publicaciones → CTA "Crear mi primer anuncio".

### 3.4.2 Layout
1. Con al menos 1 listing → **Esperado:**
   - **Header:** "Calendario" / "Calendar" + pill lime "Hoy" arriba derecha.
   - **Listing pills** horizontales (white-on-selected).
   - **Month nav:** chevron izq + "Junio 2026" + chevron der.
   - **Mode toggle:** pill compacto Día/Rango.
   - **Day headers:** LU MA MI JU VI SA DO en tipografía sutil.
   - **Grid** ocupa ~60% del viewport.

### 3.4.3 Funcionalidad
1. Tap chevron → cambia mes, recarga datos.
2. Tap "Hoy" → vuelve al mes actual + selecciona hoy.
3. Tap un listing pill → cambia datos del calendario.
4. **Modo Día:**
   - Tap un día disponible → se llena de lime + aparece action card abajo con título, dot lime + "Disponible", botón **"Bloquear"** rojo.
   - Tap el mismo día → se deselecciona (action card colapsa).
   - Tap día reservado → action card muestra "Reservado" + botón **"Ver detalles"**.
   - Tap día bloqueado → muestra "Bloqueado" + botón **"Desbloquear"** lime.
5. **Modo Rango:**
   - Tap "Rango" en el toggle → hint card "Selecciona la fecha inicial".
   - Tap fecha 1 → cambia a "Selecciona la fecha final".
   - Tap fecha 2 → se llena el rango con lime tint + action card muestra rango + N días + botones **Bloquear** / **Desbloquear**.
   - Tap **X** en action card → cancela selección.
6. **Long-press cualquier día** → bottom sheet con título + status + acción primaria.
7. Si intentas bloquear un día con reserva → snackbar de error "No puedes bloquear...".

### 3.4.4 Estados visuales de cada celda
- **Hoy:** ring lime alrededor del número.
- **Reservado:** fondo verde tenue + texto verde claro (sin punto extra abajo).
- **Bloqueado:** fondo rojo tenue + texto rojo claro.
- **Seleccionado:** fondo lime sólido + texto negro.
- **En rango (no endpoint):** fondo lime 16% + texto lime.
- **Pasado:** texto blanco 22% (no tappable).

### 3.4.5 Verifica que el calendario llega hasta abajo
- Última semana visible (29/30/31).
- Action card NO empuja el grid hacia arriba si está colapsada.

## 3.5 LISTINGS (Publicaciones)

### 3.5.1 Lista de listings
1. Bottom nav → **Listings**.
2. **Esperado:**
   - Header con stats (Published / Drafts / Paused).
   - Cards de cada publicación con foto, título, status badge, precio.
   - Hint "Tap the ··· menu to manage".
   - Cada card tiene un botón **···** visible arriba a la derecha.

### 3.5.2 Crear nueva publicación
1. Tap **+** o "Crear publicación".
2. Tipo: Espacio / Experiencia / Servicio.
3. Completa wizard (info, fotos, precio, ubicación, reglas).
4. Tap "Publicar".
5. **Esperado:** Aparece en la lista.

### 3.5.3 Editar publicación
1. Tap el **···** de una card.
2. **Esperado:** Bottom sheet con 4 opciones:
   - **Ver publicación** (lleva al listing detail)
   - **Editar publicación**
   - **Pausar publicación** (o Publicar si está pausada)
   - **Eliminar publicación**
3. **Verifica:** La opción "Eliminar publicación" **NO** está cortada por la nav bar inferior.
4. Tap "Editar" → bottom sheet con formulario → guarda → ves snackbar.

### 3.5.4 Pausar / publicar
1. Tap "Pausar publicación" → status cambia a "Paused".
2. Tap "···" otra vez → ahora dice "Publicar publicación" → vuelve a activa.

### 3.5.5 Eliminar publicación
1. Tap "Eliminar publicación" → dialog de confirmación.
2. Confirma → publicación desaparece (soft delete en DB).

## 3.6 QUICK SERVICES (Servicios rápidos)

### 3.6.1 Crear servicio rápido
1. Bottom nav → Listings → tap "Quick Services" o similar.
2. Publish service screen → foto + título + precio.
3. **Esperado:** Aparece en el feed de servicios.

### 3.6.2 Owner menu en service detail
1. Como dueño del servicio → ve a tu servicio.
2. Tap **···**.
3. **Esperado:** Bottom sheet con Edit / Delete sin estar cortado por la nav bar.

## 3.7 RESERVAS ENTRANTES (vista host)

### 3.7.1 Confirmar / rechazar reserva
1. Cuando un guest reserva tu listing → recibes notificación.
2. Dashboard / Bookings → ves la reserva pendiente.
3. Tap → opciones: **Confirmar** o **Rechazar**.
4. **Esperado:** Status cambia + guest recibe noti.

### 3.7.2 Responder reseñas
1. Cuando un guest deja reseña en tu listing → te llega noti.
2. Reviews de tu listing → ves la reseña.
3. Tap **"Responder"** → modal con campo de texto.
4. Envía respuesta.
5. **Esperado:** Aparece tu respuesta debajo de la reseña, con tu foto.
6. Si ya respondiste, **NO** ves el botón "Responder" otra vez.

## 3.8 WALLET / Cobros

### 3.8.1 Wallet
1. Bottom nav (en host) → buscar **Wallet** o Profile → Cobros.
2. **Esperado:**
   - Saldo total.
   - Lista de transacciones.
   - Botón "Retirar" (si saldo > 0).

### 3.8.2 MP Marketplace OAuth
1. Profile (host) → tap **"Cobros (Mercado Pago)"**.
2. Si NO tienes cuenta conectada → CTA "Conectar Mercado Pago".
3. Tap → te abre WebView de MP OAuth.
4. **Esperado (cuando tengas credentials reales):** Después del consent vuelve a `/host/payment-connect` con status "Conectado".
5. *NOTA: Esto requiere `MP_CLIENT_ID` y `MP_CLIENT_SECRET` en EasyPanel — actualmente queda implementado pero pendiente de credenciales.*

## 3.9 MÉTRICAS / Insights

1. Bottom nav (host) → **Métricas** / **Insights** (según idioma).
2. **Esperado:**
   - Stats agregados por mes (reservas, ingresos, ocupación).
   - Gráficos.
   - Filtros por listing.
3. **Verifica:** Solo aparecen datos del usuario logueado (user-scoped).

---

# 🧪 PARTE 4 — NOTIFICACIONES PUSH

## 4.1 Permisos
1. Primera vez como host → diálogo "¿Permitir notificaciones?".
2. Acepta.
3. Verifica en sistema → Settings de Android → Atrio → Notificaciones está ON.

## 4.2 Trigger de noti
- **Guest:** llega cuando host confirma/rechaza tu reserva, llega mensaje nuevo, llega respuesta a reseña.
- **Host:** llega cuando hay nueva reserva, mensaje nuevo, KYC aprobado.
- **Admin:** llega cuando hay nuevo KYC pendiente (trigger en migración 031).

## 4.3 Tap en noti
1. Recibe una noti (pídele a un amigo que envíe mensaje, o haz acción cross-account).
2. Tap la noti.
3. **Esperado:** Abre la app en la pantalla correcta (chat, booking detail, etc.) vía deep link.

---

# 🧪 PARTE 5 — ADMIN (si tu cuenta es admin)

> Tu cuenta `paez.r.emiliano@gmail.com` es admin (set en migración 032).

## 5.1 Acceso al panel
1. Profile → busca **"KYC Pendientes"** o **"Admin Dashboard"**.
2. Tap → entra a `/admin/kyc`.
3. **Esperado:** Lista de KYCs pendientes (NO "Acceso restringido").

## 5.2 Revisar KYC
1. Tap un usuario pendiente.
2. **Esperado:** Ves docs subidos + selfie.
3. Botones **Aprobar** / **Rechazar**.
4. Aprueba → user recibe noti + KYC status pasa a `approved`.

---

# 🧪 PARTE 6 — EDGE CASES Y NEGATIVOS

## 6.1 Sin conexión
1. Activa modo avión.
2. Intenta cargar home / search.
3. **Esperado:** Banner offline arriba + datos cacheados si los hay.

## 6.2 Sesión expirada
1. Estando logueado → invalida la sesión desde Supabase Studio.
2. Refresca pantalla.
3. **Esperado:** Te lleva al login.

## 6.3 Listing eliminado mientras estás en él
1. Abre un listing.
2. Pide a otro device (admin/host) que lo elimine.
3. Vuelve a la pantalla / refresca.
4. **Esperado:** Mensaje "Esta publicación ya no está disponible".

## 6.4 Mensajes — buscador
1. Inbox → barra de búsqueda → escribe nombre.
2. **Esperado:** Filtra conversaciones en tiempo real.

## 6.5 Calendario con muchos meses (carga cross-month)
1. Navega 6+ meses hacia adelante.
2. Vuelve atrás.
3. **Esperado:** Datos correctos por mes, sin mostrar datos viejos.

---

# 🧪 PARTE 7 — APARIENCIA Y POLISH

## 7.1 Light/Dark
- App siempre es dark theme (es producto-specific). Verifica que no hay flashes blancos al cambiar de pantalla.

## 7.2 Bottom sheets
- Todos abren con el lime drag handle.
- Cierran con swipe down o tap fuera.
- NO se cortan por la nav bar (gracias al fix `useRootNavigator: true`).

## 7.3 Snackbars
- Todos son **pill negro con dot lime** (estilo editorial — el lime cuadrado anterior NO debe aparecer en ningún lugar).

## 7.4 Tipografía
- Inter en toda la app, letterSpacing negativo en headers grandes.

## 7.5 Lime usage
- Lime aparece SOLO como acento: CTAs primarios, today ring, selected state, pill Today.
- Texto secundario en blanco/gris, nunca lime.

---

# 🐛 Si algo falla — log capture

Con la app conectada por ADB:

```powershell
$env:Path += ';C:\Users\X1404ZA\AppData\Local\Android\Sdk\platform-tools'
adb -s adb-A56UVB5905004349-A6Mrll._adb-tls-connect._tcp logcat -d *:E flutter:V > atrio_log.txt
```

Mándame el `atrio_log.txt` y te diagnostico.

---

# ✅ Resultado esperado al final

Si todos los puntos pasan → la app está lista para usuarios beta reales.

Si algo falla → anótalo aquí y dímelo:

| # | Sección | Qué falló | Pasos para reproducir |
|---|---|---|---|
|   |   |   |   |
|   |   |   |   |
