//
//  ProvisioningHandler.swift
//  SBPProvisioningExtension  (Extensión SIN interfaz / Non-UI)
//
//  Clase principal de la extensión de aprovisionamiento del emisor. Permite que
//  Wallet DESCUBRA las tarjetas disponibles en SBPPersonalBanking ("+" →
//  "Tarjeta de débito o crédito" → "Tarjetas de tus apps").
//
//  Delega todo en el SDK del emisor (HP2AppleSDK), que lee del mismo App Group
//  y resuelve el round-trip al PNO internamente.
//
//  Punto de extensión: com.apple.PassKit.issuer-provisioning
//

import PassKit
import HP2AppleSDK
import os

final class ProvisioningHandler: PKIssuerProvisioningExtensionHandler {

    private let hp2 = WalletSDK.shared

    private let log = Logger(subsystem: "dev.victorcastro.SBPPersonalBanking.ProvisioningExtension",
                             category: "provisioning")

    // MARK: - Disponibilidad

    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        let status = hp2.getProvisioningExtensionStatus()
        log.info("status(): passEntriesAvailable=\(status.passEntriesAvailable, privacy: .public)")
        completion(status)
    }

    // MARK: - Lista de tarjetas (pass entries)

    override func passEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        let entries = hp2.getPassEntriesAvailable()
        log.info("passEntries(): \(entries.count, privacy: .public) tarjetas")
        completion(entries)
    }

    override func remotePassEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        let entries = hp2.getRemotePassEntriesAvailable()
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
        let encCard = hp2.getCardDataModel(cardID: identifier)?.getEncCard()
        hp2.getAddPaymentPassRequest(certificateChain: certificates,
                                     nonceSignature: nonceSignature,
                                     nonce: nonce,
                                     pushReceiptID: nil,
                                     issuerEncCard: encCard) { [weak self] request in
            self?.log.info("Solicitud de alta para \(identifier, privacy: .public): \(request == nil ? "nil" : "ok", privacy: .public)")
            completion(request)
        }
    }
}
