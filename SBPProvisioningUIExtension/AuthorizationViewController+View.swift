//
//  AuthorizationViewController+View.swift
//  SBPProvisioningUIExtension
//

import UIKit
import Combine
import LocalAuthentication

extension AuthorizationViewController {

    final class MyView: UIView {

        enum Action {
            case continueTapped(password: String)
            case biometricTapped
            case cancelTapped
        }

        let actions = PassthroughSubject<Action, Never>()

        private let titleLabel = UILabel()
        private let subtitleLabel = UILabel()
        private let passwordField = UITextField()
        private let continueButton = UIButton(type: .system)
        private let biometricButton = UIButton(type: .system)
        private let cancelButton = UIButton(type: .system)
        private let spinner = UIActivityIndicatorView(style: .medium)

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureUI()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setLoading(_ loading: Bool) {
            loading ? spinner.startAnimating() : spinner.stopAnimating()
            continueButton.isEnabled = !loading
            biometricButton.isEnabled = !loading
            passwordField.isEnabled = !loading
        }

        func showMessage(_ message: String, isError: Bool) {
            subtitleLabel.text = message
            subtitleLabel.textColor = isError ? .systemRed : .secondaryLabel
        }

        private func configureUI() {
            backgroundColor = .systemBackground

            titleLabel.text = "Authorize with SBP"
            titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
            titleLabel.textAlignment = .center

            subtitleLabel.text = "Inicia sesión para agregar tu tarjeta a Apple Wallet."
            subtitleLabel.font = .systemFont(ofSize: 15)
            subtitleLabel.textColor = .secondaryLabel
            subtitleLabel.numberOfLines = 0
            subtitleLabel.textAlignment = .center

            passwordField.placeholder = "Contraseña"
            passwordField.borderStyle = .roundedRect
            passwordField.isSecureTextEntry = true
            passwordField.textContentType = .password

            var continueConfig = UIButton.Configuration.filled()
            continueConfig.title = "Continuar"
            continueConfig.cornerStyle = .large
            continueButton.configuration = continueConfig
            continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)

            var bioConfig = UIButton.Configuration.tinted()
            bioConfig.title = biometricButtonTitle()
            bioConfig.image = biometricButtonImage()
            bioConfig.imagePadding = 8
            bioConfig.cornerStyle = .large
            biometricButton.configuration = bioConfig
            biometricButton.addTarget(self, action: #selector(didTapBiometric), for: .touchUpInside)
            biometricButton.isHidden = !isBiometricAvailable()

            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

            let stack = UIStackView(arrangedSubviews: [
                titleLabel, subtitleLabel, passwordField,
                continueButton, biometricButton, cancelButton
            ])
            stack.axis = .vertical
            stack.spacing = 12
            stack.setCustomSpacing(24, after: subtitleLabel)
            stack.setCustomSpacing(20, after: passwordField)
            stack.translatesAutoresizingMaskIntoConstraints = false

            spinner.hidesWhenStopped = true
            spinner.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stack)
            addSubview(spinner)
            NSLayoutConstraint.activate([
                stack.centerYAnchor.constraint(equalTo: centerYAnchor),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
                spinner.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
                spinner.centerXAnchor.constraint(equalTo: centerXAnchor)
            ])
        }

        @objc private func didTapContinue() {
            actions.send(.continueTapped(password: passwordField.text ?? ""))
        }

        @objc private func didTapBiometric() {
            actions.send(.biometricTapped)
        }

        @objc private func didTapCancel() {
            actions.send(.cancelTapped)
        }

        private func isBiometricAvailable() -> Bool {
            LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        }

        private func biometryType() -> LABiometryType {
            let context = LAContext()
            _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            return context.biometryType
        }

        private func biometricButtonTitle() -> String {
            switch biometryType() {
            case .faceID: return "Usar Face ID"
            case .touchID: return "Usar Touch ID"
            case .opticID: return "Usar Optic ID"
            default: return "Usar biometría"
            }
        }

        private func biometricButtonImage() -> UIImage? {
            switch biometryType() {
            case .faceID: return UIImage(systemName: "faceid")
            case .touchID: return UIImage(systemName: "touchid")
            case .opticID: return UIImage(systemName: "opticid")
            default: return UIImage(systemName: "lock.shield")
            }
        }
    }
}
