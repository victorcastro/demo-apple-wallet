# SBPPersonalBanking

Demo de Apple Wallet para **issuer provisioning**. El foco del proyecto son las
extensiones que Wallet invoca para descubrir tarjetas, pedir autorización y
construir el request final de provisioning.

Referencia de Apple:
https://applepaydemo.apple.com/in-app-provisioning-extensions

## Idea General

El proyecto gira alrededor de estas piezas:

- `SBPPersonalBanking`: la app demo y el sandbox para probar el flujo.
- `SBPProvisioningExtension`: la extensión sin UI que responde a Wallet.
- `SBPProvisioningUIExtension`: la extensión con UI para autenticar al usuario.
- `Shared/`: datos y lógica compartida entre la app y las extensiones.

Si nunca viste Apple Wallet antes, piensa el flujo así:

1. La app guarda tarjetas demo compartidas con las extensiones.
2. Wallet pregunta a la extensión si hay tarjetas disponibles.
3. Si hace falta validar al usuario, Wallet abre la extensión de UI.
4. La extensión sin UI genera el request final que Wallet necesita para agregar la tarjeta.

## Qué Hace Cada Extensión

### App principal

La app principal contiene:

- La lista de tarjetas.
- La vista de login.
- El sandbox para probar el flujo de Wallet sin usar Wallet real.
- El flujo estándar de agregar tarjeta con `PKAddPaymentPassViewController`.

### Extensión Non-UI

`SBPProvisioningExtension` responde a Wallet con:

- `status()`
- `passEntries()`
- `remotePassEntries()`
- `generateAddPaymentPassRequest`

Esta extensión decide qué tarjetas puede ver Wallet y prepara la solicitud final
de provisioning.

### Extensión UI

`SBPProvisioningUIExtension` muestra la pantalla de autorización previa al
provisioning. Acá vive el login con contraseña y biometría.

## Flujo De Datos

- La app sincroniza tarjetas demo y las persiste en el almacenamiento compartido.
- La extensión Non-UI lee las tarjetas que todavía no están en Wallet.
- La UI de autorización valida al usuario antes de continuar.
- El backend devuelve `encCard` y la extensión arma el request final para Wallet.

## Archivo Importante

`setup_targets.rb` es un helper de verificación para el wiring del proyecto.
Sirve para comprobar que el repo sigue teniendo los targets y carpetas esperadas.

## Sandbox

En la app hay una pantalla `SandboxViewController` para simular Wallet desde el
simulador o desde la app:

- `status()`
- `passEntries()`
- autorización
- generación del request final

## Estructura

- `SBPPersonalBanking/Features/Sandbox/`: pantalla para simular el flujo de Wallet.
- `SBPProvisioningExtension/`: lógica que Wallet consulta para descubrir tarjetas.
- `SBPProvisioningUIExtension/`: UI de autenticación previa al provisioning.
- `Shared/`: modelos y datos compartidos por app y extensiones.

## Requisitos Para Producción

Esto es demo. Para producción todavía faltan:

- Entitlement de Apple para issuer provisioning.
- Backend real de la red de pago.
- Pruebas en dispositivo físico.

## Cómo Ejecutar

```bash
xcodebuild -scheme SBPPersonalBanking \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -scheme SBPPersonalBanking \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

O abre `SBPPersonalBanking.xcodeproj` en Xcode y ejecuta la app.
