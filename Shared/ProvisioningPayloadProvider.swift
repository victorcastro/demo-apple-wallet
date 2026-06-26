//
//  ProvisioningPayloadProvider.swift
//  SBPPersonalBanking (Shared)
//
//  Obtiene el payload cifrado (los 3 datos que Apple necesita) en el MOMENTO de
//  provisionar, pidiéndolo con `WalletProvisionRequest` (`POST /provision`,
//  caso 2). Si la red falla, usa el `encCard` ya guardado en Core Data (caso 1,
//  fallback).
//
//  Se usa tanto en la extensión Non-UI como en el flujo in-app de la app.
//

import Foundation
import SBPCorePersonalBanking

enum ProvisioningPayloadProvider {

    static func payload(forCardID id: String,
                        manager: CoreRequestManager = .shared) async -> EncryptedPassPayload? {
        // 1) Pedir el encCard fresco al backend (POST /provision).
        if let response = try? await manager.load(WalletProvisionRequest(cardID: id)),
           let payload = ProvisioningService.unpack(response.encCard) {
            return payload
        }
        // 2) Fallback: encCard almacenado localmente en Core Data.
        if case .success(let payload) = ProvisioningService.shared.payload(forCardID: id) {
            return payload
        }
        return nil
    }
}
