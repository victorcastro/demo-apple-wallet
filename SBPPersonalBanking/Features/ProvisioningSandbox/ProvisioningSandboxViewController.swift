//
//  ProvisioningSandboxViewController.swift
//  DemoAppleWallet
//
//  Banco de pruebas del provisioning que ejerce cada paso de forma aislada, sin
//  depender de un flujo real de Apple/HST. Un segmentado separa los DOS caminos:
//
//    • In-app  → alta iniciada desde la propia app (el botón "Añadir a Wallet"),
//                dividida en tres pasos: disponibilidad del dispositivo, estado
//                de la tarjeta y presentación del sheet de Apple Pay.
//    • Wallet  → lo que Apple Wallet le pide a la extensión issuer-provisioning
//                (`status` / `passEntries` / autorización / `generate…`).
//
//  Todas las operaciones pasan por `WalletEngineProvider.current` (mock en
//  simulador, SDK real en device), nunca por el SDK directo. El resultado de
//  cada acción se centraliza en `LoggerManager`, que lo reparte a la consola
//  visual inferior y a la consola de Xcode / del dispositivo.
//

import UIKit
import PassKit
import Combine
import SBPShared

final class ProvisioningSandboxViewController: UIViewController {

    private let engine = WalletEngineProvider.current
    private let walletManager = WalletProvisioningManager()
    private let contentView = ContentView()
    private var cancellables = Set<AnyCancellable>()
    private var cards: [WalletCard] = []
    private var selectedCardID: String?

    private var selectedCard: WalletCard? {
        cards.first { $0.cardID == selectedCardID }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
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
        title = "Provisioning Sandbox"
        bindActions()
        bindLogger()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadCards()
    }
}

// MARK: - Enrutado de acciones

private extension ProvisioningSandboxViewController {

    func bindActions() {
        contentView.actions
            .sink { [weak self] action in self?.handle(action) }
            .store(in: &cancellables)
    }

    func handle(_ action: ContentView.Action) {
        switch action {
        case .selectCard(let id): selectCard(id)
        case .checkAvailability:  runCheckAvailability()
        case .checkProvisioned:   runCheckProvisioned()
        case .addInApp:           runAddInApp()
        case .status:            runStatus()
        case .passEntries:       runPassEntries()
        case .authorize:         runAuthorize()
        case .generate:          runGenerate()
        case .expandLog:         expandLog()
        case .copyLog:           LoggerManager.shared.copyToPasteboard()
        case .clearLog:          LoggerManager.shared.clear()
        }
    }
}

// MARK: - Flujo In-app

private extension ProvisioningSandboxViewController {

    func runCheckAvailability() {
        let deviceSupport = engine.isAvailable()
        let canAddPass = WalletProvisioningManager.canAddPayments
        log("hp2.isAvailable = \(deviceSupport)\ncanAddPaymentPass = \(canAddPass)")
    }

    func runCheckProvisioned() {
        guard let card = selectedCard else {
            log("Selecciona una tarjeta primero.", level: .error)
            return
        }
        let provisioned = engine.isProvisioned(cardID: card.cardID)
        log("[\(card.maskedNumber)] isProvisioned() = \(provisioned)",
            level: provisioned ? .error : .success)
    }

    func runAddInApp() {
        guard let card = selectedCard else {
            log("Selecciona una tarjeta primero.", level: .error)
            return
        }

        log("startInAppProvisioning… cardID = \(card.cardID)")
        walletManager.startProvisioning(for: card, from: self) { [weak self] outcome in
            DispatchQueue.main.async {
                self?.logOutcome(outcome, card: card)
                self?.reloadCards()
            }
        }
    }

    func logOutcome(_ outcome: ProvisioningOutcome, card: WalletCard) {
        switch outcome {
        case .added:
            log("✅ Añadida a Wallet: \(card.localizedDescription)", level: .success)
        case .cancelled:
            log("Alta cancelada por el usuario.", level: .error)
        case .failed(let error):
            log("❌ Falló el alta: \(error.localizedDescription)", level: .error)
        case .unsupported:
            log("Dispositivo no soporta Apple Pay (canAddPaymentPass=false).", level: .error)
        }
    }
}

// MARK: - Flujo Wallet (extensión issuer-provisioning)

private extension ProvisioningSandboxViewController {

