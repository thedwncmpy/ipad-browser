//
//  KeyboardCaptureView.swift
//  browser
//
//  Created by Gemini CLI on 6/2/26.
//

import SwiftUI
import UIKit

struct KeyboardCaptureView: UIViewControllerRepresentable {
    let handleAction: (BrowserKeyboardAction) -> Void
    let shortcuts: [BrowserShortcutAction: BrowserShortcut]
    let focusRequestID: Int?
    let usesTabHorizontalNavigation: Bool

    func makeUIViewController(context: Context) -> KeyCaptureViewController {
        let controller = KeyCaptureViewController()
        configure(controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: KeyCaptureViewController, context: Context) {
        configure(uiViewController)
    }

    private func configure(_ controller: KeyCaptureViewController) {
        controller.handleAction = handleAction
        controller.shortcuts = shortcuts
        controller.usesTabHorizontalNavigation = usesTabHorizontalNavigation

        if let focusRequestID, controller.lastAppliedFocusRequestID != focusRequestID {
            controller.lastAppliedFocusRequestID = focusRequestID
            controller.activateResponder()
        }
    }
}

final class KeyCaptureViewController: UIViewController {
    var handleAction: ((BrowserKeyboardAction) -> Void)?
    var shortcuts = BrowserShortcutStore.defaults
    var lastAppliedFocusRequestID: Int?
    var usesTabHorizontalNavigation = false

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
            shortcuts[.sidebarModePreviousWorkspace, default: BrowserShortcutStore.defaults[.sidebarModePreviousWorkspace]!].makeCommand(action: usesTabHorizontalNavigation ? #selector(selectPreviousHorizontalNavigation(_:)) : #selector(selectPreviousWorkspace(_:))),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: usesTabHorizontalNavigation ? #selector(selectPreviousHorizontalNavigation(_:)) : #selector(selectPreviousWorkspace(_:))),
            shortcuts[.sidebarModeNextWorkspace, default: BrowserShortcutStore.defaults[.sidebarModeNextWorkspace]!].makeCommand(action: usesTabHorizontalNavigation ? #selector(selectNextHorizontalNavigation(_:)) : #selector(selectNextWorkspace(_:))),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: usesTabHorizontalNavigation ? #selector(selectNextHorizontalNavigation(_:)) : #selector(selectNextWorkspace(_:))),
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(submitSelection(_:))),
            UIKeyCommand(input: "/", modifierFlags: [], action: #selector(focusFilter(_:)))
        ]
    }

    @objc private func createNewTab(_ sender: UIKeyCommand) {
        dispatch(.newTab)
    }

    @objc private func createNewWorkspace(_ sender: UIKeyCommand) {
        dispatch(.newWorkspace)
    }

    @objc private func closeCurrentTab(_ sender: UIKeyCommand) {
        dispatch(.closeTab)
    }

    @objc private func reopenClosedTab(_ sender: UIKeyCommand) {
        dispatch(.reopenClosedTab)
    }

    @objc private func closeCurrentWorkspace(_ sender: UIKeyCommand) {
        dispatch(.closeWorkspace)
    }

    @objc private func selectNextTab(_ sender: UIKeyCommand) {
        dispatch(.nextTab)
    }

    @objc private func selectPreviousTab(_ sender: UIKeyCommand) {
        dispatch(.previousTab)
    }

    @objc private func selectNextHorizontalNavigation(_ sender: UIKeyCommand) {
        dispatch(.nextHorizontalNavigation)
    }

    @objc private func selectPreviousHorizontalNavigation(_ sender: UIKeyCommand) {
        dispatch(.previousHorizontalNavigation)
    }

    @objc private func moveTabToNextWorkspace(_ sender: UIKeyCommand) {
        dispatch(.moveTabToNextWorkspace)
    }

    @objc private func moveTabToPreviousWorkspace(_ sender: UIKeyCommand) {
        dispatch(.moveTabToPreviousWorkspace)
    }

    @objc private func moveTabDown(_ sender: UIKeyCommand) {
        dispatch(.moveTabDown)
    }

    @objc private func moveTabUp(_ sender: UIKeyCommand) {
        dispatch(.moveTabUp)
    }

    @objc private func selectNextWorkspace(_ sender: UIKeyCommand) {
        dispatch(.nextWorkspace)
    }

    @objc private func selectPreviousWorkspace(_ sender: UIKeyCommand) {
        dispatch(.previousWorkspace)
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
        dispatch(.toggleSidebar)
    }

    @objc private func toggleSpotlight(_ sender: UIKeyCommand) {
        dispatch(.toggleSpotlight)
    }

    @objc private func toggleCommandPalette(_ sender: UIKeyCommand) {
        dispatch(.toggleCommandPalette)
    }

    @objc private func toggleFind(_ sender: UIKeyCommand) {
        dispatch(.toggleFind)
    }

    @objc private func toggleHistory(_ sender: UIKeyCommand) {
        dispatch(.toggleHistory)
    }

    @objc private func toggleSettings(_ sender: UIKeyCommand) {
        dispatch(.toggleSettings)
    }

    @objc private func toggleNetworkTools(_ sender: UIKeyCommand) {
        dispatch(.toggleNetworkTools)
    }

    @objc private func submitSelection(_ sender: UIKeyCommand) {
        dispatch(.submitSelection)
    }

    @objc private func focusFilter(_ sender: UIKeyCommand) {
        dispatch(.focusFilter)
    }

    @objc private func dismissSpotlight(_ sender: UIKeyCommand) {
        dispatch(.dismissOverlay)
    }

    @objc private func goBack(_ sender: UIKeyCommand) {
        dispatch(.goBack)
    }

    @objc private func goForward(_ sender: UIKeyCommand) {
        dispatch(.goForward)
    }

    @objc private func reloadPage(_ sender: UIKeyCommand) {
        dispatch(.reload)
    }

    @objc private func zoomIn(_ sender: UIKeyCommand) {
        dispatch(.zoomIn)
    }

    @objc private func zoomOut(_ sender: UIKeyCommand) {
        dispatch(.zoomOut)
    }

    private func dispatch(_ action: BrowserKeyboardAction) {
        handleAction?(action)
    }
}
