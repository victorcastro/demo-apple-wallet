//
//  MockWalletEngine.swift
//  DemoAppleWallet (Shared)
//
//  Backend MOCK: simula el comportamiento del SDK de HST para que el flujo sea
//  plenamente funcional en simulador (donde el SDK real, el keychain y Apple Pay
//  no operan). No tiene dependencia del SDK.
//
//  - Store propio en UserDefaults del App Group (sembrado por el Sync de Mockoon).
//  - Genera pass entries y un PKAddPaymentPassRequest de relleno.
//  - El alta in-app se simula con un alert (no hay PKAddPaymentPassViewController
//    en simulador).
//

import UIKit
import PassKit

final class MockWalletEngine: WalletEngineProtocol {

    private let defaults: UserDefaults
    private let storeKey = "mock.cards"

    init() {
        self.defaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard
    }

    // MARK: Disponibilidad

    // En simulador siempre disponible: el flujo se demuestra con el mock.
    func isAvailable() -> Bool { true }

    // MARK: Store

    func cards() -> [WalletCard] {
        guard let data = defaults.data(forKey: storeKey),
              let cards = try? JSONDecoder().decode([WalletCard].self, from: data) else {
            return []
        }
        return cards.sorted { $0.cardHolderName < $1.cardHolderName }
    }

    @discardableResult
    func saveCards(_ cards: [WalletCard]) -> Bool {
        var current = Dictionary(uniqueKeysWithValues: self.cards().map { ($0.cardID, $0) })
        for var card in cards {
            card.isProvisioned = current[card.cardID]?.isProvisioned ?? card.isProvisioned
            current[card.cardID] = card
        }
        return persist(Array(current.values))
    }

    func card(withID id: String) -> WalletCard? {
        cards().first { $0.cardID == id }
    }

    func resetCards() {
        defaults.removeObject(forKey: storeKey)
    }

    func isProvisioned(cardID: String) -> Bool {
        card(withID: cardID)?.isProvisioned ?? false
    }

    // MARK: Extensión issuer-provisioning

    func provisioningStatus() -> PKIssuerProvisioningExtensionStatus {
        let hasCards = !provisionable().isEmpty
        let status = PKIssuerProvisioningExtensionStatus()
        status.requiresAuthentication = true
        status.passEntriesAvailable = hasCards
        status.remotePassEntriesAvailable = hasCards
        return status
    }

    func passEntries() -> [PKIssuerProvisioningExtensionPassEntry] {
        provisionable().compactMap(makePassEntry)
    }

    func remotePassEntries() -> [PKIssuerProvisioningExtensionPassEntry] {
        passEntries()
    }

    func addPaymentPassRequest(cardID: String,
                               certificates: [Data],
                               nonce: Data,
                               nonceSignature: Data,
                               completion: @escaping (PKAddPaymentPassRequest?) -> Void) {
        let request = PKAddPaymentPassRequest()
        request.encryptedPassData = Data("ENC-\(cardID)".utf8)
        request.activationData = Data("ACT-\(cardID)".utf8)
        request.ephemeralPublicKey = Data("EPK-\(cardID)".utf8)
        completion(request)
    }

    // MARK: Alta in-app (simulada)

    func startInAppProvisioning(card: WalletCard,
                                from presenter: UIViewController,
                                completion: @escaping (ProvisioningOutcome) -> Void) {
        let alert = UIAlertController(
            title: "Simular alta en Wallet",
            message: "Modo mock (simulador): se agregará \(card.localizedDescription) sin pasar por Apple Pay real.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in
            completion(.cancelled)
        })
        alert.addAction(UIAlertAction(title: "Agregar", style: .default) { [weak self] _ in
            self?.markProvisioned(cardID: card.cardID)
            completion(.added)
        })
        presenter.present(alert, animated: true)
    }

    // MARK: - Auxiliares

    private func provisionable() -> [WalletCard] {
        cards().filter { !$0.isProvisioned }
    }

    private func makePassEntry(for card: WalletCard) -> PKIssuerProvisioningExtensionPaymentPassEntry? {
        guard let configuration = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2),
              let art = WalletCardUtils.cgImage(for: card) else {
            return nil
        }
        configuration.cardholderName = card.cardHolderName
        configuration.primaryAccountSuffix = card.lastFourDigits
        configuration.localizedDescription = card.localizedDescription
        configuration.primaryAccountIdentifier = card.cardID
        configuration.paymentNetwork = card.pkPaymentNetwork
        configuration.style = .payment

        return PKIssuerProvisioningExtensionPaymentPassEntry(
            identifier: card.cardID,
            title: card.localizedDescription,
            art: art,
            addRequestConfiguration: configuration
        )
    }

    private func markProvisioned(cardID: String) {
        var all = cards()
        guard let index = all.firstIndex(where: { $0.cardID == cardID }) else { return }
        all[index].isProvisioned = true
        _ = persist(all)
    }

    @discardableResult
    private func persist(_ cards: [WalletCard]) -> Bool {
        guard let data = try? JSONEncoder().encode(cards) else { return false }
        defaults.set(data, forKey: storeKey)
        return true
    }
}
