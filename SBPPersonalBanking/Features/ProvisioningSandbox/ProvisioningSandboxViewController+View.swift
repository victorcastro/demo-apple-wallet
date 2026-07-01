//
//  ProvisioningSandboxViewController+View.swift
//  DemoAppleWallet
//
//  Toda la UI del sandbox: el segmentado In-app / Wallet, las tarjetas de acción
//  de cada segmento y el console log compartido. La lógica vive en el VC; aquí
//  solo se emite `Action` (vía `actions`) y se pinta el resultado.
//

import UIKit
import Combine

extension ProvisioningSandboxViewController {

    final class ContentView: UIView {

        // MARK: - Tipos

        enum Action {
            // In-app
            case selectCard(String)
            case checkAvailability
            case checkProvisioned
            case addInApp
            // Wallet (extensión)
            case status
            case passEntries
            case authorize
            case generate
            // Globales
            case expandLog
            case copyLog
            case clearLog
        }

        enum LogLevel {
            case success, error, info

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

        struct CardOption {
            let id: String
            let title: String
            let provisioned: Bool

            var menuTitle: String { provisioned ? "\(title) — en Wallet" : title }
        }

        private struct ActionItem {
            let title: String
            let description: String
            let action: Action
        }

        private struct Section {
            let title: String
            let showsCardSelector: Bool
            let items: [ActionItem]

            init(title: String, showsCardSelector: Bool = false, items: [ActionItem]) {
                self.title = title
                self.showsCardSelector = showsCardSelector
                self.items = items
            }
        }

        private enum Segment: Int, CaseIterable {
            case inApp, wallet

            var title: String {
                switch self {
                case .inApp:  return "In-app"
                case .wallet: return "Wallet"
                }
            }
        }

        // MARK: - API pública

        let actions = PassthroughSubject<Action, Never>()

        var logAttributedText: NSAttributedString { logView.attributedText }

        // MARK: - Datos

        private let inAppSections: [Section] = [
            Section(title: "Dispositivo", items: [
                ActionItem(title: "1. DeviceIsAvailable()",
                           description: "Valida que el dispositivo tiene NFC, la integración con el SDK de HST es correcta y los entitlements de Apple Pay están configurados.",
                           action: .checkAvailability)
            ]),
            Section(title: "Tarjeta", showsCardSelector: true, items: [
                ActionItem(title: "2. CardIsProvisioned()",
                           description: "Valida si la tarjeta seleccionada ya está digitalizada en Wallet. Si ya tiene un pase activo, no puede volver a añadirse.",
                           action: .checkProvisioned),
                ActionItem(title: "3. StartInAppProvisioning()",
                           description: "Presenta la hoja nativa de Apple Pay para digitalizar la tarjeta seleccionada en Wallet.",
                           action: .addInApp)
            ])
        ]

        private let walletItems: [ActionItem] = [
            ActionItem(title: "1. status()",
                       description: "Qué responde la extensión a Wallet sobre disponibilidad y si requiere autenticación.",
                       action: .status),
            ActionItem(title: "2. passEntries()",
                       description: "Catálogo de tarjetas que la extensión muestra a Wallet: metadatos ligeros (id, red, últimos dígitos), sin datos cifrados.",
                       action: .passEntries),
            ActionItem(title: "3. Autorizar (login / biometría)",
                       description: "Presenta la UI de autorización que Wallet usa para validar al usuario.",
                       action: .authorize),
            ActionItem(title: "4. generateAddPaymentPassRequest",
                       description: "Entrega final de UNA tarjeta ya elegida: arma el PKAddPaymentPassRequest con el payload cifrado que Wallet mete en el Secure Element.",
                       action: .generate)
        ]

        // MARK: - Vistas

        private let segmentedControl = UISegmentedControl(items: Segment.allCases.map(\.title))
        private let inAppStack = UIStackView()
        private let walletStack = UIStackView()
        private let cardSelectorButton = UIButton(type: .system)
        private let cardSelectorTitleLabel = UILabel()
        private let logContainerView = UIView()
        private let logView = UITextView()

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            return formatter
        }()

