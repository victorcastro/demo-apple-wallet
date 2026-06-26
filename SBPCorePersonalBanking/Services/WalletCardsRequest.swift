//
//  WalletCardsRequest.swift
//  SBPCorePersonalBanking (framework estático)
//
//  Servicio `GET /cards-wallet` (lista de tarjetas del usuario) y su DTO de respuesta.
//  Se ejecuta con `CoreRequestManager.shared.load(...)`.
//

import Foundation

public struct WalletCardDTO: Codable {
    public let cardHolderName: String
    public let cardID: String
    public let cardImageBase64: String
    public let cardType: String
    public let encCard: String
    public let lastFourDigits: String
    public let localizedDescription: String
    public let paymentNetwork: String
}

public struct WalletCardsRequest: SBPNetworking.Request {
    public typealias Response = [WalletCardDTO]
    public let path: String

    public init() {
        path = "/cards-wallet"
    }
}
