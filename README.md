# DemoAppleWallet

Demostración de **issuer provisioning** con Apple Wallet: agregar tarjetas de un
emisor a Wallet por los **dos caminos** que ofrece PassKit:

- **In-app** — desde la propia app, con el botón "Añadir a Wallet"
  (`PKAddPaymentPassViewController`).
- **Wallet** — desde la app Wallet (`+` → "Tarjeta de crédito o débito" →
  "Tarjetas de tus apps"), servido por dos extensiones de PassKit (non-UI +
  autorización).

En ambos caminos, la criptografía y la comunicación con el backend del emisor las
resuelve **HP2** (`HP2AppleSDK.xcframework`), el framework iOS del proveedor de
tokenización **HST**. La app nunca ve datos de tarjeta en claro ni habla con el
issuer directamente: **todo lo sensible ocurre dentro del SDK**.

Referencia Apple: https://applepaydemo.apple.com/in-app-provisioning-extensions

## Requisitos mínimos

| Herramienta | Versión |
|---|---|
| iOS | 26.0+ |
| Xcode | 26+ |
| Swift | 5.0 |
| Mockoon | cualquiera — importa `mocks/DemoWallet-mockoon.json` |

## Estructura del proyecto

Cinco targets propios: la app, dos app-extensions y dos frameworks de código
compartido.

```
DemoAppleWallet.xcodeproj
├─ SBPPersonalBanking            App (.app) — el AppTarget
│  └─ Features/                  Cards · Login · Menu · ProvisioningSandbox
├─ SBPProvisioningExtension      App Extension (.appex) — issuer-provisioning (SIN UI)
│  └─ ProvisioningHandler.swift  Wallet descubre tarjetas y pide el request de alta
├─ SBPProvisioningUIExtension    App Extension (.appex) — ...authorization (CON UI)
│  └─ AuthorizationViewController pantalla de auth que Wallet presenta
├─ SBPShared                     Framework — código común app + extensiones
│  ├─ AppleWallet/               WalletEngine · WalletCards · WalletHP2SDK · Utils
│  └─ Session/                   sesión / login (SessionStore, AuthenticationService)
├─ SBPCorePersonalBanking        Framework (dinámico) — Networking · Services
├─ Frameworks/                   HP2AppleSDK.xcframework + HttpClient.xcframework (SDK HST)
└─ mocks/                        config de Mockoon
```

Relaciones clave entre targets:

- **App (`SBPPersonalBanking`)** contiene y embebe a las dos extensiones y al SDK.
  Es el único que **embebe** el `HP2AppleSDK.xcframework`.
- **Extensiones** (`SBPProvisioningExtension`, `SBPProvisioningUIExtension`) son
  `.appex` independientes: proceso y sandbox propios, lanzados por Wallet, no por el
  usuario. Comparten el SDK y `SBPShared` con la app (ver *Wiring de Xcode*).
- **`SBPShared`** es el puente: sus fuentes son miembros de app **y** extensiones, de
  modo que los tres targets hablan con el mismo `WalletEngine` / `WalletHP2SDK`.
  Debe seguir siendo framework **dinámico** para poder compartirse.
- **`SBPCorePersonalBanking`** (framework dinámico) agrupa el networking y servicios
  de la app; no lo usan las extensiones.

## Configuración previa

Nada del provisioning real funciona sin esto en su sitio **antes** de correr la app
en un dispositivo:

1. **Entitlement de provisioning** — `com.apple.developer.payment-pass-provisioning`
   en la app y en las extensiones. Apple lo concede solo tras habilitar la relación
   con el **PNO** (Payment Network Operator) del programa.
2. **App Group** (`group.dev.victorcastro.SBPPersonalBanking`) — activado en app y en
   **ambas** extensiones. Es el contenedor compartido donde el SDK guarda su Core
   Data; sin él las extensiones no ven las tarjetas que sembró la app.
3. **`institutionCode` de HST** — el código de institución real en
   `SBPShared/AppleWallet/WalletHP2SDK/WalletHP2SDK.swift` (hoy placeholder
   `"INST-CODE"`). Identifica al emisor frente al backend de HST.
