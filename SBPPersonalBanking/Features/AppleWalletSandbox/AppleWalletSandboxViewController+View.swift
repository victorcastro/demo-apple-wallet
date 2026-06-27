//
//  AppleWalletSandboxViewController+View.swift
//  DemoAppleWallet
//

import UIKit
import Combine

extension AppleWalletSandboxViewController {

    final class MyView: UIView {

        enum Action {
            case statusTapped
            case passEntriesTapped
            case authorizeTapped
            case generateTapped
            case copyLogTapped
            case clearLogTapped
        }

        /// Severidad de una línea de log. La indica quien llama a `appendLog`
        /// y determina el color con el que se pinta para mejorar la lectura.
        enum LogLevel {
            case success
            case error
            case info

            var color: UIColor {
                switch self {
                case .success: return .systemGreen
                case .error:   return .systemRed
                case .info:    return .label
                }
            }

            var weight: UIFont.Weight {
                self == .info ? .regular : .medium
            }
        }

        let actions = PassthroughSubject<Action, Never>()

        private let logContainerView = UIView()
        private let logView = UITextView()

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            return formatter
        }()

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

        // MARK: - Log API

        /// Añade una línea al log con su hora y color según severidad.
        func appendLog(_ message: String, level: LogLevel) {
            let entry = NSMutableAttributedString(attributedString: logView.attributedText)
            if entry.length > 0 {
                entry.append(NSAttributedString(string: "\n"))
            }
            entry.append(makeEntry(for: message, level: level))
            logView.attributedText = entry
            logView.scrollRangeToVisible(NSRange(location: entry.length, length: 0))
        }

        func clearLog() {
            logView.attributedText = NSAttributedString(string: "")
        }

        private func makeEntry(for message: String, level: LogLevel) -> NSAttributedString {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 2
            paragraph.paragraphSpacing = 10

            let line = NSMutableAttributedString(
                string: "\(Self.timeFormatter.string(from: Date()))  ",
                attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: paragraph
                ]
            )
            line.append(NSAttributedString(
                string: message,
                attributes: [
                    .font: UIFont.monospacedSystemFont(ofSize: 12, weight: level.weight),
                    .foregroundColor: level.color,
                    .paragraphStyle: paragraph
                ]
            ))
            return line
        }

        // MARK: - Layout

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

            // Contenedor del log estilo "consola": forzamos modo oscuro solo en este
            // subárbol para que los colores adaptativos (texto, fondo, separador) se
            // resuelvan en dark y el verde/rojo resalten, sin afectar al resto de la UI.
            logContainerView.overrideUserInterfaceStyle = .dark
            logContainerView.backgroundColor = .secondarySystemBackground
            logContainerView.layer.cornerRadius = 14
            logContainerView.translatesAutoresizingMaskIntoConstraints = false

            // Header: título a la izquierda, acciones (copy / clear) juntas a la derecha.
            let titleLabel = UILabel()
            titleLabel.text = "Console"
            titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = .secondaryLabel
            titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let copyButton = makeIconButton(systemName: "doc.on.doc",
                                             action: #selector(didTapCopyLog),
                                             tint: .secondaryLabel)
            let clearButton = makeIconButton(systemName: "trash",
                                             action: #selector(didTapClearLog),
                                             tint: .secondaryLabel)

            let buttonsStack = UIStackView(arrangedSubviews: [copyButton, clearButton])
            buttonsStack.axis = .horizontal
            buttonsStack.spacing = 4

            let headerStack = UIStackView(arrangedSubviews: [titleLabel, buttonsStack])
            headerStack.axis = .horizontal
            headerStack.alignment = .center
            headerStack.translatesAutoresizingMaskIntoConstraints = false

            let separator = UIView()
            separator.backgroundColor = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false

            logView.isEditable = false
            logView.backgroundColor = .clear
            logView.textContainerInset = UIEdgeInsets(top: 8, left: 2, bottom: 8, right: 2)
            logView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(actionsStack)
            addSubview(logContainerView)
            logContainerView.addSubview(headerStack)
            logContainerView.addSubview(separator)
            logContainerView.addSubview(logView)

            NSLayoutConstraint.activate([
                actionsStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
                actionsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                actionsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

                logContainerView.topAnchor.constraint(equalTo: actionsStack.bottomAnchor, constant: 16),
                logContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                logContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                logContainerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),

                headerStack.topAnchor.constraint(equalTo: logContainerView.topAnchor, constant: 10),
                headerStack.leadingAnchor.constraint(equalTo: logContainerView.leadingAnchor, constant: 14),
                headerStack.trailingAnchor.constraint(equalTo: logContainerView.trailingAnchor, constant: -8),

                separator.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
                separator.leadingAnchor.constraint(equalTo: logContainerView.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: logContainerView.trailingAnchor),
                separator.heightAnchor.constraint(equalToConstant: 0.5),

                logView.topAnchor.constraint(equalTo: separator.bottomAnchor),
                logView.leadingAnchor.constraint(equalTo: logContainerView.leadingAnchor, constant: 12),
                logView.trailingAnchor.constraint(equalTo: logContainerView.trailingAnchor, constant: -12),
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

        private func makeIconButton(systemName: String, action: Selector, tint: UIColor) -> UIButton {
            var cfg = UIButton.Configuration.plain()
            cfg.image = UIImage(systemName: systemName,
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))
            cfg.baseForegroundColor = tint
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
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
