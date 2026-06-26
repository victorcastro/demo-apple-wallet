//
//  ProvisioningHandler.swift
//  SBPProvisioningExtension  (Extensión SIN interfaz / Non-UI)
//
//  Esta es la clase principal de la extensión de aprovisionamiento del emisor.
//  Es la que permite que Wallet DESCUBRA las tarjetas disponibles en
//  SBPPersonalBanking cuando el usuario toca "+" → "Tarjeta de débito o
//  crédito" → "Tarjetas de tus apps".
//
//  Funciona "en silencio" (no muestra ninguna pantalla): solo RESPONDE las
//  preguntas que le hace Wallet.
//
//  Punto de extensión: com.apple.PassKit.issuer-provisioning
//

import PassKit
import UIKit
import os

final class ProvisioningHandler: PKIssuerProvisioningExtensionHandler {

    // Nuestra fuente de tarjetas (compartida con la app vía App Group).
    private let repository = CardRepository.shared

    // Log para ver en Console.app (filtra por subsystem) si Wallet llama a la
    // extensión en el dispositivo físico.
    private let log = Logger(subsystem: "dev.victorcastro.SBPPersonalBanking.ProvisioningExtension",
                             category: "provisioning")

    // MARK: - Disponibilidad

    /// Wallet llama a este método para decidir si muestra la sección
    /// "tarjetas de tus apps". Aquí le decimos si hay tarjetas para ofrecer.
    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        // Tarjetas que aún NO están en Wallet.
        let pending = repository.provisionableCards()

        let status = PKIssuerProvisioningExtensionStatus()
        // Exigir que el usuario se autentique (lo maneja la extensión UI)
        // antes de poder agregar cualquier tarjeta.
        status.requiresAuthentication = true
        // ¿Hay tarjetas disponibles para el iPhone?
        status.passEntriesAvailable = !pending.isEmpty
        // ¿Hay tarjetas disponibles para un Apple Watch emparejado?
        status.remotePassEntriesAvailable = !pending.isEmpty

        log.info("status(): \(pending.count, privacy: .public) tarjetas provisionables; passEntriesAvailable=\(!pending.isEmpty, privacy: .public)")
        completion(status)
    }

    // MARK: - Lista de tarjetas (pass entries)

    /// Tarjetas que se ofrecen para el iPhone.
    override func passEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        let entries = makePassEntries()
        log.info("passEntries(): devolviendo \(entries.count, privacy: .public) tarjetas a Wallet")
        completion(entries)
    }

    /// Tarjetas que se ofrecen para un Apple Watch emparejado.
    override func remotePassEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        let entries = makePassEntries()
        log.info("remotePassEntries(): devolviendo \(entries.count, privacy: .public) tarjetas (Watch)")
        completion(entries)
    }

    /// Construye la lista de tarjetas que Wallet mostrará. Cada entrada lleva
    /// su arte (imagen), título y la configuración necesaria para agregarla.
    private func makePassEntries() -> [PKIssuerProvisioningExtensionPaymentPassEntry] {
        repository.provisionableCards().compactMap { card in
            // Configuración del "alta" de la tarjeta (esquema de cifrado, datos
            // visibles, red de pago, etc.).
            guard let configuration = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2) else {
                return nil
            }
            configuration.cardholderName = card.cardHolderName
            configuration.primaryAccountSuffix = card.lastFourDigits     // últimos 4 dígitos
            configuration.localizedDescription = card.localizedDescription
            configuration.primaryAccountIdentifier = card.cardID
            configuration.paymentNetwork = card.pkPaymentNetwork         // Visa / Mastercard / Amex
            configuration.style = .payment

            // Arte de HST (Base64) con fallback al arte generado si no es válido.
            guard let art = CardArtRenderer.cgImage(for: card) else { return nil }

            return PKIssuerProvisioningExtensionPaymentPassEntry(
                identifier: card.cardID,
                title: card.localizedDescription,
                art: art,
                addRequestConfiguration: configuration
            )
        }
    }

    // MARK: - Construcción de la solicitud de alta

    /// Se llama una vez que el usuario seleccionó una tarjeta y se autenticó.
    /// Aquí pedimos al PNO (la red de pago) los datos cifrados y devolvemos la
    /// solicitud completa que Wallet usará para crear la tarjeta.
    override func generateAddPaymentPassRequestForPassEntryWithIdentifier(
        _ identifier: String,
        configuration: PKAddPaymentPassRequestConfiguration,
        certificateChain certificates: [Data],   // certificados que entrega Apple
        nonce: Data,                              // valor único anti-repetición
        nonceSignature: Data,                     // firma del nonce
        completionHandler completion: @escaping (PKAddPaymentPassRequest?) -> Void
    ) {
        // Pedimos el `encCard` al backend de HST con `POST /provision` (caso 2)
        // y lo desempacamos en los 3 datos que Apple necesita. Si la red falla,
        // se usa el `encCard` guardado en Core Data (fallback). Los certificados
        // y el nonce que da Apple se enviarían al backend de HST en producción.
        log.info("generateAddPaymentPassRequest: cardID=\(identifier, privacy: .public)")
        Task {
            let payload = await ProvisioningPayloadProvider.payload(forCardID: identifier)
            guard let payload else {
                self.log.error("No se pudo obtener el payload para \(identifier, privacy: .public)")
                completion(nil)
                return
            }
            let request = PKAddPaymentPassRequest()
            request.encryptedPassData = payload.encryptedPassData
            request.activationData = payload.activationData
            request.ephemeralPublicKey = payload.ephemeralPublicKey
            self.log.info("Solicitud de alta construida para \(identifier, privacy: .public)")
            completion(request)
        }
    }
}