4. **SDK linkeado correctamente** (ver *Wiring de Xcode*): la app lo embebe; las
   extensiones lo comparten sin embeberlo.
5. **Dispositivo físico** — el provisioning real y el store del SDK (usa keychain) no
   corren en simulador. En simulador se usa el mock (ver *Mock vs SDK real*).
6. **Mockoon** sirviendo `mocks/DemoWallet-mockoon.json` en
   `http://localhost:5001` para el login y el catálogo de tarjetas.

## Piezas del sistema

- **App Extension** (`.appex`): un binario aparte, embebido en la app, con su propio
  proceso y sandbox. No lo lanza el usuario: lo lanza el sistema (Wallet). Hay dos,
  cada una atada a un *extension point* de PassKit:
  - `SBPProvisioningExtension` → `com.apple.PassKit.issuer-provisioning` (sin UI):
    subclase de `PKIssuerProvisioningExtensionHandler`. Wallet le pregunta qué
    tarjetas hay y le pide el request final de alta.
  - `SBPProvisioningUIExtension` → `...issuer-provisioning.authorization` (con UI):
    implementa `PKIssuerProvisioningExtensionAuthorizationProviding`. Es la pantalla
    de autenticación que Wallet presenta antes de provisionar.
- **App Group** (`group.dev.victorcastro.SBPPersonalBanking`): contenedor compartido.
  Como app y extensiones son procesos/sandboxes distintos, es la única forma de que
  vean los mismos datos. El SDK guarda ahí su Core Data.
- **SDK HST/HP2** (`Frameworks/HP2AppleSDK.xcframework` + `HttpClient.xcframework`):
  dueño del almacén de tarjetas (entidad Core Data `CardExtensionData` en el App
  Group) y de la comunicación con el backend del issuer. Punto de acceso único:
  `WalletHP2SDK.shared = HP2(institutionCode:groupID:)`
  (`SBPShared/AppleWallet/WalletHP2SDK/WalletHP2SDK.swift`).

## Cómo funciona (visión general)

La app solo hace dos cosas de negocio propias: **autenticar** al usuario y
**sembrar el catálogo** de tarjetas del emisor. A partir de ahí, cada tarjeta lleva
un `encCard` (paquete cifrado del issuer) y **HST/HP2 toma el control** de todo lo
que sea criptografía o alta en Wallet.

**Paso 0 — común a los dos flujos (la app):**

1. **Login** → `POST /login` (Mockoon).
2. **Sync del catálogo** → `CardsViewModel.sync()` hace `GET /cards-wallet`, mapea a
   `CardDataModel` y siembra el store del SDK con `hp2.updateDataBase(cardDataList:)`.
   Cada tarjeta trae su `encCard`.
3. **Listado en UI** → `WalletCardRepository` lee vía el engine activo
   (`engine.cards()` → `hp2.getCardsFromCoreData()`). El flag `isProvisioned` se
   deriva de `hp2.isAvailableForCard(panRefId:)`, no se persiste.

> **Dónde entra HST:** desde el paso 2. La app pide el catálogo a su backend
> (Mockoon aquí), pero **el `encCard` de cada tarjeta lo generó el issuer real** y el
> SDK es quien lo custodia y lo usa. En el alta, el SDK hace el round-trip contra el
> issuer real de HST (endpoint en `BuildConfig`, según el build PROD/HOMOLOG del
> xcframework). Mockoon solo sirve `/login` y `/cards-wallet`.

Con el catálogo ya sembrado, el usuario puede tomar cualquiera de los dos caminos:

### Flujo A — In-app (desde la app)

El usuario pulsa "Añadir a Wallet" sobre una tarjeta de la lista.

1. `WalletProvisioningManager.canAddPayments` comprueba
   `PKAddPaymentPassViewController.canAddPaymentPass()` (elegibilidad del
   dispositivo/cuenta).
2. `WalletProvisioningManager.startProvisioning(for:from:)` delega en el engine
   (`startInAppProvisioning`).
