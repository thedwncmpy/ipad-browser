//
//  BrowserKeyboardCommands.swift
//  browser
//

import UIKit

enum BrowserKeyboardCommands {
    static func makeKeyCommands(
        sidebarSelector: Selector,
        spotlightSelector: Selector,
        findSelector: Selector,
        dismissSelector: Selector,
        backSelector: Selector,
        forwardSelector: Selector,
        reloadSelector: Selector
    ) -> [UIKeyCommand] {
        [
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
