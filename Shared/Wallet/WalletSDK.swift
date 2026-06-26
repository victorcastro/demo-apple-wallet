//
//  WalletSDK.swift
//  SBPPersonalBanking (Shared)
//
//  Punto único de acceso al SDK del emisor (HP2AppleSDK). Tanto la app como la
//  extensión de aprovisionamiento crean su propia instancia de `HP2` (corren en
//  procesos distintos) pero apuntando al MISMO App Group, de modo que comparten
//  el almacén de tarjetas (Core Data `CardExtensionData`) que el SDK gestiona.
//
//  El SDK reemplaza la tubería custom previa (criptografía, round-trip al PNO y
//  Core Data propio): aquí solo lo configuramos y mapeamos entre `BankCard`
//  (modelo de la UI) y `CardDataModel` (modelo del SDK).
//

import Foundation
import HP2AppleSDK

enum WalletSDK {

    // TODO: reemplazar por el código real que entregue HST.
    /// Código de institución del emisor.
    static let institutionCode = "INST-CODE"

    /// Instancia compartida del SDK, ligada al App Group de la demo.
    static let shared = HP2(institutionCode: institutionCode,
                            groupID: AppGroup.identifier)
}

// MARK: - Mapeo BankCard <-> CardDataModel

extension BankCard {

    /// Crea el modelo de UI a partir del modelo del SDK. `isProvisioned` no vive
    /// en el SDK: lo deriva el repositorio vía `HP2.isAvailableForCard`.
    init(model: CardDataModel, isProvisioned: Bool) {
        self.init(
            cardID: model.cardID ?? "",
            cardHolderName: model.cardHolderName ?? "",
            cardImageBase64: model.cardImageBase64 ?? "",
            cardType: model.cardType ?? "",
            encCard: model.encCard ?? "",
            lastFourDigits: model.lastFourDigits ?? "",
            localizedDescription: model.localizedDescription ?? "",
            paymentNetwork: model.paymentNetwork ?? "",
            isProvisioned: isProvisioned
        )
    }

    /// Convierte la tarjeta al modelo que consume `HP2.updateDataBase`.
    var asCardDataModel: CardDataModel {
        CardDataModel(
            cardHolderName: cardHolderName,
            cardID: cardID,
            cardImageBase64: cardImageBase64,
            lastFourDigits: lastFourDigits,
            localizedDescription: localizedDescription,
            paymentNetwork: paymentNetwork,
            cardType: cardType,
            encCard: encCard
        )
    }
}
