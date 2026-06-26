//
//  MenuViewController.swift
//  SBPPersonalBanking
//

import UIKit
import LocalAuthentication

final class MenuViewController: UIViewController {

    private let viewModel = MenuViewModel()
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let faceIDContainerView = UIView()
    private let faceIDTitleLabel = UILabel()
    private let faceIDSubtitleLabel = UILabel()
    private let faceIDSwitch = UISwitch()
    private let logoutButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    private func configureUI() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.title = "Menu"

        titleLabel.text = "Sesión"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        subtitleLabel.text = "Administra el acceso de esta app demo."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        faceIDTitleLabel.text = "Activar Face ID"
        faceIDTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)

        faceIDSubtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        faceIDSubtitleLabel.textColor = .secondaryLabel
        faceIDSubtitleLabel.numberOfLines = 0

        faceIDSwitch.isOn = viewModel.isFaceIDEnabled
        faceIDSwitch.addTarget(self, action: #selector(faceIDSwitchChanged), for: .valueChanged)

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

        var logoutConfiguration = UIButton.Configuration.filled()
        logoutConfiguration.title = "Cerrar sesión"
        logoutConfiguration.baseBackgroundColor = .systemRed
        logoutConfiguration.baseForegroundColor = .white
        logoutConfiguration.cornerStyle = .large
        logoutButton.configuration = logoutConfiguration
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(faceIDContainerView)
        stackView.addArrangedSubview(logoutButton)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        refreshFaceIDUI()
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Cerrar sesión",
            message: "Volverás al login. El usuario local seguirá guardado.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cerrar sesión", style: .destructive) { [weak self] _ in
            self?.logout()
        })
        present(alert, animated: true)
    }

    private func logout() {
        guard let window = view.window else { return }
        let loginNavigationController = UINavigationController(rootViewController: LoginViewController())
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = loginNavigationController
        }
    }

    @objc private func faceIDSwitchChanged() {
        guard viewModel.hasLocalUser else {
            faceIDSwitch.setOn(false, animated: true)
            refreshFaceIDUI()
            return
        }

        if faceIDSwitch.isOn && !isBiometryAvailable() {
            faceIDSwitch.setOn(false, animated: true)
            let alert = UIAlertController(
                title: "Face ID no disponible",
                message: "Este dispositivo no tiene biometría disponible en este momento.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            refreshFaceIDUI()
            return
        }

        viewModel.setFaceIDEnabled(faceIDSwitch.isOn)
        refreshFaceIDUI()
    }

    private func refreshFaceIDUI() {
        let hasLocalUser = viewModel.hasLocalUser
        faceIDSwitch.isEnabled = hasLocalUser
        faceIDSwitch.isOn = viewModel.isFaceIDEnabled
        faceIDSubtitleLabel.text = hasLocalUser
            ? "Permite mostrar Face ID en el login mientras exista cookieJoy."
            : "Necesitas un usuario local con cookieJoy para activar Face ID."
    }

    private func isBiometryAvailable() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}
