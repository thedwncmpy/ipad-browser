//
//  OverlayShortcutTextField.swift
//  browser
//

import SwiftUI
import UIKit

struct OverlayShortcutTextField: UIViewRepresentable {
    enum ShortcutAction {
        case sidebar
        case spotlight
        case commandPalette
        case find
        case history
        case settings
        case networkTools
        case nextOption
        case previousOption
        case completeOption
        case submitOption
        case dismiss
    }

    @Binding var text: String
    let placeholder: String
    let fontName: String
    let fontSize: CGFloat
    let textColor: UIColor
    var autocompleteText: String? = nil
    let focusRequestID: Int?
    let onSubmit: () -> Void
    let onTextChange: ((String) -> Void)?
    let onShortcut: ((ShortcutAction) -> Void)?
    let shortcuts: [BrowserShortcutAction: BrowserShortcut]
    var usesBareNavigationShortcuts = false

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, onTextChange: onTextChange)
    }

    func makeUIView(context: Context) -> ShortcutAwareUITextField {
        let textField = ShortcutAwareUITextField()
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.returnKeyType = .go
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.clipsToBounds = true
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: ShortcutAwareUITextField, context: Context) {
        context.coordinator.onSubmit = onSubmit
        context.coordinator.onTextChange = onTextChange

        if uiView.text != text {
            uiView.text = text
        }

        uiView.placeholder = placeholder
        uiView.textColor = textColor
        uiView.tintColor = textColor
        uiView.font = UIFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        uiView.autocompleteText = autocompleteText ?? ""
        uiView.autocompleteTextColor = textColor.withAlphaComponent(0.32)
        uiView.shortcutHandler = onShortcut
        uiView.focusCoordinator = context.coordinator
        uiView.shortcuts = shortcuts
        uiView.usesBareNavigationShortcuts = usesBareNavigationShortcuts

        if let focusRequestID, context.coordinator.lastAppliedFocusRequestID != focusRequestID {
            context.coordinator.lastAppliedFocusRequestID = focusRequestID
            context.coordinator.pendingFocusRequest = true
            uiView.applyPendingFocusIfNeeded()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        var onSubmit: () -> Void
        var onTextChange: ((String) -> Void)?
        var lastAppliedFocusRequestID: Int?
        var pendingFocusRequest = false

        init(text: Binding<String>, onSubmit: @escaping () -> Void, onTextChange: ((String) -> Void)?) {
            _text = text
            self.onSubmit = onSubmit
            self.onTextChange = onTextChange
        }

        @objc func textDidChange(_ sender: UITextField) {
            let newValue = sender.text ?? ""
            text = newValue
            onTextChange?(newValue)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onSubmit()
            return false
        }
    }
}

final class ShortcutAwareUITextField: UITextField {
    var shortcutHandler: ((OverlayShortcutTextField.ShortcutAction) -> Void)?
    weak var focusCoordinator: OverlayShortcutTextField.Coordinator?
    var shortcuts = BrowserShortcutStore.defaults
    var usesBareNavigationShortcuts = false
    var autocompleteText = "" {
        didSet {
            autocompleteLabel.text = autocompleteText
            setNeedsLayout()
        }
    }
    var autocompleteTextColor = UIColor.white.withAlphaComponent(0.32) {
        didSet {
            autocompleteLabel.textColor = autocompleteTextColor
        }
    }

