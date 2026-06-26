//
//  ViewController.swift
//  SBPPersonalBanking
//
//  Demo home screen: lists the customer's cards and lets them add each one to
//  Apple Wallet using the standard in-app provisioning flow. The same cards are
//  shared (via the App Group) with the Wallet discovery extensions.
//

import UIKit
import PassKit
import Combine

final class CardsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let walletManager = WalletProvisioningManager()
    private let viewModel = CardsViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var cards: [BankCard] = []
    private lazy var syncButton = UIBarButtonItem(
        image: UIImage(systemName: "arrow.down.circle"),
        style: .plain,
        target: self,
        action: #selector(syncTapped)
    )

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
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in self?.setSyncing(loading) }
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
        let resetItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )
        #if DEBUG
        let sandboxItem = UIBarButtonItem(
            image: UIImage(systemName: "ladybug.fill"),
            style: .plain,
            target: self,
            action: #selector(sandboxTapped)
        )
        navigationItem.rightBarButtonItems = [resetItem, sandboxItem]
        #else
        navigationItem.rightBarButtonItem = resetItem
        #endif

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CardCell.self, forCellReuseIdentifier: CardCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func resetTapped() {
        let alert = UIAlertController(
            title: "Eliminar tarjetas",
            message: "Esto borrará todas las tarjetas guardadas localmente. Podrás recuperarlas sincronizando otra vez desde Mockoon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            self?.viewModel.reset()
        })
        present(alert, animated: true)
    }

    #if DEBUG
    @objc private func sandboxTapped() {
        navigationController?.pushViewController(SandboxViewController(), animated: true)
    }
    #endif

    /// Pide al ViewModel sincronizar (él llama a CoreRequestManager).
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

    private func addToWallet(_ card: BankCard) {
        walletManager.startProvisioning(for: card, from: self) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .added:
                self.viewModel.reload()
            case .cancelled:
                break
            case .failed(let error):
                self.presentAlert("Could not add card", error.localizedDescription)
            case .unsupported:
                self.presentAlert(
                    "Apple Pay unavailable",
                    "Adding a card to Wallet requires a real device with Apple Pay and the issuer provisioning entitlement. On Simulator this flow can't be completed, but the card data and extensions are fully wired."
                )
            }
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
        "Your cards"
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Cards not yet in Wallet are offered to Apple Wallet by the provisioning extension."
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.reuseID, for: indexPath) as! CardCell
        let card = cards[indexPath.row]
        cell.configure(with: card) { [weak self] in
            self?.addToWallet(card)
        }
        return cell
    }
}
