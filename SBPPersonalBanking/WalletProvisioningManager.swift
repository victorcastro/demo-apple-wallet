//
//  WalletProvisioningManager.swift
//  SBPPersonalBanking
//
//  Conduce el flujo in-app de aprovisionamiento delegando en el SDK del emisor
//  (HP2AppleSDK). El SDK presenta el sheet de Apple Pay
//  (`PKAddPaymentPassViewController`), hace el round-trip al PNO y construye la
//  solicitud; aquí solo le pasamos la tarjeta y recibimos el resultado por
//  `CommEvents`.
//

import UIKit
import PassKit
import HP2AppleSDK

final class WalletProvisioningManager: NSObject {

    enum ProvisioningOutcome {
        case added
        case cancelled
        case failed(Error)
        case unsupported
    }

    private let hp2: HP2
    // Retenemos los eventos mientras dura el flujo (el SDK los referencia débil).
    private var events: WalletCommEvents?

    init(sdk: HP2 = WalletSDK.shared) {
        self.hp2 = sdk
    }

    /// Whether the current device/account can add payment passes. Returns
    /// `false` on Simulator and on devices not eligible for Apple Pay.
    static var canAddPayments: Bool {
        PKAddPaymentPassViewController.canAddPaymentPass()
    }

    /// Presenta el sheet de Apple Pay para la tarjeta dada, vía el SDK.
    func startProvisioning(for card: BankCard,
                           from presenter: UIViewController,
                           completion: @escaping (ProvisioningOutcome) -> Void) {
        guard Self.canAddPayments else {
            completion(.unsupported)
            return
        }

        let events = WalletCommEvents { [weak self] outcome in
            // El SDK puede invocar el callback fuera del hilo principal; saltamos
            // a main para liberar el retén y entregar el resultado a la UI.
            DispatchQueue.main.async {
                self?.events = nil
                completion(outcome)
            }
        }
        self.events = events

        do {
            try hp2.executeProvisioningOfEncryptedCard(
                parentViewController: presenter,
                cardholderName: card.cardHolderName,
                panLastFour: card.lastFourDigits,
                cardDescr: card.localizedDescription,
                panId: card.cardID,
                pnp: card.paymentNetwork,   // string; el SDK lo convierte vía HP2Utils
                encCard: card.encCard,
                events: events
            )
        } catch {
            self.events = nil
            completion(.failed(error))
        }
    }
}

// MARK: - Eventos del SDK

/// Recibe el resultado del aprovisionamiento del SDK y lo traduce a
/// `ProvisioningOutcome`.
nonisolated final class WalletCommEvents: CommEvents {

    private let onResult: (WalletProvisioningManager.ProvisioningOutcome) -> Void

    init(onResult: @escaping (WalletProvisioningManager.ProvisioningOutcome) -> Void) {
        self.onResult = onResult
        super.init()
    }

    override func onPreExecute() {}

    override func onPostExecute(result: CommEventResult) {
        switch result.getResult() {
        case HP2Errors.SUCCESS:
            onResult(.added)
        case HP2Errors.USER_CANCELLED, HP2Errors.SYSTEM_CANCELLED:
            onResult(.cancelled)
        default:
            onResult(.failed(HP2Exception(result.getResult(), result.getMessage())))
        }
    }
}
