# SBPPersonalBanking

Demo de Apple Wallet **issuer provisioning**: agregar tarjetas del emisor a Wallet,
tanto desde la app (`PKAddPaymentPassViewController`) como desde Wallet mismo
(extensiones). El trabajo pesado (cripto + red al issuer) lo hace el SDK del
proveedor **HST/HP2**.

Referencia Apple: https://applepaydemo.apple.com/in-app-provisioning-extensions

## Conceptos nuevos (si vienes solo de apps normales)

- **App Extension** (`.appex`): un binario aparte, embebido dentro de la app, con
  su propio proceso y sandbox. No lo lanza el usuario: lo lanza el sistema (Wallet).
  Aquí hay dos, cada una atada a un *extension point* de PassKit:
  - `SBPProvisioningExtension` → `com.apple.PassKit.issuer-provisioning` (sin UI):
    subclase de `PKIssuerProvisioningExtensionHandler`. Wallet le pregunta qué
    tarjetas hay y le pide el request final.
  - `SBPProvisioningUIExtension` → `...issuer-provisioning.authorization` (con UI):
    implementa `PKIssuerProvisioningExtensionAuthorizationProviding`. Es la pantalla
    de auth que Wallet presenta antes de provisionar.
- **App Group** (`group.dev.victorcastro.SBPPersonalBanking`): contenedor compartido.
  Como app y extensiones son procesos/sandboxes distintos, es la única forma de que
  vean los mismos datos. El SDK guarda ahí su Core Data.
- **SDK HST/HP2** (`Frameworks/HP2AppleSDK.xcframework` + `HttpClient.xcframework`):
  dueño del almacén de tarjetas (entidad Core Data `CardExtensionData` en el App
  Group) y de la comunicación con el backend del issuer. Punto de acceso único:
  `WalletSDK.shared = HP2(institutionCode:groupID:)` (`Shared/WalletSDK.swift`).

## Flujo de datos

1. **Login app** → `POST /login` (Mockoon).
2. **Sync catálogo** → `CardsViewModel.sync()` hace `GET /cards-wallet`, mapea a
   `CardDataModel` y siembra el store del SDK con `hp2.updateDataBase(cardDataList:)`.
   Cada tarjeta trae su `encCard` (paquete cifrado del issuer).
3. **Listar UI** → `CardRepository` lee con `hp2.getCardsFromCoreData()`.
   `isProvisioned` se deriva de `hp2.isAvailableForCard(panRefId:)`, no se guarda.
4. **Agregar a Wallet (in-app)** → `WalletProvisioningManager` llama
   `hp2.executeProvisioningOfEncryptedCard(...)`: el SDK presenta el sheet de Apple
   Pay, hace el round-trip al issuer con el `encCard` y arma el `PKAddPaymentPassRequest`.
5. **Descubrimiento desde Wallet (extensión)** → `ProvisioningHandler` delega:
   `status/passEntries/remotePassEntries` → SDK; y `generateAddPaymentPassRequest`
   → `hp2.getAddPaymentPassRequest(...)`.

> El paso de provisioning (antes el mock `POST /provision`) ahora vive dentro del
> SDK, que llama al issuer **real** de HST (endpoint en `BuildConfig`, según el
> build PROD/HOMOLOG del xcframework). Mockoon ya solo sirve `/login` y `/cards-wallet`.

## Wiring de Xcode (importante)

- El SDK está **linked + embedded** solo en el target app.
- En ambas extensiones está **linked, Do Not Embed**: la app provee el binario y la
  extensión lo resuelve en runtime vía `@executable_path/../../Frameworks`.
- Los archivos de `Shared/` son miembros de app + extensiones, por eso compilan
  contra el mismo `WalletSDK`/`CardRepository`.

## Sandbox

`SBPPersonalBanking/Features/Sandbox/SandboxViewController` ejercita los métodos de
la extensión (`status` / `passEntries` / auth / `generateAddPaymentPassRequest`) sin
pasar por Wallet, útil en simulador.

## Pendiente para producción

- `institutionCode` real de HST (hoy placeholder `"INST-CODE"` en `WalletSDK.swift`).
- Entitlement `com.apple.developer.payment-pass-provisioning` + relación con el PNO.
- Probar en **dispositivo físico**: el provisioning real y el store del SDK
  (necesita keychain) no funcionan en simulador.

## Cómo ejecutar

```bash
xcodebuild -scheme SBPPersonalBanking -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme SBPPersonalBanking -destination 'platform=iOS Simulator,name=iPhone 17' test
```

O abre `SBPPersonalBanking.xcodeproj` en Xcode. Para el catálogo: Mockoon con
`mocks/SBPDemo-AppleWallet-mockoon.json` en `http://localhost:5001`.