3. **→ HST:** el SDK llama `hp2.executeProvisioningOfEncryptedCard(...)`, que:
   - presenta el **sheet nativo de Apple Pay**,
   - hace el round-trip al issuer con el `encCard`,
   - arma el `PKAddPaymentPassRequest` y completa el alta.
4. El resultado vuelve como `ProvisioningOutcome`
   (`added` / `cancelled` / `failed` / `unsupported`) y la UI refresca el estado.

### Flujo B — Wallet (desde la app Wallet, vía extensión)

Aquí quien conduce es **Wallet**, que llama a la extensión non-UI
(`ProvisioningHandler`). El usuario nunca abre nuestra app.

1. **`status()`** → Wallet pregunta disponibilidad y si requiere autenticación
   (`walletEngine.provisioningStatus()`).
2. **`passEntries()` / `remotePassEntries()`** → la extensión devuelve el catálogo de
   tarjetas ofrecibles (iPhone y Apple Watch). Son metadatos, **sin datos cifrados**.
3. **Autorización** → si `status` lo pide, Wallet presenta la extensión con UI
   (`SBPProvisioningUIExtension`) para validar al usuario (login / biometría).
4. **`generateAddPaymentPassRequestForPassEntryWithIdentifier(...)`** → Wallet entrega
   material criptográfico de Apple (cadena de certificados, `nonce`, `nonceSignature`)
   y pide el request final.
   **→ HST:** el engine llama `hp2.getAddPaymentPassRequest(...)`, que combina ese
   material con el `encCard` de la tarjeta y devuelve el `PKAddPaymentPassRequest`
   cifrado que Wallet mete en el Secure Element.

> Las extensiones delegan **siempre** en `WalletEngineProvider.current`
> (`ProvisioningHandler` no toca el SDK directamente), igual que la app.

## Mock vs SDK real

El SDK de HST no soporta mocks ni corre en simulador, así que todas sus operaciones
están detrás del protocolo `WalletEngineProtocol`
(`SBPShared/AppleWallet/WalletEngine/WalletEngineProtocol.swift`) con dos backends —
`MockWalletEngine` y `HSTWalletEngine`— y un switch **en compilación**:

```swift
// SBPShared/AppleWallet/WalletEngine/WalletEngineProtocol.swift
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
`ProvisioningHandler`, `ProvisioningSandboxViewController`) pasan por
`WalletEngineProvider.current`, nunca por el SDK directo.

## Wiring de Xcode (importante)

- El SDK está **linked + embedded** solo en el target app.
- En ambas extensiones está **linked, Do Not Embed**: la app provee el binario y la
  extensión lo resuelve en runtime vía `@executable_path/../../Frameworks`.
- Los archivos de `SBPShared/AppleWallet/` (`WalletEngine/`, `WalletCards/`,
  `WalletHP2SDK/`) son miembros de app + extensiones, por eso compilan contra el
  mismo `WalletHP2SDK`/`WalletCardRepository`.

## Sandbox

`SBPPersonalBanking/Features/ProvisioningSandbox/ProvisioningSandboxViewController`
ejercita cada paso de los dos flujos de forma aislada, con un segmentado que separa
**In-app** (disponibilidad del dispositivo / estado de la tarjeta / sheet de Apple
Pay) y **Wallet** (`status` / `passEntries` / auth / `generateAddPaymentPassRequest`),
sin pasar por Wallet. Todo pasa por `WalletEngineProvider.current`, así que funciona
en simulador.

## Pendiente para producción

- `institutionCode` real de HST (placeholder `"INST-CODE"` en
  `SBPShared/AppleWallet/WalletHP2SDK/WalletHP2SDK.swift`).
- Entitlement `com.apple.developer.payment-pass-provisioning` + relación con el PNO.
- Probar en **dispositivo físico**: el provisioning real y el store del SDK
  (necesita keychain) no funcionan en simulador.

## Cómo ejecutar

```bash
xcodebuild -scheme SBPPersonalBanking -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme SBPPersonalBanking -destination 'platform=iOS Simulator,name=iPhone 17' test
```

O abre `DemoAppleWallet.xcodeproj` en Xcode. Para el catálogo: Mockoon con
`mocks/DemoWallet-mockoon.json` en `http://localhost:5001`.
