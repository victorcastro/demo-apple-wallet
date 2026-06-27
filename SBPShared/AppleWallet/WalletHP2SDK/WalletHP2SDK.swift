//
//  WalletHP2SDK.swift
//  DemoAppleWallet (Shared)
//
//  Punto único de acceso al SDK del emisor (HP2AppleSDK). Tanto la app como la
//  extensión de aprovisionamiento crean su propia instancia de `HP2` (corren en
//  procesos distintos) pero apuntando al MISMO App Group, de modo que comparten
//  el almacén de tarjetas (Core Data `CardExtensionData`) que el SDK gestiona.
//
//  El SDK reemplaza la tubería custom previa (criptografía, round-trip al PNO y
//  Core Data propio): aquí solo lo configuramos. El mapeo entre `WalletCard`
//  (modelo de la UI) y `CardDataModel` (modelo del SDK) vive en
//  `WalletCard+CardDataModel.swift`.
//

import Foundation
import HP2AppleSDK

enum WalletHP2SDK {

    // TODO: reemplazar por el código real que entregue HST.
    static let institutionCode = "INST-CODE"

    /// Instancia compartida del SDK, ligada al App Group de la demo.
    static let shared = HP2(institutionCode: institutionCode, groupID: AppGroup.identifier)
}
