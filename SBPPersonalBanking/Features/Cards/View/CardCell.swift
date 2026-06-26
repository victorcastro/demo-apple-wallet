//
//  CardCell.swift
//  SBPPersonalBanking
//
//  Table cell that renders a card's art plus an "Add to Apple Wallet" button
//  (or an "Added to Wallet" badge when already provisioned).
//

import UIKit
import PassKit

final class CardCell: UITableViewCell {

    static let reuseID = "CardCell"

    private let artView = UIImageView()
    private let statusLabel = UILabel()
    private let addButton = PKAddPassButton(addPassButtonStyle: .black)
    private let coreDataDetailsContainer = UIStackView()
    private var onAdd: (() -> Void)?

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

        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.textColor = .systemGreen
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        coreDataDetailsContainer.axis = .vertical
        coreDataDetailsContainer.spacing = 10
        coreDataDetailsContainer.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        coreDataDetailsContainer.isLayoutMarginsRelativeArrangement = true
        coreDataDetailsContainer.backgroundColor = .secondarySystemGroupedBackground
        coreDataDetailsContainer.layer.cornerRadius = 12
        coreDataDetailsContainer.layer.masksToBounds = true
        coreDataDetailsContainer.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(artView)
        contentView.addSubview(addButton)
        contentView.addSubview(statusLabel)
        contentView.addSubview(coreDataDetailsContainer)

        NSLayoutConstraint.activate([
            artView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            artView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            artView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            artView.heightAnchor.constraint(equalTo: artView.widthAnchor, multiplier: 0.6),

            addButton.topAnchor.constraint(equalTo: artView.bottomAnchor, constant: 12),
            addButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            addButton.heightAnchor.constraint(equalToConstant: 44),

            statusLabel.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            statusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            coreDataDetailsContainer.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 12),
            coreDataDetailsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coreDataDetailsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            coreDataDetailsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with card: BankCard, onAdd: @escaping () -> Void) {
        self.onAdd = onAdd
        artView.image = CardArtRenderer.image(for: card)

        if card.isProvisioned {
            addButton.isHidden = true
            statusLabel.isHidden = false
            statusLabel.text = "✓ Added to Apple Wallet"
        } else {
            addButton.isHidden = false
            statusLabel.isHidden = true
        }

        configureCoreDataDetails(for: card)
    }

    @objc private func addTapped() {
        onAdd?()
    }

    private func configureCoreDataDetails(for card: BankCard) {
        coreDataDetailsContainer.arrangedSubviews.forEach { view in
            coreDataDetailsContainer.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let headerLabel = UILabel()
        headerLabel.text = "CardEntity"
        headerLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        headerLabel.textColor = .label
        coreDataDetailsContainer.addArrangedSubview(headerLabel)

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
            coreDataDetailsContainer.addArrangedSubview(makeDetailRow(title: title, value: value))
        }

        coreDataDetailsContainer.addArrangedSubview(
            makeLongDetailBlock(title: "cardImageBase64", value: Self.preview(card.cardImageBase64))
        )
        coreDataDetailsContainer.addArrangedSubview(
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
