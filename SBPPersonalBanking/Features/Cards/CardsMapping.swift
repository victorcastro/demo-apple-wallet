//
//  WalletCardDTO+BankCard.swift
//  SBPPersonalBanking
//
//  Mapeo del DTO de red (del framework SBPCorePersonalBanking) al modelo de la
//  app. Vive en el AppTarget porque `BankCard` es del app, no del core.
//

import Foundation
import SBPCorePersonalBanking

extension WalletCardDTO {
    func toBankCard(isProvisioned: Bool = false) -> BankCard {
        BankCard(cardID: cardID,
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
