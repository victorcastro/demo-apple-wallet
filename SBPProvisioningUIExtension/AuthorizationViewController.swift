//
//  AuthorizationViewController.swift
//  SBPProvisioningUIExtension  (Extensión CON interfaz / UI)
//
//  Pantalla de autorización que Wallet presenta antes de provisionar. Reutiliza
//  el login/sesión compartido con la app:
//   - `SessionStore` (SBPShared): sabe si ya hay sesión (solo pide contraseña) y
//     si la biometría está activada.
//   - `AuthService` (SBPCorePersonalBanking): ejecuta el login real y devuelve la
//     cookieJoy.
//
//  Punto de extensión: com.apple.PassKit.issuer-provisioning.authorization
//

import UIKit
import PassKit
import LocalAuthentication
import Combine
import SBPShared
import SBPCorePersonalBanking

final class AuthorizationViewController: UIViewController, PKIssuerProvisioningExtensionAuthorizationProviding {

    enum AuthorizationMethod {
        case password
        case biometric
    }

    var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?
    var authorizationMethodHandler: ((AuthorizationMethod) -> Void)?

    private let contentView = MyView()
    private var cancellables = Set<AnyCancellable>()

    // Defaults inline: Wallet instancia la clase principal vía Objective-C
    // (`[[AuthorizationViewController alloc] init]`). Al no declarar un
    // designated initializer propio, la clase HEREDA `init`/`init(nibName:bundle:)`
    // de UIViewController y esos campos quedan poblados sin pasar por Swift.
    private var session = SessionStore()
    private var authService: AuthenticationServicing = AuthenticationService()

    /// Inyección de dependencias para el sandbox y los tests. NO la usa Wallet.
    convenience init(session: SessionStore, authService: AuthenticationServicing) {
        self.init(nibName: nil, bundle: nil)
        self.session = session
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

    /// Ajusta la UI al estado de sesión: la biometría solo se ofrece si el
    /// usuario la activó en la app.
    private func configureForSession() {
        contentView.setBiometricVisible(session.isFaceIDEnabled)
        if !session.hasActiveSession {
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
        guard !password.isEmpty else {
            showMessage("Ingresa tu contraseña.", isError: true)
            return
        }

        // La extensión no pide DNI: requiere una sesión previa (cookieJoy) creada
        // desde la app. El DNI se resuelve de la cookieJoy guardada.
        guard session.hasActiveSession, let dni = session.dni else {
            showMessage("Abre la app SBP e inicia sesión antes de agregar tu tarjeta.", isError: true)
            return
        }

        setLoading(true)
        showMessage("Validando...", isError: false)

        Task {
            do {
                let cookieJoy = try await authService.login(dni: dni, password: password)
                session.save(cookieJoy: cookieJoy)
                await MainActor.run {
                    self.setLoading(false)
                    self.authorize(using: .password)
                }
            } catch {
                await MainActor.run {
                    self.setLoading(false)
                    self.showMessage(self.message(for: error), isError: true)
                }
            }
        }
    }

    private func continueWithBiometrics() {
        guard session.isFaceIDEnabled else {
            showMessage("Activa Face ID en la app para usarlo aquí.", isError: true)
            return
        }

        setLoading(true)
        showMessage("Validando biometría...", isError: false)
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
                    // La sesión ya existe (cookieJoy guardada): la biometría solo
                    // la desbloquea, no vuelve a llamar al login.
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

    private func message(for error: Error) -> String {
        if let error = error as? CoreRequestError, case .httpStatus = error {
            return "Contraseña incorrecta."
        }
        if let error = error as? AuthenticationError {
            return error.errorDescription ?? "No se pudo iniciar sesión."
        }
        return error.localizedDescription
    }

    private func authorize(using method: AuthorizationMethod) {
        authorizationMethodHandler?(method)
        completionHandler?(.authorized)
    }
}
