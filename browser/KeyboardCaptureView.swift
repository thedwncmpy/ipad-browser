//
//  KeyboardCaptureView.swift
//  browser
//
//  Created by Gemini CLI on 6/2/26.
//

import SwiftUI
import UIKit

struct KeyboardCaptureView: UIViewControllerRepresentable {
    let onNewWorkspace: () -> Void
    let onNewTab: () -> Void
    let onCloseWorkspace: () -> Void
    let onCloseTab: () -> Void
    let onReopenClosedTab: () -> Void
    let onNextWorkspace: () -> Void
    let onPreviousWorkspace: () -> Void
    let onNextTab: () -> Void
    let onPreviousTab: () -> Void
    let onMoveTabToNextWorkspace: () -> Void
    let onMoveTabToPreviousWorkspace: () -> Void
    let onMoveTabDown: () -> Void
    let onMoveTabUp: () -> Void
    let onToggleSidebar: () -> Void
    let onToggleSpotlight: () -> Void
    let onToggleCommandPalette: () -> Void
    let onToggleFind: () -> Void
    let onToggleHistory: () -> Void
    let onToggleSettings: () -> Void
    let onToggleNetworkTools: () -> Void
    let onSubmitSelection: () -> Void
    let onFocusFilter: () -> Void
    let onDismissSpotlight: () -> Void
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onReload: () -> Void
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let shortcuts: [BrowserShortcutAction: BrowserShortcut]
    let focusRequestID: Int?

