//
//  BrowserKeyboardCommands.swift
//  browser
//

import UIKit

enum BrowserKeyboardCommands {
    static func makeKeyCommands(
        newWorkspaceSelector: Selector,
        newTabSelector: Selector,
        closeWorkspaceSelector: Selector,
        closeTabSelector: Selector,
        nextWorkspaceSelector: Selector,
        previousWorkspaceSelector: Selector,
        nextTabSelector: Selector,
        previousTabSelector: Selector,
        sidebarSelector: Selector,
        spotlightSelector: Selector,
        commandPaletteSelector: Selector,
        findSelector: Selector,
        dismissSelector: Selector,
        backSelector: Selector,
        forwardSelector: Selector,
        reloadSelector: Selector
    ) -> [UIKeyCommand] {
        [
            UIKeyCommand(
                input: "n",
                modifierFlags: [.command],
                action: newWorkspaceSelector
            ),
            UIKeyCommand(
                input: "t",
                modifierFlags: [.command],
                action: newTabSelector
            ),
            UIKeyCommand(
                input: "w",
                modifierFlags: [.command, .shift],
                action: closeWorkspaceSelector
            ),
            UIKeyCommand(
                input: "w",
                modifierFlags: [.command],
                action: closeTabSelector
            ),
            UIKeyCommand(
                input: "h",
                modifierFlags: [.control],
                action: previousWorkspaceSelector
            ),
            UIKeyCommand(
                input: "l",
                modifierFlags: [.control],
                action: nextWorkspaceSelector
            ),
            UIKeyCommand(
                input: "j",
                modifierFlags: [.control],
                action: nextTabSelector
            ),
            UIKeyCommand(
                input: "k",
                modifierFlags: [.control],
                action: previousTabSelector
            ),
            UIKeyCommand(
                input: "/",
                modifierFlags: [.command],
                action: sidebarSelector
            ),
            UIKeyCommand(
                input: "l",
                modifierFlags: [.command],
                action: spotlightSelector
            ),
            UIKeyCommand(
                input: " ",
                modifierFlags: [.alternate],
                action: commandPaletteSelector
            ),
            UIKeyCommand(
                input: "f",
                modifierFlags: [.command],
                action: findSelector
            ),
            UIKeyCommand(
                input: " ",
                modifierFlags: [.command, .shift],
                action: spotlightSelector
            ),
            UIKeyCommand(
                input: UIKeyCommand.inputEscape,
                modifierFlags: [],
                action: dismissSelector
            ),
            UIKeyCommand(
                input: "[",
                modifierFlags: [.command],
                action: backSelector
            ),
            UIKeyCommand(
                input: "]",
                modifierFlags: [.command],
                action: forwardSelector
            ),
            UIKeyCommand(
                input: "r",
                modifierFlags: [.command],
                action: reloadSelector
            ),
        ]
    }
}
