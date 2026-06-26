//
//  MenuViewController.swift
//  SBPPersonalBanking
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

    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Cerrar sesión",
            message: "Volverás al login. El usuario local seguirá guardado.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cerrar sesión", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
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
            logoutTapped()
        case .faceIDToggled:
            faceIDSwitchChanged()
        }
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
