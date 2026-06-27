//
//  WalletCard.swift
//  DemoAppleWallet
//
//  Modelo de uso (struct) que refleja la estructura de tarjeta que pide HST.
//  Sirve como "valor" cómodo de pasar por la app; el mapeo con el modelo del
//  SDK (`CardDataModel`) vive en `WalletCard+CardDataModel.swift`.
//

import Foundation
import PassKit

public struct WalletCard: Identifiable, Equatable, Codable {

    public var cardID: String
    public var cardHolderName: String
    public var cardImageBase64: String
    public var cardType: String                // "credit" / "debit"
    public var encCard: String                 // paquete cifrado que entrega HST
    public var lastFourDigits: String
    public var localizedDescription: String
    public var paymentNetwork: String          // "Visa", "MasterCard", ...
    
    // Campo local para controlar el provisioning
    public var isProvisioned: Bool

    public init(cardID: String, cardHolderName: String, cardImageBase64: String,
                cardType: String, encCard: String, lastFourDigits: String,
                localizedDescription: String, paymentNetwork: String, isProvisioned: Bool) {
        self.cardID = cardID
        self.cardHolderName = cardHolderName
        self.cardImageBase64 = cardImageBase64
        self.cardType = cardType
        self.encCard = encCard
        self.lastFourDigits = lastFourDigits
        self.localizedDescription = localizedDescription
        self.paymentNetwork = paymentNetwork
        self.isProvisioned = isProvisioned
    }

    // MARK: - Derivados

    public var id: String { cardID }
    public var maskedNumber: String { "•••• \(lastFourDigits)" }

    /// Convierte el texto de la red de pago al tipo que usa PassKit.
    public var pkPaymentNetwork: PKPaymentNetwork {
        switch paymentNetwork.lowercased().replacingOccurrences(of: " ", with: "") {
        case "visa": return .visa
        case "mastercard": return .masterCard
        case "amex", "americanexpress": return .amex
        case "discover": return .discover
        default: return PKPaymentNetwork(paymentNetwork)
        }
    }
}
