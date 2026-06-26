//
//  BankCard.swift
//  SBPPersonalBanking
//
//  Modelo de uso (struct) que refleja la estructura de tarjeta que pide HST.
//  Sirve como "valor" cómodo de pasar por la app; se convierte a/desde
//  `WalletDataCardEntity` (Core Data) en el repositorio.
//

import Foundation
import PassKit

struct BankCard: Identifiable, Equatable {

    var cardID: String
    var cardHolderName: String
    var cardImageBase64: String
    var cardType: String                // "credit" / "debit"
    var encCard: String                 // paquete cifrado que entrega HST
    var lastFourDigits: String
    var localizedDescription: String
    var paymentNetwork: String          // "Visa", "MasterCard", ...
    
    // Campo local para controlar el provisioning
    var isProvisioned: Bool

    // MARK: - Derivados

    var id: String { cardID }
    var maskedNumber: String { "•••• \(lastFourDigits)" }

    /// Convierte el texto de la red de pago al tipo que usa PassKit.
    var pkPaymentNetwork: PKPaymentNetwork {
        switch paymentNetwork.lowercased().replacingOccurrences(of: " ", with: "") {
        case "visa": return .visa
        case "mastercard": return .masterCard
        case "amex", "americanexpress": return .amex
        case "discover": return .discover
        default: return PKPaymentNetwork(paymentNetwork)
        }
    }
}

// MARK: - Mapeo con Core Data

extension BankCard {

    /// Crea el struct a partir de la entidad de Core Data.
    init(entity: WalletDataCardEntity) {
        self.init(
            cardID: entity.cardID ?? "",
            cardHolderName: entity.cardHolderName ?? "",
            cardImageBase64: entity.cardImageBase64 ?? "",
            cardType: entity.cardType ?? "",
            encCard: entity.encCard ?? "",
            lastFourDigits: entity.lastFourDigits ?? "",
            localizedDescription: entity.localizedDescription ?? "",
            paymentNetwork: entity.paymentNetwork ?? "",
            isProvisioned: entity.isProvisioned
        )
    }

    /// Vuelca los valores del struct en una entidad de Core Data.
    func apply(to entity: WalletDataCardEntity) {
        entity.cardID = cardID
        entity.cardHolderName = cardHolderName
        entity.cardImageBase64 = cardImageBase64
        entity.cardType = cardType
        entity.encCard = encCard
        entity.lastFourDigits = lastFourDigits
        entity.localizedDescription = localizedDescription
        entity.paymentNetwork = paymentNetwork
        entity.isProvisioned = isProvisioned
    }
}
