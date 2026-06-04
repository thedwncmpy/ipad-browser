//
//  KeyboardCaptureView.swift
//  browser
//
//  Created by Gemini CLI on 6/2/26.
//

import SwiftUI
import UIKit

struct KeyboardCaptureView: UIViewRepresentable {
    let onToggleSidebar: () -> Void
    let onToggleSpotlight: () -> Void
    let onDismissSpotlight: () -> Void

    func makeUIView(context: Context) -> KeyCaptureUIView {
        let view = KeyCaptureUIView()
        view.onToggleSidebar = onToggleSidebar
        view.onToggleSpotlight = onToggleSpotlight
        view.onDismissSpotlight = onDismissSpotlight

        DispatchQueue.main.async {
            view.becomeFirstResponder()
        }

        return view
    }

    func updateUIView(_ uiView: KeyCaptureUIView, context: Context) {
        uiView.onToggleSidebar = onToggleSidebar
        uiView.onToggleSpotlight = onToggleSpotlight
        uiView.onDismissSpotlight = onDismissSpotlight

        if !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }
}

final class KeyCaptureUIView: UIView {
    var onToggleSidebar: (() -> Void)?
    var onToggleSpotlight: (() -> Void)?
    var onDismissSpotlight: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(
                input: "\\",
                modifierFlags: [.command],
                action: #selector(handleSidebarToggle(_:))
            ),
            UIKeyCommand(
                input: "l",
                modifierFlags: [.command],
                action: #selector(toggleSpotlight(_:))
            ),
            UIKeyCommand(
                input: " ",
                modifierFlags: [.command, .shift],
                action: #selector(toggleSpotlight(_:))
            ),
            UIKeyCommand(
                input: UIKeyCommand.inputEscape,
                modifierFlags: [],
                action: #selector(dismissSpotlight(_:))
            ),
        ]
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        DispatchQueue.main.async {
            self.becomeFirstResponder()
        }
    }

    @objc private func handleSidebarToggle(_ sender: UIKeyCommand) {
        onToggleSidebar?()
    }

    @objc private func toggleSpotlight(_ sender: UIKeyCommand) {
        onToggleSpotlight?()
    }

    @objc private func dismissSpotlight(_ sender: UIKeyCommand) {
        onDismissSpotlight?()
    }
}
