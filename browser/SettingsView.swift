//
//  SettingsView.swift
//  browser
//

import SwiftUI
import UIKit

struct SettingsView: View {
    private enum Style {
        static let width: CGFloat = 680
        static let maxHeight: CGFloat = 720
        static let rowHeight: CGFloat = 54
        static let cornerRadius: CGFloat = 14
        static let fontName = "LilexNFM-Regular"
    }

    @Binding var shortcuts: [BrowserShortcutAction: BrowserShortcut]
    let onDismiss: () -> Void
    @State private var recordingAction: BrowserShortcutAction?
    @State private var recorderFocusRequestID = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.custom(Style.fontName, size: 22))
                        .foregroundStyle(.white)

                    Spacer()

                    Button("Reset Shortcuts") {
                        resetShortcuts()
                    }
                    .font(.custom(Style.fontName, size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .frame(height: 62)

                Divider().overlay(Color.white.opacity(0.12))

                shortcutSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: Style.width)
            .frame(maxHeight: Style.maxHeight)
            .background(Color.black.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous))
            .overlay {
                ShortcutRecorderView(
                    isRecording: recordingAction != nil,
                    focusRequestID: recorderFocusRequestID == 0 ? nil : recorderFocusRequestID,
                    onShortcut: recordShortcut,
                    onDismiss: {
                        recordingAction = nil
                    }
                )
                .frame(width: 1, height: 1)
                .opacity(0)
            }
        }
    }

    private var shortcutSection: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(BrowserShortcutAction.allCases) { action in
                    shortcutRow(for: action)

                    if action != BrowserShortcutAction.allCases.last {
                        Divider().overlay(Color.white.opacity(0.08))
                    }
                }
            }
        }
    }

    private func resetShortcuts() {
        shortcuts = BrowserShortcutStore.defaults
        BrowserShortcutStore.save(shortcuts)
    }

    private func shortcutRow(for action: BrowserShortcutAction) -> some View {
        HStack(spacing: 14) {
            Text(action.title)
                .font(.custom(Style.fontName, size: 16))
                .foregroundStyle(.white)

            Spacer()

            Button {
                recordingAction = action
                recorderFocusRequestID += 1
            } label: {
                Text(recordingAction == action ? "Press keys" : shortcut(for: action).displayText)
                    .font(.custom(Style.fontName, size: 14))
                    .foregroundStyle(recordingAction == action ? .black : .white)
                    .frame(minWidth: 128, minHeight: 34)
                    .background(recordingAction == action ? Color.white : Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .frame(height: Style.rowHeight)
    }

    private func shortcut(for action: BrowserShortcutAction) -> BrowserShortcut {
        shortcuts[action] ?? BrowserShortcutStore.defaults[action]!
    }

    private func recordShortcut(_ shortcut: BrowserShortcut) {
        guard let recordingAction else { return }

        shortcuts[recordingAction] = shortcut
        BrowserShortcutStore.save(shortcuts)
        self.recordingAction = nil
    }
}

private struct ShortcutRecorderView: UIViewControllerRepresentable {
    let isRecording: Bool
    let focusRequestID: Int?
    let onShortcut: (BrowserShortcut) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> ShortcutRecorderViewController {
        let controller = ShortcutRecorderViewController()
        configure(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: ShortcutRecorderViewController, context: Context) {
        configure(uiViewController)
    }

    private func configure(_ controller: ShortcutRecorderViewController) {
        controller.isRecording = isRecording
        controller.onShortcut = onShortcut
        controller.onDismiss = onDismiss

        if isRecording, let focusRequestID, controller.lastAppliedFocusRequestID != focusRequestID {
            controller.lastAppliedFocusRequestID = focusRequestID
            controller.activateResponder()
        }
    }
}

private final class ShortcutRecorderViewController: UIViewController {
    var isRecording = false
    var onShortcut: ((BrowserShortcut) -> Void)?
    var onDismiss: (() -> Void)?
    var lastAppliedFocusRequestID: Int?

    override var canBecomeFirstResponder: Bool { true }

    override func loadView() {
        view = UIView(frame: .zero)
        view.isHidden = true
    }

    func activateResponder() {
        DispatchQueue.main.async {
            _ = self.becomeFirstResponder()
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard isRecording, let key = presses.first?.key else {
            super.pressesBegan(presses, with: event)
            return
        }

        let input = key.charactersIgnoringModifiers.isEmpty ? key.characters : key.charactersIgnoringModifiers
        guard !input.isEmpty else { return }

        onShortcut?(BrowserShortcut(input: input.lowercased(), modifiers: key.modifierFlags))
    }
}
