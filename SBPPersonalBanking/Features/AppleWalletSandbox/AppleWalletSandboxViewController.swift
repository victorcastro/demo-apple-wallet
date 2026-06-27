//
//  AppleWalletSandboxViewController.swift
//  DemoAppleWallet
//
//  "Wallet falso": dispara el mismo código que invocaría Wallet, llamando
//  DIRECTO al SDK (igual que lo haría la extensión Non-UI), para verlo funcionar
//  en el simulador sin necesitar Apple/HST. Cada botón ejecuta un paso y muestra
//  el resultado en el log.
//
//  No instancia `ProvisioningHandler` (que es código de la extensión): habla con
//  `WalletHP2SDK.shared`, que es justo lo que el handler delega.
//

import UIKit
import PassKit
import Combine
import SBPShared

final class AppleWalletSandboxViewController: UIViewController {

    private let engine = WalletEngineProvider.current
    private let contentView = MyView()
    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true   // oculta el TabBar mientras este VC está en el stack
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Apple Wallet (Sandbox)"
        bindViewActions()
        log("Sandbox listo. Simula las llamadas que haría Wallet.")
    }
    
    /// Consulta el estado general de la extensión para saber si hay tarjetas disponibles
    /// y si Wallet debería pedir autenticación antes de continuar.
    @objc private func runStatus() {
        let status = engine.provisioningStatus()
        log("status(): passEntriesAvailable=\(status.passEntriesAvailable), "
            + "remotePassEntriesAvailable=\(status.remotePassEntriesAvailable), "
            + "requiresAuthentication=\(status.requiresAuthentication)",
            level: .success)
    }

    /// Recupera las tarjetas provisionables que la extensión expondría a Wallet
    /// para mostrarlas como opciones de agregado.
    @objc private func runPassEntries() {
        let entries = engine.passEntries()
        let ids = WalletCardRepository.shared.provisionableCards().map(\.cardID).joined(separator: ", ")
        log("passEntries(): \(entries.count) entradas para Wallet [\(ids)]", level: entries.isEmpty ? .error : .success)
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
                    text = "Authorized [\(Self.authorizationMethodText(authorizationMethod))]"
                } else {
                    text = "Canceled ❌"
                }
                self?.log("Autorize login/biometric: \(text)", level: result == .authorized ? .success : .error)
                self?.dismiss(animated: true)
            }
        }
        auth.modalPresentationStyle = .formSheet
        present(auth, animated: true)
    }

    /// Genera el `PKAddPaymentPassRequest` final usando una tarjeta de prueba para
    /// simular el payload que Wallet necesita al momento de provisionar.
    @objc private func runGenerate() {
        guard let card = WalletCardRepository.shared.provisionableCards().first else {
            log("no hay tarjetas provisionables", level: .error)
            return
        }

        log("generate… cardID=\(card.cardID) (el engine arma el PKAddPaymentPassRequest)")
        engine.addPaymentPassRequest(
            cardID: card.cardID,
            certificates: [Data()],
            nonce: Data(),
            nonceSignature: Data()
        ) { [weak self] request in
            DispatchQueue.main.async {
                if let request {
                    self?.log("✅ PKAddPaymentPassRequest: "
                              + "encryptedPassData=\(request.encryptedPassData?.count ?? 0)B, "
                              + "activationData=\(request.activationData?.count ?? 0)B, "
                              + "ephemeralPublicKey=\(request.ephemeralPublicKey?.count ?? 0)B",
                              level: .success)
                } else {
                    self?.log("✖️ request = nil (no se pudo construir)", level: .error)
                }
            }
        }
    }
}

private extension AppleWalletSandboxViewController {
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

    func log(_ message: String, level: MyView.LogLevel = .info) {
        contentView.appendLog(message, level: level)
    }
}
