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

        private let iconView = UIImageView()
        private let titleLabel = UILabel()
        private let messageLabel = UILabel()
        private let dniField = UITextField()
        private let passwordField = UITextField()
        private let loginButton = UIButton(type: .system)
        private let faceIDButton = UIButton(type: .system)
        private let removeLocalUserButton = UIButton(type: .system)
        private let demoHintLabel = UILabel()
        private let versionLabel = UILabel()
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

            iconView.image = UIImage(systemName: "building.columns.fill")
            iconView.tintColor = .tintColor
            iconView.contentMode = .scaleAspectFit
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .semibold)
            iconView.setContentHuggingPriority(.required, for: .vertical)

            titleLabel.text = "Bienvenido"
            titleLabel.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 32, weight: .bold))
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.adjustsFontForContentSizeCategory = true

            messageLabel.font = .preferredFont(forTextStyle: .subheadline)
            messageLabel.textAlignment = .center
            messageLabel.textColor = .secondaryLabel
            messageLabel.numberOfLines = 0
            messageLabel.adjustsFontForContentSizeCategory = true
            messageLabel.text = "Ingresa tu DNI y contraseña."

            dniField.placeholder = "DNI"
            dniField.borderStyle = .roundedRect
            dniField.textContentType = .username
            dniField.autocapitalizationType = .allCharacters
            dniField.autocorrectionType = .no
            dniField.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true

            passwordField.placeholder = "Password"
            passwordField.borderStyle = .roundedRect
            passwordField.isSecureTextEntry = true
            passwordField.textContentType = .password
            passwordField.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true

            var loginConfiguration = UIButton.Configuration.filled()
            loginConfiguration.title = "Iniciar sesión"
            loginConfiguration.cornerStyle = .large
            loginConfiguration.buttonSize = .large
            loginButton.configuration = loginConfiguration
            loginButton.addTarget(self, action: #selector(didTapSubmit), for: .touchUpInside)

            var faceIDConfiguration = UIButton.Configuration.tinted()
            faceIDConfiguration.title = "Entrar con Face ID"
            faceIDConfiguration.image = UIImage(systemName: "faceid")
            faceIDConfiguration.imagePadding = 8
            faceIDConfiguration.cornerStyle = .large
            faceIDConfiguration.buttonSize = .large
            faceIDButton.configuration = faceIDConfiguration
            faceIDButton.addTarget(self, action: #selector(didTapFaceID), for: .touchUpInside)
            faceIDButton.isHidden = true

            var removeConfiguration = UIButton.Configuration.plain()
            removeConfiguration.title = "Eliminar usuario local"
            removeLocalUserButton.configuration = removeConfiguration
            removeLocalUserButton.addTarget(self, action: #selector(didTapRemoveLocalUser), for: .touchUpInside)
            removeLocalUserButton.isHidden = true

            demoHintLabel.font = .preferredFont(forTextStyle: .footnote)
            demoHintLabel.textAlignment = .center
            demoHintLabel.textColor = .secondaryLabel
            demoHintLabel.numberOfLines = 0
            demoHintLabel.adjustsFontForContentSizeCategory = true
            demoHintLabel.text = "DNI: 12345678 · Password: 1234"

            versionLabel.font = .preferredFont(forTextStyle: .caption2)
            versionLabel.textAlignment = .center
            versionLabel.textColor = .tertiaryLabel
            versionLabel.adjustsFontForContentSizeCategory = true
            versionLabel.text = Self.appVersionText
            versionLabel.translatesAutoresizingMaskIntoConstraints = false

            spinner.hidesWhenStopped = true

            // Cabecera (ícono + título + mensaje) anclada arriba.
            let headerStack = UIStackView(arrangedSubviews: [iconView, titleLabel, messageLabel])
            headerStack.axis = .vertical
            headerStack.alignment = .center
            headerStack.spacing = 8
            headerStack.setCustomSpacing(16, after: iconView)

            // Formulario (campos + botones) debajo de la cabecera.
            let formStack = UIStackView(arrangedSubviews: [
                dniField, passwordField, loginButton, faceIDButton, demoHintLabel, spinner
            ])
            formStack.axis = .vertical
            formStack.spacing = 16
            formStack.setCustomSpacing(8, after: loginButton)

            let stack = UIStackView(arrangedSubviews: [headerStack, formStack])
            stack.axis = .vertical
            stack.spacing = 32
            stack.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stack)
            addSubview(removeLocalUserButton)
            addSubview(versionLabel)
            removeLocalUserButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
                stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 48),
                versionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                versionLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -12),
                removeLocalUserButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                removeLocalUserButton.bottomAnchor.constraint(equalTo: versionLabel.topAnchor, constant: -8)
            ])
        }

        /// Versión de la app leída del bundle, p. ej. "Versión 1.0 (1)".
        private static var appVersionText: String {
            let info = Bundle.main.infoDictionary
            let short = info?["CFBundleShortVersionString"] as? String ?? "—"
            let build = info?["CFBundleVersion"] as? String ?? "—"
            return "Versión \(short) (\(build))"
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
