//
//  BankCard.swift
//  SBPPersonalBanking
//
//  Modelo de uso (struct) que refleja la estructura de tarjeta que pide HST.
//  Sirve como "valor" cómodo de pasar por la app; el mapeo con el modelo del
//  SDK (`CardDataModel`) vive en `WalletSDK.swift`.
//

import Foundation
import PassKit

struct BankCard: Identifiable, Equatable, Codable {

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
