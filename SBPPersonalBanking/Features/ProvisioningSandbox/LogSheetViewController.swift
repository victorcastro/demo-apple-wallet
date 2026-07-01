import UIKit

final class LogSheetViewController: UIViewController {

    private let content: NSAttributedString
    private let onCopy: () -> Void
    private let onClear: () -> Void

    private let logView = UITextView()

    init(content: NSAttributedString,
         onCopy: @escaping () -> Void,
         onClear: @escaping () -> Void) {
        self.content = content
        self.onCopy = onCopy
        self.onClear = onClear
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = .black

        let titleLabel = UILabel()
        titleLabel.text = "Console log — Provisioning"
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let minimizeButton = makeIconButton(systemName: "arrow.down.right.and.arrow.up.left") { [weak self] in
            self?.dismiss(animated: true)
        }
        let copyButton = makeIconButton(systemName: "doc.on.doc") { [weak self] in
            self?.onCopy()
        }
        let clearButton = makeIconButton(systemName: "trash") { [weak self] in
            self?.onClear()
            self?.logView.attributedText = NSAttributedString(string: "")
        }

        let buttonsStack = UIStackView(arrangedSubviews: [minimizeButton, copyButton, clearButton])
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
        logView.attributedText = content
        logView.backgroundColor = .clear
        logView.textContainerInset = UIEdgeInsets(top: 16, left: 20, bottom: 24, right: 20)
        logView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerStack)
        view.addSubview(separator)
        view.addSubview(logView)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            separator.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 10),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            logView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            logView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            logView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            logView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
