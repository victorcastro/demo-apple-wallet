//
//  ProvisioningHandler.swift
//  SBPProvisioningExtension  (Extensión SIN interfaz / Non-UI)
//
//  Clase principal de la extensión de aprovisionamiento del emisor. Permite que
//  Wallet DESCUBRA las tarjetas disponibles en SBPPersonalBanking ("+" →
//  "Tarjeta de débito o crédito" → "Tarjetas de tus apps").
//
//  Delega en el `WalletEngine` activo (SDK real en device; mock en simulador,
//  aunque la extensión solo corre de verdad en device).
//
//  Punto de extensión: com.apple.PassKit.issuer-provisioning
//

import PassKit
import os

final class ProvisioningHandler: PKIssuerProvisioningExtensionHandler {

    private let engine = WalletEngineProvider.current

    private let log = Logger(subsystem: "dev.victorcastro.SBPPersonalBanking.ProvisioningExtension",
                             category: "provisioning")

    // MARK: - Disponibilidad

    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        let status = engine.provisioningStatus()
        log.info("status(): passEntriesAvailable=\(status.passEntriesAvailable, privacy: .public)")
        completion(status)
    }

    // MARK: - Lista de tarjetas (pass entries)

    override func passEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        let entries = engine.passEntries()
        log.info("passEntries(): \(entries.count, privacy: .public) tarjetas")
        completion(entries)
    }

    override func remotePassEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        let entries = engine.remotePassEntries()
        log.info("remotePassEntries(): \(entries.count, privacy: .public) tarjetas (Watch)")
        completion(entries)
    }

    // MARK: - Construcción de la solicitud de alta

    override func generateAddPaymentPassRequestForPassEntryWithIdentifier(
        _ identifier: String,
        configuration: PKAddPaymentPassRequestConfiguration,
        certificateChain certificates: [Data],
        nonce: Data,
        nonceSignature: Data,
        completionHandler completion: @escaping (PKAddPaymentPassRequest?) -> Void
    ) {
        log.info("generateAddPaymentPassRequest: cardID=\(identifier, privacy: .public)")
        engine.addPaymentPassRequest(cardID: identifier,
                                     certificates: certificates,
                                     nonce: nonce,
                                     nonceSignature: nonceSignature) { [weak self] request in
            self?.log.info("Solicitud de alta para \(identifier, privacy: .public): \(request == nil ? "nil" : "ok", privacy: .public)")
            completion(request)
        }
    }
}
