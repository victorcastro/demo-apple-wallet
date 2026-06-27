//
//  HSTWalletEngine.swift
//  DemoAppleWallet (Shared)
//
//  Backend REAL: delega todo en el SDK de HST (`WalletHP2SDK.shared` = HP2). Es el
//  camino de producción (device + entitlement). Centraliza las llamadas al SDK
//  que antes vivían dispersas en WalletCardRepository / ProvisioningHandler /
//  WalletProvisioningManager.
//

import UIKit
import PassKit
import HP2AppleSDK

final class HSTWalletEngine: WalletEngineProtocol {

    private let hp2: HP2
    // Retén de los eventos mientras dura un alta (el SDK los referencia débil).
    private var events: WalletCommEvents?

    init(sdk: HP2 = WalletHP2SDK.shared) {
        self.hp2 = sdk
    }

    // MARK: Store

    func cards() -> [WalletCard] {
        hp2.getCardsFromCoreData()
            .map { WalletCard(model: $0, isProvisioned: isProvisioned(cardID: $0.cardID ?? "")) }
    }

    @discardableResult
    func saveCards(_ cards: [WalletCard]) -> Bool {
        hp2.updateDataBase(cardDataList: cards.map(\.asCardDataModel)) == DataBaseErrors.SUCCESS.rawValue
    }

    func card(withID id: String) -> WalletCard? {
        guard let model = hp2.getCardDataModel(cardID: id) else { return nil }
        return WalletCard(model: model, isProvisioned: isProvisioned(cardID: id))
    }

    func resetCards() {
        _ = hp2.updateDataBase(cardDataList: [])
    }

    func isProvisioned(cardID: String) -> Bool {
        guard !cardID.isEmpty else { return false }
        return !hp2.isAvailableForCard(panRefId: cardID)
    }

    // MARK: Extensión issuer-provisioning

    func provisioningStatus() -> PKIssuerProvisioningExtensionStatus {
        hp2.getProvisioningExtensionStatus()
    }

    func passEntries() -> [PKIssuerProvisioningExtensionPassEntry] {
        hp2.getPassEntriesAvailable()
    }

    func remotePassEntries() -> [PKIssuerProvisioningExtensionPassEntry] {
        hp2.getRemotePassEntriesAvailable()
    }

    func addPaymentPassRequest(cardID: String,
                               certificates: [Data],
                               nonce: Data,
                               nonceSignature: Data,
                               completion: @escaping (PKAddPaymentPassRequest?) -> Void) {
        let encCard = hp2.getCardDataModel(cardID: cardID)?.getEncCard()
        hp2.getAddPaymentPassRequest(certificateChain: certificates,
                                     nonceSignature: nonceSignature,
                                     nonce: nonce,
                                     pushReceiptID: nil,
                                     issuerEncCard: encCard,
                                     completionHandler: completion)
    }

    // MARK: Alta in-app

    func startInAppProvisioning(card: WalletCard,
                                from presenter: UIViewController,
                                completion: @escaping (ProvisioningOutcome) -> Void) {
        guard PKAddPaymentPassViewController.canAddPaymentPass() else {
            completion(.unsupported)
            return
        }

        let events = WalletCommEvents { [weak self] outcome in
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
                pnp: card.paymentNetwork,
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

/// Traduce el resultado del SDK a `ProvisioningOutcome`. Debe ser `nonisolated`
/// porque sobreescribe métodos `nonisolated` de la clase `CommEvents` del SDK.
nonisolated final class WalletCommEvents: CommEvents {

    private let onResult: (ProvisioningOutcome) -> Void

    init(onResult: @escaping (ProvisioningOutcome) -> Void) {
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
