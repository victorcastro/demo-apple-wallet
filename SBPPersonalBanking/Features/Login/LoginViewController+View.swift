//
//  LoginViewController+View.swift
//  SBPPersonalBanking
//

import UIKit
import Combine

extension LoginViewController {

    final class MyView: UIView {

        enum Action {
            case submitTapped(dni: String, password: String)
            case removeLocalUserTapped
            case faceIDTapped
        }

        let actions = PassthroughSubject<Action, Never>()

        private let titleLabel = UILabel()
        private let messageLabel = UILabel()
        private let dniField = UITextField()
        private let passwordField = UITextField()
        private let loginButton = UIButton(type: .system)
        private let faceIDButton = UIButton(type: .system)
        private let removeLocalUserButton = UIButton(type: .system)
        private let demoHintLabel = UILabel()
        private let spinner = UIActivityIndicatorView(style: .medium)

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureUI()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setLoading(_ isLoading: Bool) {
            isLoading ? spinner.startAnimating() : spinner.stopAnimating()
            dniField.isEnabled = !isLoading
            passwordField.isEnabled = !isLoading
            loginButton.isEnabled = !isLoading
            faceIDButton.isEnabled = !isLoading
            removeLocalUserButton.isEnabled = !isLoading
        }

        func setMessage(_ message: String?, isError: Bool) {
            messageLabel.text = message
            messageLabel.textColor = isError ? .systemRed : .secondaryLabel
        }

        func setLocalUserMode(_ hasLocalUser: Bool) {
            dniField.isHidden = hasLocalUser
            removeLocalUserButton.isHidden = !hasLocalUser
            messageLabel.text = hasLocalUser
                ? "Usuario local detectado. Ingresa tu contraseña."
                : "Ingresa tu DNI y contraseña."
            messageLabel.textColor = .secondaryLabel
            demoHintLabel.text = hasLocalUser
                ? "Password: 1234"
                : "DNI: 12345678 · Password: 1234"
        }

        func setFaceIDVisible(_ isVisible: Bool) {
            faceIDButton.isHidden = !isVisible
        }

        private func configureUI() {
            backgroundColor = .systemBackground

            titleLabel.text = "Login"
            titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
            titleLabel.textAlignment = .center

            messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
            messageLabel.textAlignment = .center
            messageLabel.textColor = .secondaryLabel
            messageLabel.numberOfLines = 0
            messageLabel.text = "Ingresa tu DNI y contraseña."

            dniField.placeholder = "DNI"
            dniField.borderStyle = .roundedRect
            dniField.textContentType = .username
            dniField.autocapitalizationType = .allCharacters
            dniField.autocorrectionType = .no

            passwordField.placeholder = "Password"
            passwordField.borderStyle = .roundedRect
            passwordField.isSecureTextEntry = true
            passwordField.textContentType = .password

            var loginConfiguration = UIButton.Configuration.filled()
            loginConfiguration.title = "Iniciar sesión"
            loginConfiguration.cornerStyle = .large
            loginButton.configuration = loginConfiguration
            loginButton.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)

            var faceIDConfiguration = UIButton.Configuration.tinted()
            faceIDConfiguration.title = "Entrar con Face ID"
            faceIDConfiguration.image = UIImage(systemName: "faceid")
            faceIDConfiguration.imagePadding = 8
            faceIDConfiguration.cornerStyle = .large
            faceIDButton.configuration = faceIDConfiguration
            faceIDButton.addTarget(self, action: #selector(didTapFaceID), for: .touchUpInside)
            faceIDButton.isHidden = true

            var removeConfiguration = UIButton.Configuration.plain()
            removeConfiguration.title = "Eliminar usuario local"
            removeLocalUserButton.configuration = removeConfiguration
            removeLocalUserButton.addTarget(self, action: #selector(didTapRemoveLocalUser), for: .touchUpInside)
            removeLocalUserButton.isHidden = true

            demoHintLabel.font = .systemFont(ofSize: 15, weight: .semibold)
            demoHintLabel.textAlignment = .center
            demoHintLabel.textColor = .secondaryLabel
            demoHintLabel.numberOfLines = 0
            demoHintLabel.text = "DNI: 12345678 · Password: 1234"

            spinner.hidesWhenStopped = true

            let stack = UIStackView(arrangedSubviews: [
                titleLabel,
                messageLabel,
                dniField,
                passwordField,
                loginButton,
                faceIDButton,
                demoHintLabel,
                spinner
            ])
            stack.axis = .vertical
            stack.spacing = 16
            stack.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stack)
            addSubview(removeLocalUserButton)
            removeLocalUserButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
                stack.centerYAnchor.constraint(equalTo: centerYAnchor),
                removeLocalUserButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                removeLocalUserButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24)
            ])
        }

        @objc private func didTapSubmit() {
            actions.send(.submitTapped(dni: dniField.text ?? "", password: passwordField.text ?? ""))
        }

        @objc private func didTapRemoveLocalUser() {
            dniField.text = nil
            passwordField.text = nil
            actions.send(.removeLocalUserTapped)
        }

        @objc private func didTapFaceID() {
            actions.send(.faceIDTapped)
        }
    }
}
