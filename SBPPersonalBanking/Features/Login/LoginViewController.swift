//
//  LoginViewController.swift
//  SBPPersonalBanking
//

import UIKit
import Combine
import LocalAuthentication

final class LoginViewController: UIViewController {

    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let contentView = MyView()

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        bindViewActions()
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.contentView.setLoading(isLoading)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.contentView.setMessage(message, isError: true)
            }
            .store(in: &cancellables)

        viewModel.$hasLocalUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasLocalUser in
                self?.contentView.setLocalUserMode(hasLocalUser)
            }
            .store(in: &cancellables)

        viewModel.$isFaceIDAvailableForLogin
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAvailable in
                self?.contentView.setFaceIDVisible(isAvailable)
            }
            .store(in: &cancellables)

        viewModel.$loginSucceeded
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showMainApp()
            }
            .store(in: &cancellables)
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
        case let .submitTapped(dni, password):
            viewModel.login(dni: dni, password: password)
        case .removeLocalUserTapped:
            viewModel.removeLocalUser()
        case .faceIDTapped:
            loginWithFaceID()
        }
    }

    private func showMainApp() {
        guard let window = view.window else { return }
        let mainTabBarController = MainTabBarController()
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = mainTabBarController
        }
    }

    private func loginWithFaceID() {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        let reason = "Autentícate con Face ID para entrar en SBP Demo."

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            contentView.setMessage("Face ID no está disponible en este dispositivo.", isError: true)
            return
        }

        contentView.setLoading(true)
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.contentView.setLoading(false)
                if success {
                    self?.viewModel.loginWithFaceID()
                } else {
                    self?.contentView.setMessage("No se pudo validar con Face ID.", isError: true)
                }
            }
        }
    }
}