        // MARK: - Init

        override init(frame: CGRect) {
            super.init(frame: frame)
            configureUI()
            updateVisibleSegment()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Log API

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

        // MARK: - Selector de tarjetas (In-app)

        func updateCards(_ options: [CardOption], selectedID: String?) {
            let menuActions = options.map { option in
                UIAction(title: option.menuTitle,
                         state: option.id == selectedID ? .on : .off) { [weak self] _ in
                    self?.actions.send(.selectCard(option.id))
                }
            }
            cardSelectorButton.menu = UIMenu(title: "Tarjetas", children: menuActions)
            cardSelectorButton.showsMenuAsPrimaryAction = true
            cardSelectorButton.isEnabled = !options.isEmpty

            let selected = options.first { $0.id == selectedID }
            cardSelectorTitleLabel.text = selected?.title ?? "Sin tarjetas"
            cardSelectorTitleLabel.textColor = selected == nil ? .secondaryLabel : .label
        }

        // MARK: - Segmentado

        private func updateVisibleSegment() {
            let segment = Segment(rawValue: segmentedControl.selectedSegmentIndex) ?? .inApp
            inAppStack.isHidden = segment != .inApp
            walletStack.isHidden = segment != .wallet
        }

        // MARK: - Layout

        private func configureUI() {
            backgroundColor = .systemBackground

            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.addAction(
                UIAction { [weak self] _ in self?.updateVisibleSegment() },
                for: .valueChanged
            )

            inAppStack.axis = .vertical
            inAppStack.spacing = 16
            inAppSections.map(makeSection).forEach(inAppStack.addArrangedSubview)

            configureActionStack(walletStack, items: walletItems)

            let topStack = UIStackView(arrangedSubviews: [segmentedControl, inAppStack, walletStack])
            topStack.axis = .vertical
            topStack.spacing = 16
            topStack.translatesAutoresizingMaskIntoConstraints = false

            addSubview(topStack)
            addSubview(logContainerView)
            configureLogContainer()

            NSLayoutConstraint.activate([
                topStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
                topStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                topStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

                logContainerView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 16),
                logContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                logContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
                logContainerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16)
            ])
        }

        private func configureActionStack(_ stack: UIStackView, items: [ActionItem]) {
            stack.axis = .vertical
            stack.spacing = 12
            items.map(makeCard).forEach(stack.addArrangedSubview)
        }