    func makeUIViewController(context: Context) -> KeyCaptureViewController {
        let controller = KeyCaptureViewController()
        configure(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: KeyCaptureViewController, context: Context) {
        configure(uiViewController)
    }

    private func configure(_ controller: KeyCaptureViewController) {
        controller.onNewWorkspace = onNewWorkspace
        controller.onNewTab = onNewTab
        controller.onCloseWorkspace = onCloseWorkspace
        controller.onCloseTab = onCloseTab
        controller.onReopenClosedTab = onReopenClosedTab
        controller.onNextWorkspace = onNextWorkspace
        controller.onPreviousWorkspace = onPreviousWorkspace
        controller.onNextTab = onNextTab
        controller.onPreviousTab = onPreviousTab
        controller.onMoveTabToNextWorkspace = onMoveTabToNextWorkspace
        controller.onMoveTabToPreviousWorkspace = onMoveTabToPreviousWorkspace
        controller.onMoveTabDown = onMoveTabDown
        controller.onMoveTabUp = onMoveTabUp
        controller.onToggleSidebar = onToggleSidebar
        controller.onToggleSpotlight = onToggleSpotlight
        controller.onToggleCommandPalette = onToggleCommandPalette
        controller.onToggleFind = onToggleFind
        controller.onToggleHistory = onToggleHistory
        controller.onToggleSettings = onToggleSettings
        controller.onToggleNetworkTools = onToggleNetworkTools
        controller.onSubmitSelection = onSubmitSelection
        controller.onFocusFilter = onFocusFilter
        controller.onDismissSpotlight = onDismissSpotlight
        controller.onGoBack = onGoBack
        controller.onGoForward = onGoForward
        controller.onReload = onReload
        controller.onZoomIn = onZoomIn
        controller.onZoomOut = onZoomOut
        controller.shortcuts = shortcuts

        if let focusRequestID, controller.lastAppliedFocusRequestID != focusRequestID {
            controller.lastAppliedFocusRequestID = focusRequestID
            controller.activateResponder()
        }
    }
}

final class KeyCaptureViewController: UIViewController {
    var onNewWorkspace: (() -> Void)?
    var onNewTab: (() -> Void)?
    var onCloseWorkspace: (() -> Void)?
    var onCloseTab: (() -> Void)?
    var onReopenClosedTab: (() -> Void)?
    var onNextWorkspace: (() -> Void)?
    var onPreviousWorkspace: (() -> Void)?
    var onNextTab: (() -> Void)?
    var onPreviousTab: (() -> Void)?
    var onMoveTabToNextWorkspace: (() -> Void)?
    var onMoveTabToPreviousWorkspace: (() -> Void)?
    var onMoveTabDown: (() -> Void)?
    var onMoveTabUp: (() -> Void)?
    var onToggleSidebar: (() -> Void)?
    var onToggleSpotlight: (() -> Void)?
    var onToggleCommandPalette: (() -> Void)?
    var onToggleFind: (() -> Void)?
    var onToggleHistory: (() -> Void)?
    var onToggleSettings: (() -> Void)?
    var onToggleNetworkTools: (() -> Void)?
    var onSubmitSelection: (() -> Void)?
    var onFocusFilter: (() -> Void)?
    var onDismissSpotlight: (() -> Void)?
    var onGoBack: (() -> Void)?
    var onGoForward: (() -> Void)?
    var onReload: (() -> Void)?
    var onZoomIn: (() -> Void)?
    var onZoomOut: (() -> Void)?
    var shortcuts = BrowserShortcutStore.defaults
    var lastAppliedFocusRequestID: Int?

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        BrowserKeyboardCommands.makeKeyCommands(
            newWorkspaceSelector: #selector(createNewWorkspace(_:)),
            newTabSelector: #selector(createNewTab(_:)),
            closeWorkspaceSelector: #selector(closeCurrentWorkspace(_:)),
            closeTabSelector: #selector(closeCurrentTab(_:)),
            reopenClosedTabSelector: #selector(reopenClosedTab(_:)),
            nextWorkspaceSelector: #selector(selectNextWorkspace(_:)),
            previousWorkspaceSelector: #selector(selectPreviousWorkspace(_:)),
            nextTabSelector: #selector(selectNextTab(_:)),
            previousTabSelector: #selector(selectPreviousTab(_:)),
            moveTabToNextWorkspaceSelector: #selector(moveTabToNextWorkspace(_:)),
            moveTabToPreviousWorkspaceSelector: #selector(moveTabToPreviousWorkspace(_:)),
            moveTabDownSelector: #selector(moveTabDown(_:)),
            moveTabUpSelector: #selector(moveTabUp(_:)),
            sidebarSelector: #selector(handleSidebarToggle(_:)),
            spotlightSelector: #selector(toggleSpotlight(_:)),
            commandPaletteSelector: #selector(toggleCommandPalette(_:)),
            findSelector: #selector(toggleFind(_:)),
            historySelector: #selector(toggleHistory(_:)),
            settingsSelector: #selector(toggleSettings(_:)),
            dismissSelector: #selector(dismissSpotlight(_:)),
            backSelector: #selector(goBack(_:)),
            forwardSelector: #selector(goForward(_:)),
            reloadSelector: #selector(reloadPage(_:)),
            zoomInSelector: #selector(zoomIn(_:)),
            zoomOutSelector: #selector(zoomOut(_:)),
            networkToolsSelector: #selector(toggleNetworkTools(_:)),
            shortcuts: shortcuts
        ) + [
            shortcuts[.sidebarModeNextTab, default: BrowserShortcutStore.defaults[.sidebarModeNextTab]!].makeCommand(action: #selector(selectNextTab(_:))),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(selectNextTab(_:))),
            shortcuts[.sidebarModePreviousTab, default: BrowserShortcutStore.defaults[.sidebarModePreviousTab]!].makeCommand(action: #selector(selectPreviousTab(_:))),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(selectPreviousTab(_:))),
            shortcuts[.sidebarModePreviousWorkspace, default: BrowserShortcutStore.defaults[.sidebarModePreviousWorkspace]!].makeCommand(action: #selector(selectPreviousWorkspace(_:))),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(selectPreviousWorkspace(_:))),
            shortcuts[.sidebarModeNextWorkspace, default: BrowserShortcutStore.defaults[.sidebarModeNextWorkspace]!].makeCommand(action: #selector(selectNextWorkspace(_:))),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(selectNextWorkspace(_:))),
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(submitSelection(_:))),
            UIKeyCommand(input: "/", modifierFlags: [], action: #selector(focusFilter(_:)))
        ]
    }

    @objc private func createNewTab(_ sender: UIKeyCommand) {
        onNewTab?()
    }

    @objc private func createNewWorkspace(_ sender: UIKeyCommand) {
        onNewWorkspace?()
    }

    @objc private func closeCurrentTab(_ sender: UIKeyCommand) {
        onCloseTab?()
    }

    @objc private func reopenClosedTab(_ sender: UIKeyCommand) {
        onReopenClosedTab?()
    }

    @objc private func closeCurrentWorkspace(_ sender: UIKeyCommand) {
        onCloseWorkspace?()
    }

    @objc private func selectNextTab(_ sender: UIKeyCommand) {
        onNextTab?()
    }

    @objc private func selectPreviousTab(_ sender: UIKeyCommand) {
        onPreviousTab?()
    }

    @objc private func moveTabToNextWorkspace(_ sender: UIKeyCommand) {
        onMoveTabToNextWorkspace?()
    }

    @objc private func moveTabToPreviousWorkspace(_ sender: UIKeyCommand) {
        onMoveTabToPreviousWorkspace?()
    }

    @objc private func moveTabDown(_ sender: UIKeyCommand) {
        onMoveTabDown?()
    }

    @objc private func moveTabUp(_ sender: UIKeyCommand) {
        onMoveTabUp?()
    }

    @objc private func selectNextWorkspace(_ sender: UIKeyCommand) {
        onNextWorkspace?()
    }

    @objc private func selectPreviousWorkspace(_ sender: UIKeyCommand) {
        onPreviousWorkspace?()
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

    @objc private func toggleCommandPalette(_ sender: UIKeyCommand) {
        onToggleCommandPalette?()
    }

    @objc private func toggleFind(_ sender: UIKeyCommand) {
        onToggleFind?()
    }

    @objc private func toggleHistory(_ sender: UIKeyCommand) {
        onToggleHistory?()
    }

    @objc private func toggleSettings(_ sender: UIKeyCommand) {
        onToggleSettings?()
    }

    @objc private func toggleNetworkTools(_ sender: UIKeyCommand) {
        onToggleNetworkTools?()
    }

    @objc private func submitSelection(_ sender: UIKeyCommand) {
        onSubmitSelection?()
    }

    @objc private func focusFilter(_ sender: UIKeyCommand) {
        onFocusFilter?()
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

    @objc private func zoomIn(_ sender: UIKeyCommand) {
        onZoomIn?()
    }

    @objc private func zoomOut(_ sender: UIKeyCommand) {
        onZoomOut?()
    }
}
