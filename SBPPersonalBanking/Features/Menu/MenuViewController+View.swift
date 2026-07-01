//
//  MenuViewController+View.swift
//  DemoAppleWallet
//

import UIKit
import Combine

extension MenuViewController {

    final class MyView: UIView {

        enum Action {
            case logoutTapped
            case faceIDToggled
            case resetCardsTapped
        }

        let actions = PassthroughSubject<Action, Never>()

        private let stackView = UIStackView()
        private let faceIDContainerView = UIView()
        private let faceIDTitleLabel = UILabel()
        private let faceIDSubtitleLabel = UILabel()
        private let faceIDSwitch = UISwitch()
        private let resetContainerView = UIView()
        private let resetTitleLabel = UILabel()
        private let resetSubtitleLabel = UILabel()
        private let resetButton = UIButton(type: .system)
        private let logoutButton = UIButton(type: .system)
        private let appInfoLabel = UILabel()

        var isFaceIDSwitchOn: Bool {
            faceIDSwitch.isOn
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureUI()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setFaceIDSwitchOn(_ isOn: Bool, animated: Bool) {
            faceIDSwitch.setOn(isOn, animated: animated)
        }

        func setFaceIDState(isEnabled: Bool, isOn: Bool, subtitle: String) {
            faceIDSwitch.isEnabled = isEnabled
            faceIDSwitch.isOn = isOn
            faceIDSubtitleLabel.text = subtitle
        }

        private func configureUI() {
            backgroundColor = .systemGroupedBackground

            faceIDTitleLabel.text = "Activar Face ID"
            faceIDTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)

            faceIDSubtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
            faceIDSubtitleLabel.textColor = .secondaryLabel
            faceIDSubtitleLabel.numberOfLines = 0

            faceIDSwitch.addTarget(self, action: #selector(didToggleFaceID), for: .valueChanged)

            let faceIDTextStack = UIStackView(arrangedSubviews: [faceIDTitleLabel, faceIDSubtitleLabel])
            faceIDTextStack.axis = .vertical
            faceIDTextStack.spacing = 4

            let faceIDRow = UIStackView(arrangedSubviews: [faceIDTextStack, faceIDSwitch])
            faceIDRow.axis = .horizontal
            faceIDRow.alignment = .center
            faceIDRow.spacing = 16
            faceIDRow.translatesAutoresizingMaskIntoConstraints = false

            faceIDContainerView.backgroundColor = .secondarySystemGroupedBackground
            faceIDContainerView.layer.cornerRadius = 16
            faceIDContainerView.translatesAutoresizingMaskIntoConstraints = false
            faceIDContainerView.addSubview(faceIDRow)

            NSLayoutConstraint.activate([
                faceIDRow.topAnchor.constraint(equalTo: faceIDContainerView.topAnchor, constant: 16),
                faceIDRow.leadingAnchor.constraint(equalTo: faceIDContainerView.leadingAnchor, constant: 16),
                faceIDRow.trailingAnchor.constraint(equalTo: faceIDContainerView.trailingAnchor, constant: -16),
                faceIDRow.bottomAnchor.constraint(equalTo: faceIDContainerView.bottomAnchor, constant: -16)
            ])

            resetTitleLabel.text = "Eliminar tarjetas"
            resetTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)

            resetSubtitleLabel.text = "Borra las tarjetas guardadas localmente (CoreData). Podrás recuperarlas sincronizando otra vez."
            resetSubtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
            resetSubtitleLabel.textColor = .secondaryLabel
            resetSubtitleLabel.numberOfLines = 0

            var resetConfiguration = UIButton.Configuration.tinted()
            resetConfiguration.title = "Eliminar"
            resetConfiguration.image = UIImage(systemName: "trash")
            resetConfiguration.imagePadding = 6
            resetConfiguration.baseForegroundColor = .systemRed
            resetConfiguration.baseBackgroundColor = .systemRed
            resetConfiguration.cornerStyle = .large
            resetButton.configuration = resetConfiguration
            resetButton.setContentHuggingPriority(.required, for: .horizontal)
            resetButton.addTarget(self, action: #selector(didTapResetCards), for: .touchUpInside)

            let resetTextStack = UIStackView(arrangedSubviews: [resetTitleLabel, resetSubtitleLabel])
            resetTextStack.axis = .vertical
            resetTextStack.spacing = 4

            let resetRow = UIStackView(arrangedSubviews: [resetTextStack, resetButton])
            resetRow.axis = .horizontal
            resetRow.alignment = .center
            resetRow.spacing = 16
            resetRow.translatesAutoresizingMaskIntoConstraints = false

            resetContainerView.backgroundColor = .secondarySystemGroupedBackground
            resetContainerView.layer.cornerRadius = 16
            resetContainerView.translatesAutoresizingMaskIntoConstraints = false
            resetContainerView.addSubview(resetRow)

            NSLayoutConstraint.activate([
                resetRow.topAnchor.constraint(equalTo: resetContainerView.topAnchor, constant: 16),
                resetRow.leadingAnchor.constraint(equalTo: resetContainerView.leadingAnchor, constant: 16),
                resetRow.trailingAnchor.constraint(equalTo: resetContainerView.trailingAnchor, constant: -16),
                resetRow.bottomAnchor.constraint(equalTo: resetContainerView.bottomAnchor, constant: -16)
            ])

            var logoutConfiguration = UIButton.Configuration.filled()
            logoutConfiguration.title = "Cerrar sesión"
            logoutConfiguration.image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
            logoutConfiguration.imagePadding = 8
            logoutConfiguration.baseBackgroundColor = .systemRed
            logoutConfiguration.baseForegroundColor = .white
            logoutConfiguration.cornerStyle = .large
            logoutButton.configuration = logoutConfiguration
            logoutButton.addTarget(self, action: #selector(didTapLogout), for: .touchUpInside)
            logoutButton.translatesAutoresizingMaskIntoConstraints = false
            logoutButton.heightAnchor.constraint(equalToConstant: 52).isActive = true

            appInfoLabel.font = .systemFont(ofSize: 13, weight: .regular)
            appInfoLabel.textColor = .secondaryLabel
            appInfoLabel.textAlignment = .center
            appInfoLabel.numberOfLines = 0
            appInfoLabel.text = appVersionText()

            stackView.axis = .vertical
            stackView.spacing = 16
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(faceIDContainerView)
            stackView.addArrangedSubview(resetContainerView)
            stackView.addArrangedSubview(logoutButton)
            stackView.addArrangedSubview(appInfoLabel)

            addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
                stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
                stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
            ])
        }

        private func appVersionText() -> String {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
            return "Versión \(version) (\(build))"
        }

        @objc private func didTapLogout() {
            actions.send(.logoutTapped)
        }

        @objc private func didTapResetCards() {
            actions.send(.resetCardsTapped)
        }

        @objc private func didToggleFaceID() {
            actions.send(.faceIDToggled)
        }
    }
}
