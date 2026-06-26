# Mock HTTP de HST (Mockoon)

Servidor HTTP simulado que imita el backend de HST mientras no se tiene acceso al
real (que solo funciona en producción). Devuelve las tarjetas con la estructura
de HST, incluido el `encCard`.

## Importar y arrancar

1. Abre **Mockoon** (app de escritorio) → **Open environment** → elige
   `SBPDemo-AppleWallet-mockoon.json`.
2. Pulsa **Start** (▶). El servidor queda en `http://localhost:5001`.

## Endpoints

### `POST http://localhost:5001/login`
Valida el login del usuario. El caso correcto devuelve `cookieJoy`; el caso por
defecto responde `401` con `error`.

```bash
curl -X POST http://localhost:5001/login \
  -H "Content-Type: application/json" \
  -d '{"dni":"12345678","password":"1234"}'
# -> { "cookieJoy": "joy-cookie-..." }
```

### `GET http://localhost:5001/cards-wallet`
Lista de tarjetas del usuario (sincronización). Es el caso típico: la app pide
esta lista y **guarda el `encCard` en Core Data**. Puedes pedir variantes con
`?count=1`, `?count=2`, `?count=3` o `?count=5`. Si no envías `count`, el
mock devuelve 3 tarjetas.

```json
[
  {
    "cardHolderName": "Victor Castro",
    "cardID": "card-visa-001",
    "cardImageBase64": "iVBORw0KGgo...",
    "cardType": "credit",
    "encCard": "eyJlbmNyeXB0ZWRQYXNzRGF0YSI6...",
    "lastFourDigits": "4821",
    "localizedDescription": "SBP Visa Signature",
    "paymentNetwork": "Visa"
  }
]
```

### `POST http://localhost:5001/provision`
Devuelve el `encCard` de una tarjeta concreta (caso: pedirlo al provisionar).
Usa reglas por `cardID` del body; si no existe, responde `404`.

```bash
curl -X POST http://localhost:5001/provision \
  -H "Content-Type: application/json" \
  -d '{"cardID":"card-visa-001"}'
# -> { "cardID": "card-visa-001", "encCard": "eyJ..." }
```

## Formato del `encCard` (provisional)

En este mock, `encCard` es **Base64( JSON )** con los 3 datos que Apple necesita,
cada uno en Base64:

```
encCard = base64({
  "encryptedPassData":  "<base64>",
  "activationData":     "<base64>",
  "ephemeralPublicKey": "<base64>"
})
```

Coincide con `ProvisioningService.unpack(_:)` de la app. ⚠️ Cuando se integre HST
real, ajustar este formato (y `unpack` / `placeholderEncCard`) al suyo.

> `cardImageBase64` aquí es un PNG 1×1 de relleno; HST envía el arte real.

## Nota para consumirlo desde la app (iOS ATS)

Para llamar a `http://localhost:5001` (HTTP en claro) desde la app, añade en su
`Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

(Solo para desarrollo. Con HST real será HTTPS y no hace falta.)
