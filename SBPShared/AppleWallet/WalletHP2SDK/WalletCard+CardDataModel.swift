//
//  WalletCard+CardDataModel.swift
//  DemoAppleWallet (Shared)
//
//  Mapeo entre el modelo de dominio `WalletCard` y el modelo del SDK HP2
//  (`CardDataModel`). Separado de `WalletHP2SDK.swift` para que ese archivo sea
//  solo el punto de instanciación del SDK.
//

import Foundation
import HP2AppleSDK

extension WalletCard {

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
