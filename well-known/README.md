# Universal Links / Android App Links

Contenido de `https://atrio.app/.well-known/` para que el sistema operativo
verifique que la app puede manejar deep links a `atrio.app`.

## Archivos

| Archivo | Plataforma | URL final pública |
|---|---|---|
| `assetlinks.json` | Android | `https://atrio.app/.well-known/assetlinks.json` |
| `apple-app-site-association` | iOS | `https://atrio.app/.well-known/apple-app-site-association` |

> ⚠️ **`apple-app-site-association` no lleva extensión `.json`**. Servirlo con
> `Content-Type: application/json` y sin `Content-Encoding: gzip`.

## Antes de subirlos a producción

### 1️⃣ iOS — completar el Team ID

El archivo `apple-app-site-association` tiene un placeholder:

```
"appIDs": [ "TEAMID.com.atrio.atrio" ]
```

Reemplaza `TEAMID` con tu Apple Developer Team ID (10 caracteres alfanuméricos).
Encuéntralo en https://developer.apple.com/account → Membership.

### 2️⃣ Android — agregar el fingerprint de Play App Signing (cuando subas)

`assetlinks.json` ya incluye los SHA-256 del keystore release local y del
debug. Pero **Google Play re-firma los APK con su propia clave** cuando usas
App Signing. Esa clave tiene otro SHA-256 que solo aparece tras subir la
primera build a Play Console:

  Play Console → tu app → Setup → App integrity → App signing key certificate

Copia el `SHA-256 certificate fingerprint` que aparece ahí y agrégalo al
array `sha256_cert_fingerprints` (mantén los otros también — múltiples
fingerprints en el mismo array es válido y necesario para que tanto las
builds de Play Store como sideloads firmados con tu llave funcionen).

## Deploy

Esta carpeta debe servirse en `/.well-known/` del dominio raíz `atrio.app`,
con HTTPS válido. Ejemplos:

| Hosting | Cómo |
|---|---|
| **Vercel / Netlify** | Coloca esta carpeta como `public/.well-known/` en tu site. Vercel sirve `apple-app-site-association` con el MIME correcto automáticamente. |
| **Nginx / Caddy** | `root /var/www/atrio.app;` y asegúrate de tener una regla `location /.well-known/apple-app-site-association { default_type application/json; }` |
| **Cloudflare Pages** | Igual que Vercel: carpeta `public/.well-known/`. |
| **GitHub Pages** | Subir como `/.well-known/*` en la branch que sirve el sitio. |

### Verificar después del deploy

**Android**:
```bash
curl -s https://atrio.app/.well-known/assetlinks.json | jq
```
Debe responder 200 con el JSON. Luego prueba en un dispositivo con la app
instalada:
```bash
adb shell pm verify-app-links --re-verify com.atrio.atrio
adb shell pm get-app-links com.atrio.atrio
```
El estado debe pasar de `legacy_unknown` a `verified`.

**iOS**:
```bash
curl -i https://atrio.app/.well-known/apple-app-site-association
```
Debe responder 200 con `Content-Type: application/json` (sin gzip). Luego
en el dispositivo:
- Borra la app
- Re-instálala (TestFlight o Xcode)
- Espera ~24h para la primera verificación, o fuérzala con `swcutil` desde
  un mac:
  ```bash
  sudo swcutil reset
  ```

## Si cambias de keystore

Si rotas el keystore en el futuro (`atrio-release.jks`), extrae el nuevo
SHA-256 con:
```bash
keytool -list -v -keystore atrio-release.jks -alias atrio | grep SHA256
```
y agrégalo al array (no elimines el viejo hasta que estés seguro de que
ningún usuario tiene la app firmada con la llave anterior).
