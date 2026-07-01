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

    private var events: WalletCommEvents?

    init(sdk: HP2 = WalletHP2SDK.shared) {
        self.hp2 = sdk
    }

    // MARK: Disponibilidad

    func isAvailable() -> Bool {
        hp2.isAvailable()
    }

    // MARK: Store

    /// Devuelve todas las tarjetas persistidas por el SDK (`getCardsFromCoreData()`)
    /// mapeadas a `WalletCard`, resolviendo para cada una su flag `isProvisioned`.
    func cards() -> [WalletCard] {
        hp2.getCardsFromCoreData()
            .map { WalletCard(model: $0, isProvisioned: isProvisioned(cardID: $0.cardID ?? "")) }
    }

    /// Persiste el conjunto de tarjetas en el store del SDK vía
    /// `updateDataBase(cardDataList:)`. Reemplaza el contenido actual con el
    /// listado dado. Devuelve `true` si el SDK responde `DataBaseErrors.SUCCESS`.
    @discardableResult
    func saveCards(_ cards: [WalletCard]) -> Bool {
        hp2.updateDataBase(cardDataList: cards.map(\.toModel)) == DataBaseErrors.SUCCESS.rawValue
    }

    /// Recupera una única tarjeta por su `cardID` (`getCardDataModel(cardID:)`),
    /// mapeada a `WalletCard` con su flag `isProvisioned`. `nil` si no existe.
    func card(withID id: String) -> WalletCard? {
        guard let model = hp2.getCardDataModel(cardID: id) else { return nil }
        return WalletCard(model: model, isProvisioned: isProvisioned(cardID: id))
    }

    /// Vacía el store de tarjetas del SDK persistiendo una lista vacía.
    func resetCards() {
        _ = hp2.updateDataBase(cardDataList: [])
    }

    /// Indica si la tarjeta ya está digitalizada en Wallet. Se apoya en
    /// `isAvailableForCard(panRefId:)` del SDK —que informa si la tarjeta *puede*
    /// añadirse— y lo invierte: no disponible ⇒ ya provisionada. Un `cardID`
    /// vacío se considera no provisionado.
    func isProvisioned(cardID: String) -> Bool {
        guard !cardID.isEmpty else { return false }
        return !hp2.isAvailableForCard(panRefId: cardID)
    }

    // MARK: Extensión issuer-provisioning

    /// Estado que la extensión issuer-provisioning reporta a Wallet
    /// (`getProvisioningExtensionStatus()`): disponibilidad de pases locales y
    /// remotos, y si se requiere autenticación del usuario.
    func provisioningStatus() -> PKIssuerProvisioningExtensionStatus {
        hp2.getProvisioningExtensionStatus()
    }

    /// Catálogo de tarjetas locales que la extensión ofrece a Wallet
    /// (`getPassEntriesAvailable()`): entradas con metadatos, sin datos cifrados.
    func passEntries() -> [PKIssuerProvisioningExtensionPassEntry] {
        hp2.getPassEntriesAvailable()
    }

    /// Equivalente a `passEntries()` pero para tarjetas provisionables en
    /// dispositivos emparejados (p. ej. Apple Watch), vía
    /// `getRemotePassEntriesAvailable()`.
    func remotePassEntries() -> [PKIssuerProvisioningExtensionPassEntry] {
        hp2.getRemotePassEntriesAvailable()
    }

    /// Construye el `PKAddPaymentPassRequest` final para una tarjeta. Recupera su
    /// `encCard` (payload cifrado del emisor) del store y lo pasa junto al
    /// material criptográfico que entrega Apple (cadena de certificados, `nonce`
    /// y su firma) a `getAddPaymentPassRequest(...)`. El SDK resuelve de forma
    /// asíncrona con el request listo para Wallet, o `nil` si no pudo armarlo.
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

/// Recibe los callbacks del SDK durante el alta y mapea su resultado a `ProvisioningOutcome`.
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