    private let autocompleteLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAutocompleteLabel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAutocompleteLabel()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyPendingFocusIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutAutocompleteLabel()
    }

    override var font: UIFont? {
        didSet {
            autocompleteLabel.font = font
            setNeedsLayout()
        }
    }

    override var text: String? {
        didSet {
            setNeedsLayout()
        }
    }

    private func configureAutocompleteLabel() {
        autocompleteLabel.backgroundColor = .clear
        autocompleteLabel.isUserInteractionEnabled = false
        autocompleteLabel.textColor = autocompleteTextColor
        autocompleteLabel.lineBreakMode = .byClipping
        addSubview(autocompleteLabel)
    }

    private func layoutAutocompleteLabel() {
        let typedText = text ?? ""
        guard !typedText.isEmpty, !autocompleteText.isEmpty else {
            autocompleteLabel.frame = .zero
            return
        }

        let bounds = textRect(forBounds: bounds)
        let typedWidth = textWidth(for: typedText)
        let remainingWidth = max(0, bounds.width - typedWidth)
        autocompleteLabel.frame = CGRect(
            x: bounds.minX + typedWidth,
            y: bounds.minY,
            width: remainingWidth,
            height: bounds.height
        )
    }

    private func textWidth(for text: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? .systemFont(ofSize: UIFont.systemFontSize)
        ]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }

    func applyPendingFocusIfNeeded() {
        guard window != nil, focusCoordinator?.pendingFocusRequest == true else { return }

        focusCoordinator?.pendingFocusRequest = false
        DispatchQueue.main.async {
            _ = self.becomeFirstResponder()
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands = [
            shortcuts[.sidebar, default: BrowserShortcutStore.defaults[.sidebar]!].makeCommand(action: #selector(handleSidebarShortcut(_:))),
            shortcuts[.spotlight, default: BrowserShortcutStore.defaults[.spotlight]!].makeCommand(action: #selector(handleSpotlightShortcut(_:))),
            shortcuts[.spotlightAlternate, default: BrowserShortcutStore.defaults[.spotlightAlternate]!].makeCommand(action: #selector(handleSpotlightShortcut(_:))),
            shortcuts[.commandPalette, default: BrowserShortcutStore.defaults[.commandPalette]!].makeCommand(action: #selector(handleCommandPaletteShortcut(_:))),
            shortcuts[.find, default: BrowserShortcutStore.defaults[.find]!].makeCommand(action: #selector(handleFindShortcut(_:))),
            shortcuts[.history, default: BrowserShortcutStore.defaults[.history]!].makeCommand(action: #selector(handleHistoryShortcut(_:))),
            shortcuts[.settings, default: BrowserShortcutStore.defaults[.settings]!].makeCommand(action: #selector(handleSettingsShortcut(_:))),
            shortcuts[.networkTools, default: BrowserShortcutStore.defaults[.networkTools]!].makeCommand(action: #selector(handleNetworkToolsShortcut(_:))),
            prioritizedKeyCommand(input: "j", modifiers: [.control], action: #selector(handleNextOptionShortcut(_:))),
            prioritizedKeyCommand(input: "k", modifiers: [.control], action: #selector(handlePreviousOptionShortcut(_:))),
            prioritizedKeyCommand(input: "\t", modifiers: [], action: #selector(handleCompleteOptionShortcut(_:))),
            shortcuts[.dismiss, default: BrowserShortcutStore.defaults[.dismiss]!].makeCommand(action: #selector(handleDismissShortcut(_:)))
        ]

        if usesBareNavigationShortcuts {
            commands.append(contentsOf: [
                prioritizedKeyCommand(input: "j", modifiers: [], action: #selector(handleNextOptionShortcut(_:))),
                prioritizedKeyCommand(input: UIKeyCommand.inputDownArrow, modifiers: [], action: #selector(handleNextOptionShortcut(_:))),
                prioritizedKeyCommand(input: "k", modifiers: [], action: #selector(handlePreviousOptionShortcut(_:))),
                prioritizedKeyCommand(input: UIKeyCommand.inputUpArrow, modifiers: [], action: #selector(handlePreviousOptionShortcut(_:))),
                prioritizedKeyCommand(input: "\r", modifiers: [], action: #selector(handleSubmitOptionShortcut(_:)))
            ])
        }

        return commands
    }

    private func prioritizedKeyCommand(input: String, modifiers: UIKeyModifierFlags, action: Selector) -> UIKeyCommand {
        let command = UIKeyCommand(input: input, modifierFlags: modifiers, action: action)
        command.wantsPriorityOverSystemBehavior = true
        return command
    }

    @objc private func handleSidebarShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.sidebar)
    }

    @objc private func handleSpotlightShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.spotlight)
    }

    @objc private func handleCommandPaletteShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.commandPalette)
    }

    @objc private func handleFindShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.find)
    }

    @objc private func handleHistoryShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.history)
    }

    @objc private func handleSettingsShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.settings)
    }

    @objc private func handleNetworkToolsShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.networkTools)
    }

    @objc private func handleNextOptionShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.nextOption)
    }

    @objc private func handlePreviousOptionShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.previousOption)
    }

    @objc private func handleCompleteOptionShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.completeOption)
    }

    @objc private func handleSubmitOptionShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.submitOption)
    }

    @objc private func handleDismissShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.dismiss)
    }
}
