//
//  WalletProvisioningManager.swift
//  DemoAppleWallet
//
//  API in-app para agregar una tarjeta a Wallet. Delega en el `WalletEngine`
//  activo: en device el SDK presenta el sheet real de Apple Pay; en simulador el
//  mock lo simula con un alert.
//

import UIKit
import PassKit
import SBPShared

final class WalletProvisioningManager: NSObject {

    private let engine: WalletEngineProtocol

    init(engine: WalletEngineProtocol = WalletEngineProvider.current) {
        self.engine = engine
        super.init()
    }

    /// Indica si el dispositivo/cuenta actual puede añadir pases de pago. Devuelve:
    /// `false` en el simulador y en dispositivos no compatibles con Apple Pay.
    static var canAddPayments: Bool {
        PKAddPaymentPassViewController.canAddPaymentPass()
    }

    /// Inicia el alta de la tarjeta (real o simulada según el backend).
    func startProvisioning(for card: WalletCard,
                           from presenter: UIViewController,
                           completion: @escaping (ProvisioningOutcome) -> Void) {
        engine.startInAppProvisioning(card: card, from: presenter, completion: completion)
    }
}
