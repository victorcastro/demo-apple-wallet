//
//  WalletProvisioningManager.swift
//  SBPPersonalBanking
//
//  Drives the *standard* in-app provisioning flow (PKAddPaymentPassViewController)
//  from inside the app. This is the prerequisite that must work before the
//  Wallet discovery extensions are useful.
//

import UIKit
import PassKit

final class WalletProvisioningManager: NSObject {

    enum ProvisioningOutcome {
        case added
        case cancelled
        case failed(Error)
        case unsupported
    }

    private var card: BankCard?
    private var completion: ((ProvisioningOutcome) -> Void)?

    /// Whether the current device/account can add payment passes. Returns
    /// `false` on Simulator and on devices not eligible for Apple Pay.
    static var canAddPayments: Bool {
        PKAddPaymentPassViewController.canAddPaymentPass()
    }

    /// Presents the Apple Pay "Add Card" sheet for the given card.
    func startProvisioning(for card: BankCard,
                           from presenter: UIViewController,
                           completion: @escaping (ProvisioningOutcome) -> Void) {
        guard Self.canAddPayments,
              let configuration = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2) else {
            completion(.unsupported)
            return
        }

        configuration.cardholderName = card.cardHolderName
        configuration.primaryAccountSuffix = card.lastFourDigits
        configuration.localizedDescription = card.localizedDescription
        configuration.primaryAccountIdentifier = card.cardID
        configuration.paymentNetwork = card.pkPaymentNetwork
        configuration.style = .payment

        guard let controller = PKAddPaymentPassViewController(requestConfiguration: configuration,
                                                              delegate: self) else {
            completion(.unsupported)
            return
        }

        self.card = card
        self.completion = completion
        presenter.present(controller, animated: true)
    }
}

extension WalletProvisioningManager: PKAddPaymentPassViewControllerDelegate {

    func addPaymentPassViewController(
        _ controller: PKAddPaymentPassViewController,
        generateRequestWithCertificateChain certificates: [Data],
        nonce: Data,
        nonceSignature: Data,
        completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void
    ) {
        guard let card else {
            handler(PKAddPaymentPassRequest())
            return
        }

        // Pedimos el encCard al backend (POST /provision) y, si falla, usamos el
        // guardado en Core Data. Luego construimos la solicitud para Apple.
        Task {
            let request = PKAddPaymentPassRequest()
            if let payload = await ProvisioningPayloadProvider.payload(forCardID: card.cardID) {
                request.encryptedPassData = payload.encryptedPassData
                request.activationData = payload.activationData
                request.ephemeralPublicKey = payload.ephemeralPublicKey
            }
            handler(request)
        }
    }

    func addPaymentPassViewController(
        _ controller: PKAddPaymentPassViewController,
        didFinishAdding pass: PKPaymentPass?,
        error: Error?
    ) {
        let card = self.card
        let completion = self.completion
        self.card = nil
        self.completion = nil

        controller.dismiss(animated: true) {
            if let error {
                completion?(.failed(error))
            } else if pass != nil {
                if let card { CardRepository.shared.markProvisioned(id: card.id) }
                completion?(.added)
            } else {
                completion?(.cancelled)
            }
        }
    }
}
