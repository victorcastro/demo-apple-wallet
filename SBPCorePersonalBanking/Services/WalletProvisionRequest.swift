//
//  WalletProvisionRequest.swift
//  SBPCorePersonalBanking (framework estático)
//
//  Servicio `POST /provision` (devuelve el `encCard` de una tarjeta concreta) y
//  su DTO de respuesta. Se ejecuta con `CoreRequestManager.shared.load(...)`.
//

import Foundation

public struct WalletProvisionResponse: Codable {
    public let cardID: String
    public let encCard: String
}

/// `POST /provision` — devuelve el `encCard` de una tarjeta concreta.
public struct WalletProvisionRequest: SBPNetworking.Request {
    public typealias Response = WalletProvisionResponse
    public let path: String
    public let method: HTTPMethod
    public let body: Data?

    public init(cardID: String) {
        path = "/provision"
        method = .post
        body = try? JSONEncoder().encode(["cardID": cardID])
    }
}
