//
//  WalletEngineProtocol.swift
//  DemoAppleWallet (Shared)
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
public enum ProvisioningOutcome {
    case added
    case cancelled
    case failed(Error)
    case unsupported
}

public protocol WalletEngineProtocol {

    // MARK: Store de tarjetas
    func cards() -> [WalletCard]
    @discardableResult func saveCards(_ cards: [WalletCard]) -> Bool
    func card(withID id: String) -> WalletCard?
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
    func startInAppProvisioning(card: WalletCard,
                                from presenter: UIViewController,
                                completion: @escaping (ProvisioningOutcome) -> Void)
}

/// Punto único de selección del backend. El switch es en compilación para que
/// app y extensión usen el mismo motor de forma consistente (sin estado runtime).
public enum WalletEngineProvider {

    #if USE_MOCK_WALLET || targetEnvironment(simulator)
    public static let current: WalletEngineProtocol = MockWalletEngine()
    #else
    public static let current: WalletEngineProtocol = HSTWalletEngine()
    #endif
}