    func runStatus() {
        let status = engine.provisioningStatus()
        log("status(): passEntriesAvailable=\(status.passEntriesAvailable), "
            + "remotePassEntriesAvailable=\(status.remotePassEntriesAvailable), "
            + "requiresAuthentication=\(status.requiresAuthentication)",
            level: .success)
    }

    func runPassEntries() {
        let entries = engine.passEntries()
        let ids = WalletCardRepository.shared.provisionableCards().map(\.cardID).joined(separator: ", ")
        log("passEntries(): \(entries.count) entradas para Wallet [\(ids)]",
            level: entries.isEmpty ? .error : .success)
    }

    func runAuthorize() {
        let auth = AuthorizationViewController()
        var authorizationMethod: AuthorizationViewController.AuthorizationMethod?

        auth.authorizationMethodHandler = { method in
            authorizationMethod = method
        }

        auth.completionHandler = { [weak self] result in
            DispatchQueue.main.async {
                let authorized = result == .authorized
                let text = authorized
                    ? "Authorized [\(Self.authorizationMethodText(authorizationMethod))]"
                    : "Canceled ❌"
                self?.log("Autorizar login/biometric: \(text)", level: authorized ? .success : .error)
                self?.dismiss(animated: true)
            }
        }
        auth.modalPresentationStyle = .formSheet
        present(auth, animated: true)
    }

    func runGenerate() {
        guard let card = WalletCardRepository.shared.provisionableCards().first else {
            log("No hay tarjetas provisionables.", level: .error)
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
                guard let request else {
                    self?.log("✖️ request = nil (no se pudo construir)", level: .error)
                    return
                }
                self?.log("✅ PKAddPaymentPassRequest: "
                          + "encryptedPassData=\(request.encryptedPassData?.count ?? 0)B, "
                          + "activationData=\(request.activationData?.count ?? 0)B, "
                          + "ephemeralPublicKey=\(request.ephemeralPublicKey?.count ?? 0)B",
                          level: .success)
            }
        }
    }
}

// MARK: - Selector de tarjetas

private extension ProvisioningSandboxViewController {

    func reloadCards() {
        cards = WalletCardRepository.shared.allCards()
        if selectedCardID == nil || !cards.contains(where: { $0.cardID == selectedCardID }) {
            selectedCardID = cards.first?.cardID
        }
        refreshCardSelector()
    }

    func refreshCardSelector() {
        contentView.updateCards(
            cards.map {
                ContentView.CardOption(id: $0.cardID,
                                       title: "\($0.maskedNumber) · \($0.paymentNetwork)",
                                       provisioned: $0.isProvisioned)
            },
            selectedID: selectedCardID
        )
    }

    func selectCard(_ id: String) {
        selectedCardID = id
        refreshCardSelector()
        if let card = selectedCard {
            log("Tarjeta seleccionada: \(card.maskedNumber) · \(card.localizedDescription)")
        }
    }
}

// MARK: - Acciones globales / Log

private extension ProvisioningSandboxViewController {

    func bindLogger() {
        LoggerManager.shared.entries.forEach { render($0) }
        LoggerManager.shared.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .appended(let entry): self?.render(entry)
                case .cleared:             self?.contentView.clearLog()
                }
            }
            .store(in: &cancellables)
    }

    func render(_ entry: LoggerManager.Entry) {
        contentView.appendLog(entry.message, level: entry.level.uiLevel)
    }
    
    func expandLog() {
        let sheet = LogSheetViewController(
            content: contentView.logAttributedText,
            onCopy: { LoggerManager.shared.copyToPasteboard() },
            onClear: { LoggerManager.shared.clear() }
        )
        sheet.modalPresentationStyle = .pageSheet
        if let sheetController = sheet.sheetPresentationController {
            sheetController.detents = [.large()]
            sheetController.prefersGrabberVisible = true
        }
        present(sheet, animated: true)
    }

    func log(_ message: String, level: LoggerManager.Level = .info) {
        LoggerManager.shared.log(message, level: level)
    }

    static func authorizationMethodText(_ method: AuthorizationViewController.AuthorizationMethod?) -> String {
        switch method {
        case .password:  return "password"
        case .biometric: return "biometría"
        case .none:      return "método desconocido"
        }
    }
}

// MARK: - Mapeo de severidad a la consola visual

private extension LoggerManager.Level {
    var uiLevel: ProvisioningSandboxViewController.ContentView.LogLevel {
        switch self {
        case .info:    return .info
        case .success: return .success
        case .error:   return .error
        }
    }
}
