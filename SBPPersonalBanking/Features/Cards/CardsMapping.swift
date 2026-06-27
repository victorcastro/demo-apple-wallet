//
//  WalletCardDTO+WalletCard.swift
//  DemoAppleWallet
//
//  Mapeo del DTO de red (del framework SBPCorePersonalBanking) al modelo de la
//  app. Vive en el AppTarget porque `WalletCard` es del app, no del core.
//

import Foundation
import SBPCorePersonalBanking
import SBPShared

extension WalletCardDTO {
    func toWalletCard(isProvisioned: Bool = false) -> WalletCard {
        WalletCard(cardID: cardID,
                 cardHolderName: cardHolderName,
                 cardImageBase64: cardImageBase64,
                 cardType: cardType,
                 encCard: encCard,
                 lastFourDigits: lastFourDigits,
                 localizedDescription: localizedDescription,
                 paymentNetwork: paymentNetwork,
                 isProvisioned: isProvisioned)
    }
}
