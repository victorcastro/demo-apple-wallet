//
//  WalletEngine.swift
//  SBPPersonalBanking (Shared)
//
//  Abstracción sobre TODAS las operaciones de provisioning que hoy haría el SDK
//  de HST. Tiene dos implementaciones intercambiables:
//
//    - HSTWalletEngine  → SDK real (device + entitlement).
//    - MockWalletEngine → simulación funcional en simulador, sin SDK.
//
//  El backend se elige en COMPILACIÓN (no en runtime): en simulador siempre mock;
//  en device, el SDK real, salvo que se fuerce el flag `USE_MOCK_WALLET`.
//

import UIKit
import PassKit

/// Resultado del alta in-app de una tarjeta en Wallet.
enum ProvisioningOutcome {
    case added
    case cancelled
    case failed(Error)
    case unsupported
}

protocol WalletEngine {

    // MARK: Store de tarjetas
    func cards() -> [BankCard]
    @discardableResult func saveCards(_ cards: [BankCard]) -> Bool
    func card(withID id: String) -> BankCard?
    func resetCards()
    /// `true` cuando la tarjeta ya está en Wallet (ya NO es provisionable).
    func isProvisioned(cardID: String) -> Bool

    // MARK: Superficie de la extensión issuer-provisioning
    func provisioningStatus() -> PKIssuerProvisioningExtensionStatus
    func passEntries() -> [PKIssuerProvisioningExtensionPassEntry]
    func remotePassEntries() -> [PKIssuerProvisioningExtensionPassEntry]
    func addPaymentPassRequest(cardID: String,
                               certificates: [Data],
                               nonce: Data,
                               nonceSignature: Data,
                               completion: @escaping (PKAddPaymentPassRequest?) -> Void)

    // MARK: Alta in-app (presenta el sheet de Apple Pay o lo simula)
    func startInAppProvisioning(card: BankCard,
                                from presenter: UIViewController,
                                completion: @escaping (ProvisioningOutcome) -> Void)
}

/// Punto único de selección del backend. El switch es en compilación para que
/// app y extensión usen el mismo motor de forma consistente (sin estado runtime).
enum WalletEngineProvider {

    #if USE_MOCK_WALLET || targetEnvironment(simulator)
    static let current: WalletEngine = MockWalletEngine()
    #else
    static let current: WalletEngine = HSTWalletEngine()
    #endif
}
