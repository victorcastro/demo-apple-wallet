//
//  WalletProvisioningManager.swift
//  SBPPersonalBanking
//
//  API in-app para agregar una tarjeta a Wallet. Delega en el `WalletEngine`
//  activo: en device el SDK presenta el sheet real de Apple Pay; en simulador el
//  mock lo simula con un alert.
//

import UIKit
import PassKit

final class WalletProvisioningManager: NSObject {

    private let engine: WalletEngine

    init(engine: WalletEngine = WalletEngineProvider.current) {
        self.engine = engine
        super.init()
    }

    /// Whether the current device/account can add payment passes. Returns
    /// `false` on Simulator and on devices not eligible for Apple Pay.
    static var canAddPayments: Bool {
        PKAddPaymentPassViewController.canAddPaymentPass()
    }

    /// Inicia el alta de la tarjeta (real o simulada según el backend).
    func startProvisioning(for card: BankCard,
                           from presenter: UIViewController,
                           completion: @escaping (ProvisioningOutcome) -> Void) {
        engine.startInAppProvisioning(card: card, from: presenter, completion: completion)
    }
}
