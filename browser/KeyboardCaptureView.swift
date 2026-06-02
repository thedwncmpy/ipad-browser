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

    func makeUIView(context: Context) -> KeyCaptureUIView {
        let view = KeyCaptureUIView()
        view.onToggleSidebar = onToggleSidebar

        DispatchQueue.main.async {
            view.becomeFirstResponder()
        }

        return view
    }

    func updateUIView(_ uiView: KeyCaptureUIView, context: Context) {
        uiView.onToggleSidebar = onToggleSidebar

        if !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }
}

final class KeyCaptureUIView: UIView {
    var onToggleSidebar: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        DispatchQueue.main.async {
            self.becomeFirstResponder()
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else {
                continue
            }

            let isCommandPressed = key.modifierFlags.contains(.command)
            let isBackslash = key.charactersIgnoringModifiers == "\\"

            if isCommandPressed && isBackslash {
                onToggleSidebar?()
                return
            }
        }

        super.pressesBegan(presses, with: event)
    }
}
