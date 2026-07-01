//
//  ViewController.swift
//  DemoAppleWallet
//
//  Demo home screen: lists the customer's cards and lets them add each one to
//  Apple Wallet using the standard in-app provisioning flow. The same cards are
//  shared (via the App Group) with the Wallet discovery extensions.
//

import UIKit
import PassKit
import Combine
import SBPShared

final class CardsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let viewModel = CardsViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var cards: [WalletCard] = []
    private var expandedCardIDs: Set<String> = []
    private lazy var syncButton = UIBarButtonItem(
        image: UIImage(systemName: "arrow.down.circle"),
        style: .plain,
        target: self,
        action: #selector(syncTapped)
    )
    private lazy var emptyStateView = makeEmptyStateView()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    // MARK: - Bindings (Combine)

    private func bindViewModel() {
        viewModel.$cards
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cards in
                self?.cards = cards
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                self?.setSyncing(loading)
                self?.updateEmptyState()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.presentAlert("No se pudo sincronizar",
                                   "\(message)\n\n¿Está corriendo Mockoon en http://localhost:5001?")
            }
            .store(in: &cancellables)
    }

    // MARK: - UI

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = "Cards"

        navigationItem.leftBarButtonItem = syncButton
        #if DEBUG
        let sandboxItem = UIBarButtonItem(
            image: UIImage(systemName: "testtube.2"),
            style: .plain,
            target: self,
            action: #selector(sandboxTapped)
        )
        navigationItem.rightBarButtonItem = sandboxItem
        #endif

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CardCell.self, forCellReuseIdentifier: CardCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Empty state

    private func makeEmptyStateView() -> UIView {
        let imageView = UIImageView(image: UIImage(systemName: "creditcard"))
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)

        let titleLabel = UILabel()
        titleLabel.text = "Aún no tienes tarjetas"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Sincroniza para traer tus tarjetas disponibles."
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.setCustomSpacing(16, after: imageView)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -40)
        ])
        return container
    }

    private func updateEmptyState() {
        let showEmpty = cards.isEmpty && !viewModel.isLoading
        tableView.backgroundView = showEmpty ? emptyStateView : nil
    }

    // MARK: - Actions

    #if DEBUG
    @objc private func sandboxTapped() {
        navigationController?.pushViewController(ProvisioningSandboxViewController(), animated: true)
    }
    #endif

    @objc private func syncTapped() {
        viewModel.sync()
    }

    private func setSyncing(_ syncing: Bool) {
        if syncing {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.startAnimating()
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: spinner)
        } else {
            navigationItem.leftBarButtonItem = syncButton
        }
    }

    private func presentAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table data source / delegate

extension CardsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        nil
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.reuseID, for: indexPath) as! CardCell
        let card = cards[indexPath.row]
        cell.configure(
            with: card,
            isExpanded: expandedCardIDs.contains(card.cardID),
            onToggleDetails: { [weak self, weak tableView] in
                guard let self else { return }
                if self.expandedCardIDs.contains(card.cardID) {
                    self.expandedCardIDs.remove(card.cardID)
                } else {
                    self.expandedCardIDs.insert(card.cardID)
                }
                tableView?.performBatchUpdates(nil)
            }
        )
        return cell
    }
}