        private func configureLogContainer() {
            logContainerView.overrideUserInterfaceStyle = .dark
            logContainerView.backgroundColor = .secondarySystemBackground
            logContainerView.layer.cornerRadius = 14
            logContainerView.translatesAutoresizingMaskIntoConstraints = false

            let titleLabel = UILabel()
            titleLabel.text = "Console log"
            titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            titleLabel.textColor = .secondaryLabel
            titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let expandButton = makeIconButton(systemName: "arrow.up.left.and.arrow.down.right") { [weak self] in
                self?.actions.send(.expandLog)
            }
            let copyButton = makeIconButton(systemName: "doc.on.doc") { [weak self] in
                self?.actions.send(.copyLog)
            }
            let clearButton = makeIconButton(systemName: "trash") { [weak self] in
                self?.actions.send(.clearLog)
            }

            let buttonsStack = UIStackView(arrangedSubviews: [expandButton, copyButton, clearButton])
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

            logContainerView.addSubview(headerStack)
            logContainerView.addSubview(separator)
            logContainerView.addSubview(logView)

            NSLayoutConstraint.activate([
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

        // MARK: - Fábricas de vistas

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

        private func makeCardSelector() -> UIView {
            let container = UIView()
            container.backgroundColor = .secondarySystemBackground
            container.layer.cornerRadius = 12
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor.separator.cgColor

            let icon = UIImageView(image: UIImage(systemName: "creditcard.fill"))
            icon.tintColor = .tintColor
            icon.contentMode = .scaleAspectFit
            icon.setContentHuggingPriority(.required, for: .horizontal)

            cardSelectorTitleLabel.text = "Sin tarjetas"
            cardSelectorTitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
            cardSelectorTitleLabel.textColor = .label
            cardSelectorTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let chevron = UIImageView(image: UIImage(
                systemName: "chevron.up.chevron.down",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
            chevron.tintColor = .secondaryLabel
            chevron.contentMode = .scaleAspectFit
            chevron.setContentHuggingPriority(.required, for: .horizontal)

            let stack = UIStackView(arrangedSubviews: [icon, cardSelectorTitleLabel, chevron])
            stack.axis = .horizontal
            stack.spacing = 10
            stack.alignment = .center
            stack.isUserInteractionEnabled = false
            stack.translatesAutoresizingMaskIntoConstraints = false

            cardSelectorButton.configuration = nil
            cardSelectorButton.translatesAutoresizingMaskIntoConstraints = false

            container.addSubview(stack)
            container.addSubview(cardSelectorButton)

            NSLayoutConstraint.activate([
                container.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),

                stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
                stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

                cardSelectorButton.topAnchor.constraint(equalTo: container.topAnchor),
                cardSelectorButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                cardSelectorButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                cardSelectorButton.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            return container
        }

        private func makeSection(_ section: Section) -> UIView {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 8
            stack.addArrangedSubview(makeSectionHeader(section.title))
            if section.showsCardSelector {
                stack.addArrangedSubview(makeCardSelector())
            }
            section.items.map(makeCard).forEach(stack.addArrangedSubview)
            return stack
        }

        private func makeSectionHeader(_ title: String) -> UIView {
            let label = UILabel()
            label.text = title.uppercased()
            label.font = .systemFont(ofSize: 11, weight: .semibold)
            label.textColor = .secondaryLabel
            return label
        }

        private func makeCard(_ item: ActionItem) -> UIView {
            let container = UIView()
            container.backgroundColor = .secondarySystemBackground
            container.layer.cornerRadius = 12

            let titleLabel = UILabel()
            titleLabel.text = item.title
            titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
            titleLabel.numberOfLines = 0

            let descriptionLabel = UILabel()
            descriptionLabel.text = item.description
            descriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
            descriptionLabel.textColor = .secondaryLabel
            descriptionLabel.numberOfLines = 0

            let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
            textStack.axis = .vertical
            textStack.spacing = 4

            let chevron = UIImageView(image: UIImage(systemName: "chevron.right",
                                                     withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)))
            chevron.tintColor = .tertiaryLabel
            chevron.contentMode = .scaleAspectFit
            chevron.setContentHuggingPriority(.required, for: .horizontal)
            chevron.setContentCompressionResistancePriority(.required, for: .horizontal)

            let rowStack = UIStackView(arrangedSubviews: [textStack, chevron])
            rowStack.axis = .horizontal
            rowStack.alignment = .center
            rowStack.spacing = 8
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            let button = UIButton(type: .system)
            button.backgroundColor = .clear
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addAction(
                UIAction { [weak self] _ in self?.actions.send(item.action) },
                for: .touchUpInside
            )

            container.addSubview(rowStack)
            container.addSubview(button)

            NSLayoutConstraint.activate([
                rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 14),
                rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
                rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
                rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -14),

                button.topAnchor.constraint(equalTo: container.topAnchor),
                button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            return container
        }

        private func makeIconButton(systemName: String, handler: @escaping () -> Void) -> UIButton {
            var cfg = UIButton.Configuration.plain()
            cfg.image = UIImage(systemName: systemName,
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))
            cfg.baseForegroundColor = .secondaryLabel
            cfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
            let button = UIButton(configuration: cfg)
            button.addAction(UIAction { _ in handler() }, for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }
    }
}
