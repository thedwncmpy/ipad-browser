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
        case nextOption
        case previousOption
        case dismiss
    }

    @Binding var text: String
    let placeholder: String
    let fontName: String
    let fontSize: CGFloat
    let textColor: UIColor
    let focusRequestID: Int?
    let onSubmit: () -> Void
    let onTextChange: ((String) -> Void)?
    let onShortcut: ((ShortcutAction) -> Void)?

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
        uiView.shortcutHandler = onShortcut
        uiView.focusCoordinator = context.coordinator

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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyPendingFocusIfNeeded()
    }

    func applyPendingFocusIfNeeded() {
        guard window != nil, focusCoordinator?.pendingFocusRequest == true else { return }

        focusCoordinator?.pendingFocusRequest = false
        DispatchQueue.main.async {
            _ = self.becomeFirstResponder()
        }
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            prioritizedKeyCommand(input: "/", modifiers: [.command], action: #selector(handleSidebarShortcut(_:))),
            prioritizedKeyCommand(input: "l", modifiers: [.command], action: #selector(handleSpotlightShortcut(_:))),
            prioritizedKeyCommand(input: " ", modifiers: [.alternate], action: #selector(handleCommandPaletteShortcut(_:))),
            prioritizedKeyCommand(input: "f", modifiers: [.command], action: #selector(handleFindShortcut(_:))),
            prioritizedKeyCommand(input: "j", modifiers: [.control], action: #selector(handleNextOptionShortcut(_:))),
            prioritizedKeyCommand(input: "k", modifiers: [.control], action: #selector(handlePreviousOptionShortcut(_:))),
            prioritizedKeyCommand(input: UIKeyCommand.inputEscape, modifiers: [], action: #selector(handleDismissShortcut(_:)))
        ]
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

    @objc private func handleNextOptionShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.nextOption)
    }

    @objc private func handlePreviousOptionShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.previousOption)
    }

    @objc private func handleDismissShortcut(_ sender: UIKeyCommand) {
        shortcutHandler?(.dismiss)
    }
}
