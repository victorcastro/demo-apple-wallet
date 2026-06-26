//
//  SandboxViewController.swift
//  SBPPersonalBanking
//
//  "Wallet falso": dispara el mismo código que invocaría Wallet (la extensión
//  Non-UI y la de autorización) para verlo funcionar en el simulador, sin
//  necesitar Apple/HST. Cada botón ejecuta un paso y muestra el resultado en el
//  log.
//

import UIKit
import PassKit
import Combine

final class SandboxViewController: UIViewController {

    private let handler = ProvisioningHandler()
    private let contentView = MyView()
    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "📦 Sandbox"
        bindViewActions()
        log("Sandbox listo. Simula las llamadas que haría Wallet.")
    }
    
    /// Consulta el estado general de la extensión para saber si hay tarjetas disponibles
    /// y si Wallet debería pedir autenticación antes de continuar.
    @objc private func runStatus() {
        handler.status { [weak self] status in
            DispatchQueue.main.async {
                self?.log("status(): passEntriesAvailable=\(status.passEntriesAvailable), "
                          + "remotePassEntriesAvailable=\(status.remotePassEntriesAvailable), "
                          + "requiresAuthentication=\(status.requiresAuthentication)")
            }
        }
    }

    /// Recupera las tarjetas provisionables que la extensión expondría a Wallet
    /// para mostrarlas como opciones de agregado.
    @objc private func runPassEntries() {
        handler.passEntries { [weak self] entries in
            DispatchQueue.main.async {
                let ids = CardRepository.shared.provisionableCards().map(\.cardID).joined(separator: ", ")
                self?.log("passEntries(): \(entries.count) entradas para Wallet [\(ids)]")
            }
        }
    }

    /// Presenta la pantalla de autorización para simular el paso de login o biometría
    /// que Wallet ejecutaría antes de agregar la tarjeta.
    @objc private func runAuthorize() {
        let auth = AuthorizationViewController()
        var authorizationMethod: AuthorizationViewController.AuthorizationMethod?
        
        auth.authorizationMethodHandler = { method in
            authorizationMethod = method
        }
        
        auth.completionHandler = { [weak self] result in
            DispatchQueue.main.async {
                let text: String
                if result == .authorized {
                    text = "authorized ✅ (\(Self.authorizationMethodText(authorizationMethod)))"
                } else {
                    text = "canceled ❌"
                }
                self?.log("autorización: \(text)")
                self?.dismiss(animated: true)
            }
        }
        auth.modalPresentationStyle = .formSheet
        present(auth, animated: true)
    }

    /// Genera el `PKAddPaymentPassRequest` final usando una tarjeta de prueba para
    /// simular el payload que Wallet necesita al momento de provisionar.
    @objc private func runGenerate() {
        guard let card = CardRepository.shared.provisionableCards().first else {
            log("no hay tarjetas provisionables")
            return
        }
        guard let config = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2) else { return }
        config.paymentNetwork = card.pkPaymentNetwork

        log("generate… cardID=\(card.cardID) (el SDK pide el payload al issuer de HST)")
        handler.generateAddPaymentPassRequestForPassEntryWithIdentifier(
            card.cardID,
            configuration: config,
            certificateChain: [Data()],   // certs/nonce falsos: el mock no los usa
            nonce: Data(),
            nonceSignature: Data()
        ) { [weak self] request in
            DispatchQueue.main.async {
                if let request {
                    self?.log("✅ PKAddPaymentPassRequest: "
                              + "encryptedPassData=\(request.encryptedPassData?.count ?? 0)B, "
                              + "activationData=\(request.activationData?.count ?? 0)B, "
                              + "ephemeralPublicKey=\(request.ephemeralPublicKey?.count ?? 0)B")
                } else {
                    self?.log("✖️ request = nil (no se pudo construir)")
                }
            }
        }
    }
}

private extension SandboxViewController {
    func bindViewActions() {
        contentView.actions
            .sink { [weak self] action in
                self?.handle(action)
            }
            .store(in: &cancellables)
    }

    func handle(_ action: MyView.Action) {
        switch action {
        case .statusTapped:
            runStatus()
        case .passEntriesTapped:
            runPassEntries()
        case .authorizeTapped:
            runAuthorize()
        case .generateTapped:
            runGenerate()
        case .copyLogTapped:
            copyLog()
        case .clearLogTapped:
            clearLog()
        }
    }

    @objc private func copyLog() {
        UIPasteboard.general.string = contentView.logText
        log("log copiado al portapapeles")
    }

    @objc private func clearLog() {
        contentView.clearLog()
    }
    
    static func authorizationMethodText(_ method: AuthorizationViewController.AuthorizationMethod?) -> String {
        switch method {
        case .password:
            return "password"
        case .biometric:
            return "biometría"
        case .none:
            return "método desconocido"
        }
    }

    // MARK: - Log

    func log(_ message: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        contentView.appendLog("[\(time)] \(message)\n\n")
    }
}
