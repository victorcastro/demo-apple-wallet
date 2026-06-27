//
//  AuthorizationViewController.swift
//  SBPProvisioningUIExtension  (Extensión CON interfaz / UI)
//
//  Pantalla de autorización que Wallet presenta antes de provisionar. Solo se
//  ocupa de la UI y delega TODA la lógica de auth/sesión en `AuthenticationService`
//  (SBPShared): estado de sesión, login con contraseña, biometría y persistencia.
//
//  Punto de extensión: com.apple.PassKit.issuer-provisioning.authorization
//

import UIKit
import PassKit
import Combine
import SBPShared

final class AuthorizationViewController: UIViewController, PKIssuerProvisioningExtensionAuthorizationProviding {

    enum AuthorizationMethod {
        case password
        case biometric
    }

    var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?
    var authorizationMethodHandler: ((AuthorizationMethod) -> Void)?

    private let contentView = MyView()
    private var cancellables = Set<AnyCancellable>()

    private var authService: AuthenticationServicing = AuthenticationService()

    /// Constructor opcional para UnitTest y dataMock, AppleWallet no lo usa
    convenience init(authService: AuthenticationServicing) {
        self.init(nibName: nil, bundle: nil)
        self.authService = authService
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewActions()
        configureForSession()
    }

    private func bindViewActions() {
        contentView.actions
            .sink { [weak self] action in
                self?.handle(action)
            }
            .store(in: &cancellables)
    }

    /// Ajusta la UI al estado de sesión: la biometría solo se ofrece si está disponible.
    private func configureForSession() {
        contentView.setBiometricVisible(authService.isBiometricLoginAvailable)
        if !authService.hasActiveSession {
            showMessage("Abre la app SBP e inicia sesión antes de agregar tu tarjeta.", isError: true)
        }
    }

    // MARK: - Acciones

    private func handle(_ action: MyView.Action) {
        switch action {
        case let .continueTapped(password):
            continueWithPassword(password)
        case .biometricTapped:
            continueWithBiometrics()
        case .cancelTapped:
            completionHandler?(.canceled)
        }
    }

    private func continueWithPassword(_ password: String) {
        authenticate(loadingMessage: "Validando...", method: .password) { [authService] in
            try await authService.loginWithPassword(password)
        }
    }

    private func continueWithBiometrics() {
        authenticate(loadingMessage: "Validando biometría...", method: .biometric) { [authService] in
            try await authService.loginWithBiometrics()
        }
    }

    /// Ejecuta una operación de auth y refleja el resultado en la UI.
    private func authenticate(loadingMessage: String,
                              method: AuthorizationMethod,
                              operation: @escaping () async throws -> Void) {
        setLoading(true)
        showMessage(loadingMessage, isError: false)

        Task { [weak self] in
            do {
                try await operation()
                await MainActor.run {
                    guard let self else { return }
                    self.setLoading(false)
                    self.authorize(using: method)
                }
            } catch {
                await MainActor.run {
                    guard let self else { return }
                    self.setLoading(false)
                    self.showMessage(error.localizedDescription, isError: true)
                }
            }
        }
    }

    // MARK: - Estado UI

    private func setLoading(_ loading: Bool) {
        contentView.setLoading(loading)
    }

    private func showMessage(_ message: String, isError: Bool) {
        contentView.showMessage(message, isError: isError)
    }

    private func authorize(using method: AuthorizationMethod) {
        authorizationMethodHandler?(method)
        completionHandler?(.authorized)
    }
}
