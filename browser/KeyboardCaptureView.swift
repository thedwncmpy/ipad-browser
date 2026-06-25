//
//  KeyboardCaptureView.swift
//  browser
//
//  Created by Gemini CLI on 6/2/26.
//

import SwiftUI
import UIKit

struct KeyboardCaptureView: UIViewControllerRepresentable {
    let onToggleSidebar: () -> Void
    let onToggleSpotlight: () -> Void
    let onToggleFind: () -> Void
    let onDismissSpotlight: () -> Void
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onReload: () -> Void

    func makeUIViewController(context: Context) -> KeyCaptureViewController {
        let controller = KeyCaptureViewController()
        configure(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: KeyCaptureViewController, context: Context) {
        configure(uiViewController)
    }

    private func configure(_ controller: KeyCaptureViewController) {
        controller.onToggleSidebar = onToggleSidebar
        controller.onToggleSpotlight = onToggleSpotlight
        controller.onToggleFind = onToggleFind
        controller.onDismissSpotlight = onDismissSpotlight
        controller.onGoBack = onGoBack
        controller.onGoForward = onGoForward
        controller.onReload = onReload
        controller.activateResponder()
    }
}

final class KeyCaptureViewController: UIViewController {
    var onToggleSidebar: (() -> Void)?
    var onToggleSpotlight: (() -> Void)?
    var onToggleFind: (() -> Void)?
    var onDismissSpotlight: (() -> Void)?
    var onGoBack: (() -> Void)?
    var onGoForward: (() -> Void)?
    var onReload: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        BrowserKeyboardCommands.makeKeyCommands(
            sidebarSelector: #selector(handleSidebarToggle(_:)),
            spotlightSelector: #selector(toggleSpotlight(_:)),
            findSelector: #selector(toggleFind(_:)),
            dismissSelector: #selector(dismissSpotlight(_:)),
            backSelector: #selector(goBack(_:)),
            forwardSelector: #selector(goForward(_:)),
            reloadSelector: #selector(reloadPage(_:))
        )
    }

    override func loadView() {
        view = UIView(frame: .zero)
        view.isHidden = true
        view.isUserInteractionEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        activateResponder()
    }

    func activateResponder() {
        DispatchQueue.main.async {
            _ = self.becomeFirstResponder()
        }
    }

    @objc private func handleSidebarToggle(_ sender: UIKeyCommand) {
        onToggleSidebar?()
    }

    @objc private func toggleSpotlight(_ sender: UIKeyCommand) {
        onToggleSpotlight?()
    }

    @objc private func toggleFind(_ sender: UIKeyCommand) {
        onToggleFind?()
    }

    @objc private func dismissSpotlight(_ sender: UIKeyCommand) {
        onDismissSpotlight?()
    }

    @objc private func goBack(_ sender: UIKeyCommand) {
        onGoBack?()
    }

    @objc private func goForward(_ sender: UIKeyCommand) {
        onGoForward?()
    }

    @objc private func reloadPage(_ sender: UIKeyCommand) {
        onReload?()
    }
}
