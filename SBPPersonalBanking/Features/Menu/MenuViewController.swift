//
//  MenuViewController.swift
//  DemoAppleWallet
//

import UIKit
import LocalAuthentication
import Combine

final class MenuViewController: UIViewController {

    private let viewModel = MenuViewModel()
    private let contentView = MyView()
    private var cancellables = Set<AnyCancellable>()

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Menu"
        bindViewActions()
        refreshFaceIDUI()
    }

    private func logout() {
        guard let window = view.window else { return }
        let loginNavigationController = UINavigationController(rootViewController: LoginViewController())
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = loginNavigationController
        }
    }

    private func bindViewActions() {
        contentView.actions
            .sink { [weak self] action in
                self?.handle(action)
            }
            .store(in: &cancellables)
    }

    private func handle(_ action: MyView.Action) {
        switch action {
        case .logoutTapped:
            logout()
        case .faceIDToggled:
            faceIDSwitchChanged()
        case .resetCardsTapped:
            resetCardsTapped()
        }
    }

    private func resetCardsTapped() {
        let alert = UIAlertController(
            title: "Eliminar tarjetas",
            message: "Esto borrará todas las tarjetas guardadas localmente. Podrás recuperarlas sincronizando otra vez desde Mockoon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.viewModel.resetCards()
        })
        present(alert, animated: true)
    }

    @objc private func faceIDSwitchChanged() {
        guard viewModel.hasLocalUser else {
            contentView.setFaceIDSwitchOn(false, animated: true)
            refreshFaceIDUI()
            return
        }

        if contentView.isFaceIDSwitchOn && !isBiometryAvailable() {
            contentView.setFaceIDSwitchOn(false, animated: true)
            let alert = UIAlertController(
                title: "Face ID no disponible",
                message: "Este dispositivo no tiene biometría disponible en este momento.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            refreshFaceIDUI()
            return
        }

        viewModel.setFaceIDEnabled(contentView.isFaceIDSwitchOn)
        refreshFaceIDUI()
    }

    private func refreshFaceIDUI() {
        let hasLocalUser = viewModel.hasLocalUser
        let subtitle = hasLocalUser
            ? "Permite mostrar Face ID en el login mientras exista cookieJoy."
            : "Necesitas un usuario local con cookieJoy para activar Face ID."
        contentView.setFaceIDState(
            isEnabled: hasLocalUser,
            isOn: viewModel.isFaceIDEnabled,
            subtitle: subtitle
        )
    }

    private func isBiometryAvailable() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}
