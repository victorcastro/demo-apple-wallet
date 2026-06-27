//
//  AuthorizationViewController.swift
//  SBPProvisioningUIExtension  (Extensión CON interfaz / UI)
//
//  Pantalla de autorización que Wallet presenta antes de provisionar. Ofrece:
//   - Inicio de sesión con contraseña (botón "Continuar"), con validación local
//     temporal hasta reconectarlo con la feature Login.
//   - Face ID/Touch ID OPCIONAL mediante su propio botón (sin auto-prompt).
//
//  Punto de extensión: com.apple.PassKit.issuer-provisioning.authorization
//

import UIKit
import PassKit
import LocalAuthentication
import Combine

final class AuthorizationViewController: UIViewController, PKIssuerProvisioningExtensionAuthorizationProviding {

    enum AuthorizationMethod {
        case password
        case biometric
    }

    var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?
    var authorizationMethodHandler: ((AuthorizationMethod) -> Void)?

    private let contentView = MyView()
    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewActions()
    }

    private func bindViewActions() {
        contentView.actions
            .sink { [weak self] action in
                self?.handle(action)
            }
            .store(in: &cancellables)
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
        guard !password.isEmpty else {
            showMessage("Ingresa tu contraseña.", isError: true)
            return
        }

        // TODO: Implementar el login real
        authorize(using: .password)
    }

    private func continueWithBiometrics() {
        setLoading(true)
        showMessage("Validando biometría...", isError: false)
        
        // TODO: Implementar el login real
        evaluateNativeBiometrics()
    }

    private func evaluateNativeBiometrics() {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        let reason = "Autentícate para agregar tu tarjeta SBP a Apple Wallet."
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.setLoading(false)
                if success {
                    self?.authorize(using: .biometric)
                } else {
                    self?.showMessage("No se pudo validar con biometría. Usa tu contraseña.", isError: false)
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
