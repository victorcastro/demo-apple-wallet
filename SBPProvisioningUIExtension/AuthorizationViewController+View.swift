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

        private let iconView = UIImageView()
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

            iconView.image = UIImage(systemName: "creditcard.fill")
            iconView.tintColor = .tintColor
            iconView.contentMode = .scaleAspectFit
            iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
            iconView.setContentHuggingPriority(.required, for: .vertical)

            titleLabel.text = "SBPPersonalBanking"
            titleLabel.font = UIFontMetrics(forTextStyle: .title1).scaledFont(for: .systemFont(ofSize: 28, weight: .bold))
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            titleLabel.adjustsFontForContentSizeCategory = true

            subtitleLabel.text = "Inicia sesión para validar tu identidad y agregar tu tarjeta a Apple Wallet."
            subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
            subtitleLabel.textColor = .secondaryLabel
            subtitleLabel.numberOfLines = 0
            subtitleLabel.textAlignment = .center
            subtitleLabel.adjustsFontForContentSizeCategory = true

            passwordField.placeholder = "Contraseña"
            passwordField.borderStyle = .roundedRect
            passwordField.isSecureTextEntry = true
            passwordField.textContentType = .password
            passwordField.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true

            var continueConfig = UIButton.Configuration.filled()
            continueConfig.title = "Continuar"
            continueConfig.cornerStyle = .large
            continueConfig.buttonSize = .large
            continueButton.configuration = continueConfig
            continueButton.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)

            var bioConfig = UIButton.Configuration.tinted()
            bioConfig.title = biometricButtonTitle()
            bioConfig.image = biometricButtonImage()
            bioConfig.imagePadding = 8
            bioConfig.cornerStyle = .large
            bioConfig.buttonSize = .large
            biometricButton.configuration = bioConfig
            biometricButton.addTarget(self, action: #selector(didTapBiometric), for: .touchUpInside)
            biometricButton.isHidden = !isBiometricAvailable()

            cancelButton.setTitle("Cancelar", for: .normal)
            cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

            // Cabecera (ícono + título + subtítulo) anclada arriba.
            let headerStack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel])
            headerStack.axis = .vertical
            headerStack.alignment = .center
            headerStack.spacing = 8
            headerStack.setCustomSpacing(16, after: iconView)

            // Formulario (campo + botones) debajo de la cabecera.
            let formStack = UIStackView(arrangedSubviews: [passwordField, continueButton, biometricButton])
            formStack.axis = .vertical
            formStack.spacing = 12
            formStack.setCustomSpacing(20, after: passwordField)

            let stack = UIStackView(arrangedSubviews: [headerStack, formStack])
            stack.axis = .vertical
            stack.spacing = 32
            stack.translatesAutoresizingMaskIntoConstraints = false

            spinner.hidesWhenStopped = true
            spinner.translatesAutoresizingMaskIntoConstraints = false
            cancelButton.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stack)
            addSubview(spinner)
            addSubview(cancelButton)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 40),
                stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
                spinner.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
                spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
                cancelButton.centerXAnchor.constraint(equalTo: centerXAnchor),
                cancelButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
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
