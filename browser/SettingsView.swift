//
//  SettingsView.swift
//  browser
//

import SwiftUI
import UIKit

struct SettingsView: View {
    private enum Style {
        static let fieldWidth: CGFloat = 620
        static let fieldHeight: CGFloat = 72
        static let rowHeight: CGFloat = 52
        static let cornerRadius: CGFloat = 18
        static let horizontalPadding: CGFloat = 24
        static let fontName = "LilexNFM-Regular"
        static let backgroundColor = Color.black.opacity(0.82)
        static let borderColor = Color.white.opacity(0.18)
    }

    @Binding var shortcuts: [BrowserShortcutAction: BrowserShortcut]
    let onDismiss: () -> Void
    @State private var recordingAction: BrowserShortcutAction?
    @State private var recorderFocusRequestID = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Text("Settings")
                            .font(.custom(Style.fontName, size: 24))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Button {
                            resetShortcuts()
                        } label: {
                            Text("Reset Shortcuts")
                                .font(.custom(Style.fontName, size: 14))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Style.horizontalPadding)
                    .frame(height: Style.fieldHeight)

                    shortcutSection
                        .frame(maxHeight: min(Style.rowHeight * CGFloat(BrowserShortcutAction.allCases.count), geometry.size.height * 0.58))
                }
                .frame(width: Style.fieldWidth)
                .background(Style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                        .stroke(Style.borderColor, lineWidth: 1)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, max(0, geometry.size.height * 0.25 - Style.fieldHeight / 2))
        }
        .ignoresSafeArea()
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
        Button {
            recordingAction = action
            recorderFocusRequestID += 1
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.title)
                        .font(.custom(Style.fontName, size: 16))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(recordingAction == action ? "Press a new shortcut" : shortcut(for: action).displayText)
                        .font(.custom(Style.fontName, size: 12))
                        .foregroundStyle(recordingAction == action ? Color.black.opacity(0.72) : Color.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(shortcut(for: action).displayText)
                    .font(.custom(Style.fontName, size: 14))
                    .foregroundStyle(recordingAction == action ? Color.black : Color.white.opacity(0.82))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 30)
                    .background(recordingAction == action ? Color.black.opacity(0.08) : Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 18)
            .frame(height: Style.rowHeight, alignment: .leading)
        }
        .buttonStyle(.plain)
        .background(recordingAction == action ? Color.white : Color.clear)
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
