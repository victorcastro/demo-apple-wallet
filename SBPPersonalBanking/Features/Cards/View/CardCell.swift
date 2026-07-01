//
//  CardCell.swift
//  DemoAppleWallet
//
//  Table cell that renders a card's art, an "Added to Wallet" badge when the
//  card is already provisioned, and the expandable CoreData detail block.
//

import UIKit
import SBPShared

final class CardCell: UITableViewCell {

    static let reuseID = "CardCell"

    private let artView = UIImageView()
    private let statusLabel = UILabel()
    private let coreDataDetailsContainer = UIStackView()
    private let detailsHeader = UIStackView()
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let detailsBody = UIStackView()
    private var onToggleDetails: (() -> Void)?
    private var isDetailsExpanded = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none

        artView.contentMode = .scaleAspectFit
        artView.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        statusLabel.textColor = .systemGreen
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        coreDataDetailsContainer.axis = .vertical
        coreDataDetailsContainer.spacing = 10
        coreDataDetailsContainer.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        coreDataDetailsContainer.isLayoutMarginsRelativeArrangement = true
        coreDataDetailsContainer.backgroundColor = .secondarySystemGroupedBackground
        coreDataDetailsContainer.layer.cornerRadius = 12
        coreDataDetailsContainer.layer.masksToBounds = true
        coreDataDetailsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Header tocable: chevron + título. Alterna la visibilidad del cuerpo.
        chevronView.tintColor = .secondaryLabel
        chevronView.contentMode = .center
        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevronView.setContentHuggingPriority(.required, for: .horizontal)

        let headerTitle = UILabel()
        headerTitle.text = "Datos en CoreData (CardEntity)"
        headerTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        headerTitle.textColor = .label

        detailsHeader.axis = .horizontal
        detailsHeader.spacing = 8
        detailsHeader.alignment = .center
        detailsHeader.addArrangedSubview(chevronView)
        detailsHeader.addArrangedSubview(headerTitle)
        detailsHeader.addArrangedSubview(UIView())   // spacer: hace tocable toda la fila
        detailsHeader.isUserInteractionEnabled = true
        detailsHeader.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(toggleDetailsTapped))
        )

        detailsBody.axis = .vertical
        detailsBody.spacing = 10

        coreDataDetailsContainer.addArrangedSubview(detailsHeader)
        coreDataDetailsContainer.addArrangedSubview(detailsBody)

        contentView.addSubview(artView)
        contentView.addSubview(statusLabel)
        contentView.addSubview(coreDataDetailsContainer)

        NSLayoutConstraint.activate([
            artView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            artView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            artView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.62),
            artView.heightAnchor.constraint(equalTo: artView.widthAnchor, multiplier: 0.6),

            statusLabel.topAnchor.constraint(equalTo: artView.bottomAnchor, constant: 8),
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            coreDataDetailsContainer.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            coreDataDetailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coreDataDetailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            coreDataDetailsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with card: WalletCard,
                   isExpanded: Bool,
                   onToggleDetails: @escaping () -> Void) {
        self.onToggleDetails = onToggleDetails
        artView.image = WalletCardUtils.image(for: card)

        if card.isProvisioned {
            statusLabel.isHidden = false
            statusLabel.text = "✓ Added to Apple Wallet"
        } else {
            statusLabel.isHidden = true
            statusLabel.text = nil
        }

        configureCoreDataDetails(for: card)
        isDetailsExpanded = isExpanded
        setDetails(expanded: isExpanded)
    }

    @objc private func toggleDetailsTapped() {
        isDetailsExpanded.toggle()
        UIView.animate(withDuration: 0.25) {
            self.setDetails(expanded: self.isDetailsExpanded)
            self.contentView.layoutIfNeeded()
        }
        onToggleDetails?()
    }

    /// Muestra/oculta el cuerpo de detalles y orienta el chevron.
    private func setDetails(expanded: Bool) {
        detailsBody.isHidden = !expanded
        chevronView.transform = expanded ? CGAffineTransform(rotationAngle: .pi / 2) : .identity
    }

    private func configureCoreDataDetails(for card: WalletCard) {
        detailsBody.arrangedSubviews.forEach { view in
            detailsBody.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let rows: [(String, String)] = [
            ("cardID", card.cardID),
            ("cardHolderName", card.cardHolderName),
            ("cardType", card.cardType),
            ("lastFourDigits", card.lastFourDigits),
            ("localizedDescription", card.localizedDescription),
            ("paymentNetwork", card.paymentNetwork),
            ("isProvisioned", String(card.isProvisioned))
        ]

        rows.forEach { title, value in
            detailsBody.addArrangedSubview(makeDetailRow(title: title, value: value))
        }

        detailsBody.addArrangedSubview(
            makeLongDetailBlock(title: "cardImageBase64", value: Self.preview(card.cardImageBase64))
        )
        detailsBody.addArrangedSubview(
            makeLongDetailBlock(title: "encCard", value: Self.preview(card.encCard))
        )
    }

    private func makeDetailRow(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.numberOfLines = 1

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 12
        return stack
    }

    private func makeLongDetailBlock(title: String, value: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private static func preview(_ value: String, limit: Int = 160) -> String {
        guard value.count > limit else { return value }
        let index = value.index(value.startIndex, offsetBy: limit)
        return "\(value[..<index])... (\(value.count) chars)"
    }
}
