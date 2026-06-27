# SBPPersonalBanking

Demo de Apple Wallet **issuer provisioning**: agregar tarjetas del emisor a Wallet,
tanto desde la app (`PKAddPaymentPassViewController`) como desde Wallet mismo
(extensiones). El trabajo pesado (cripto + red al issuer) lo hace el SDK del
proveedor **HST/HP2**.

> **HST** es el proveedor; **HP2** es su SDK.

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
  `WalletHP2SDK.shared = HP2(institutionCode:groupID:)` (`SBPShared/Wallet/HP2/WalletHP2SDK.swift`).

## Flujo de datos

1. **Login app** → `POST /login` (Mockoon).
2. **Sync catálogo** → `CardsViewModel.sync()` hace `GET /cards-wallet`, mapea a
   `CardDataModel` y siembra el store del SDK con `hp2.updateDataBase(cardDataList:)`.
   Cada tarjeta trae su `encCard` (paquete cifrado del issuer).
3. **Listar UI** → `WalletCardRepository` lee vía el `WalletEngine` activo
   (`engine.cards()`), que en device envuelve `hp2.getCardsFromCoreData()` y mapea a
   `WalletCard`. `isProvisioned` lo deriva el engine de `hp2.isAvailableForCard(panRefId:)`,
   no se guarda.
4. **Agregar a Wallet (in-app)** → `WalletProvisioningManager` llama
   `hp2.executeProvisioningOfEncryptedCard(...)`: el SDK presenta el sheet de Apple
   Pay, hace el round-trip al issuer con el `encCard` y arma el `PKAddPaymentPassRequest`.
5. **Descubrimiento desde Wallet (extensión)** → `ProvisioningHandler` delega:
   `status/passEntries/remotePassEntries` → SDK; y `generateAddPaymentPassRequest`
   → `hp2.getAddPaymentPassRequest(...)`.

> El paso de provisioning (antes el mock `POST /provision`) ahora vive dentro del
> SDK, que llama al issuer **real** de HST (endpoint en `BuildConfig`, según el
> build PROD/HOMOLOG del xcframework). Mockoon ya solo sirve `/login` y `/cards-wallet`.

## Mock vs SDK real

El SDK de HST no soporta mocks ni corre en simulador, así que todas sus operaciones
están detrás del protocolo `WalletEngineProtocol`
(`SBPShared/Wallet/WalletEngineProtocol.swift`) con dos backends —
`MockWalletEngine` y `HSTWalletEngine`— y un switch **en compilación**:

```swift
// SBPShared/Wallet/WalletEngineProtocol.swift
public enum WalletEngineProvider {
    #if USE_MOCK_WALLET || targetEnvironment(simulator)
    public static let current = MockWalletEngine()   // simulador
    #else
    public static let current = HSTWalletEngine()    // device, SDK real
    #endif
}
```

- **Simulador** → `MockWalletEngine`: store en `UserDefaults` (App Group), arma
  `PKAddPaymentPassRequest`/pass-entries de relleno y simula el alta con un alert.
  Las tarjetas igual se siembran desde Mockoon (`/cards-wallet`).
- **Device** → `HSTWalletEngine`: envuelve el SDK real. Para forzar mock en device,
  añade `USE_MOCK_WALLET` en *Active Compilation Conditions*.

Todos los consumidores (`WalletCardRepository`, `WalletProvisioningManager`,
`ProvisioningHandler`, `AppleWalletSandboxViewController`) pasan por
`WalletEngineProvider.current`, nunca por el SDK directo.

## Wiring de Xcode (importante)

- El SDK está **linked + embedded** solo en el target app.
- En ambas extensiones está **linked, Do Not Embed**: la app provee el binario y la
  extensión lo resuelve en runtime vía `@executable_path/../../Frameworks`.
- Los archivos de `SBPShared/` (`Wallet/` + `WalletCards/`) son miembros de app +
  extensiones, por eso compilan contra el mismo `WalletHP2SDK`/`WalletCardRepository`.

## Sandbox

`SBPPersonalBanking/Features/AppleWalletSandbox/AppleWalletSandboxViewController` ejercita los métodos de
la extensión (`status` / `passEntries` / auth / `generateAddPaymentPassRequest`) sin
pasar por Wallet, útil en simulador.

## Pendiente para producción

- `institutionCode` real de HST (hoy placeholder `"INST-CODE"` en
  `SBPShared/Wallet/HP2/WalletHP2SDK.swift`).
- Entitlement `com.apple.developer.payment-pass-provisioning` + relación con el PNO.
- Probar en **dispositivo físico**: el provisioning real y el store del SDK
  (necesita keychain) no funcionan en simulador.

## Cómo ejecutar

```bash
xcodebuild -scheme SBPPersonalBanking -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme SBPPersonalBanking -destination 'platform=iOS Simulator,name=iPhone 17' test
```

O abre `DemoAppleWallet.xcodeproj` en Xcode. Para el catálogo: Mockoon con
`mocks/SBPDemo-AppleWallet-mockoon.json` en `http://localhost:5001`.
