//
//  SandboxViewController+View.swift
//  SBPPersonalBanking
//

import UIKit
import Combine

extension SandboxViewController {

    final class MyView: UIView {

        enum Action {
            case statusTapped
            case passEntriesTapped
            case authorizeTapped
            case generateTapped
            case copyLogTapped
            case clearLogTapped
        }

        let actions = PassthroughSubject<Action, Never>()

        private let logContainerView = UIView()
        private let logHeaderView = UIView()
        private let logView = UITextView()

        var logText: String {
            logView.text
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureUI()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func appendLog(_ message: String) {
            logView.text += message
            logView.scrollRangeToVisible(NSRange(location: (logView.text as NSString).length, length: 0))
        }

        func clearLog() {
            logView.text = ""
        }

        private func configureUI() {
            backgroundColor = .systemBackground

            let actionsStack = UIStackView(arrangedSubviews: [
                makeActionView(
                    title: "1 · status()",
                    description: "Consulta qué respondería la extensión a Wallet sobre disponibilidad de tarjetas y si requiere autenticación.",
                    action: #selector(didTapStatus)
                ),
                makeActionView(
                    title: "2 · passEntries()",
                    description: "Pide la lista de tarjetas que la extensión ofrecería a Wallet para añadirlas.",
                    action: #selector(didTapPassEntries)
                ),
                makeActionView(
                    title: "3 · Autorizar (login / biometría)",
                    description: "Presenta la UI de autorización para simular el paso donde Wallet pide validar al usuario.",
                    action: #selector(didTapAuthorize)
                ),
                makeActionView(
                    title: "4 · generateAddPaymentPassRequest",
                    description: "Construye el payload final de provisioning de una tarjeta, como lo solicitaría Wallet antes de añadirla.",
                    action: #selector(didTapGenerate)
                )
            ])
            actionsStack.axis = .vertical
            actionsStack.spacing = 12
            actionsStack.translatesAutoresizingMaskIntoConstraints = false

            logContainerView.backgroundColor = .secondarySystemBackground
            logContainerView.layer.cornerRadius = 8
            logContainerView.translatesAutoresizingMaskIntoConstraints = false

            logHeaderView.translatesAutoresizingMaskIntoConstraints = false

            logView.isEditable = false
            logView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            logView.backgroundColor = .clear
            logView.translatesAutoresizingMaskIntoConstraints = false

            let clearLogsButton = makeClearLogsButton(#selector(didTapClearLog))
            let copyLogButton = makeLogActionButton(#selector(didTapCopyLog))

            addSubview(actionsStack)
            addSubview(logContainerView)
            logContainerView.addSubview(logHeaderView)
            logContainerView.addSubview(logView)
            logHeaderView.addSubview(clearLogsButton)
            logHeaderView.addSubview(copyLogButton)

            NSLayoutConstraint.activate([
                actionsStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
                actionsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                actionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

                logContainerView.topAnchor.constraint(equalTo: actionsStack.bottomAnchor, constant: 16),
                logContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                logContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                logContainerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),

                logHeaderView.topAnchor.constraint(equalTo: logContainerView.topAnchor, constant: 8),
                logHeaderView.leadingAnchor.constraint(equalTo: logContainerView.leadingAnchor, constant: 8),
                logHeaderView.trailingAnchor.constraint(equalTo: logContainerView.trailingAnchor, constant: -8),
                logHeaderView.heightAnchor.constraint(equalToConstant: 28),

                clearLogsButton.leadingAnchor.constraint(equalTo: logHeaderView.leadingAnchor),
                clearLogsButton.centerYAnchor.constraint(equalTo: logHeaderView.centerYAnchor),

                copyLogButton.trailingAnchor.constraint(equalTo: logHeaderView.trailingAnchor),
                copyLogButton.centerYAnchor.constraint(equalTo: logHeaderView.centerYAnchor),
                copyLogButton.widthAnchor.constraint(equalToConstant: 28),
                copyLogButton.heightAnchor.constraint(equalToConstant: 28),

                logView.topAnchor.constraint(equalTo: logHeaderView.bottomAnchor, constant: 4),
                logView.leadingAnchor.constraint(equalTo: logContainerView.leadingAnchor, constant: 8),
                logView.trailingAnchor.constraint(equalTo: logContainerView.trailingAnchor, constant: -8),
                logView.bottomAnchor.constraint(equalTo: logContainerView.bottomAnchor, constant: -8)
            ])
        }

        private func makeActionView(title: String, description: String, action: Selector) -> UIView {
            let container = UIView()
            container.backgroundColor = .secondarySystemBackground
            container.layer.cornerRadius = 12

            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            titleLabel.numberOfLines = 0

            let descriptionLabel = UILabel()
            descriptionLabel.text = description
            descriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
            descriptionLabel.textColor = .secondaryLabel
            descriptionLabel.numberOfLines = 0

            let button = UIButton(type: .system)
            button.backgroundColor = .clear
            button.addTarget(self, action: action, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false

            let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
            textStack.axis = .vertical
            textStack.spacing = 4
            textStack.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(textStack)
            container.addSubview(button)

            NSLayoutConstraint.activate([
                textStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
                textStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
                textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
                textStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

                button.topAnchor.constraint(equalTo: container.topAnchor),
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            return container
        }

        private func makeLogActionButton(_ action: Selector) -> UIButton {
            var cfg = UIButton.Configuration.plain()
            cfg.image = UIImage(systemName: "doc.on.doc")
            cfg.contentInsets = .zero
            cfg.baseForegroundColor = .secondaryLabel
            let button = UIButton(configuration: cfg)
            button.addTarget(self, action: action, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }

        private func makeClearLogsButton(_ action: Selector) -> UIButton {
            var cfg = UIButton.Configuration.plain()
            cfg.title = "Clear"
            cfg.contentInsets = .zero
            cfg.baseForegroundColor = .systemBlue
            let button = UIButton(configuration: cfg)
            button.addTarget(self, action: action, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }

        @objc private func didTapStatus() {
            actions.send(.statusTapped)
        }

        @objc private func didTapPassEntries() {
            actions.send(.passEntriesTapped)
        }

        @objc private func didTapAuthorize() {
            actions.send(.authorizeTapped)
        }

        @objc private func didTapGenerate() {
            actions.send(.generateTapped)
        }

        @objc private func didTapCopyLog() {
            actions.send(.copyLogTapped)
        }

        @objc private func didTapClearLog() {
            actions.send(.clearLogTapped)
        }
    }
}
