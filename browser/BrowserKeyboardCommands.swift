//
//  BrowserKeyboardCommands.swift
//  browser
//

import UIKit

enum BrowserKeyboardCommands {
    static func makeKeyCommands(
        sidebarSelector: Selector,
        spotlightSelector: Selector,
        dismissSelector: Selector
    ) -> [UIKeyCommand] {
        [
            UIKeyCommand(
                input: "\\",
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
                modifierFlags: [.command, .shift],
                action: spotlightSelector
            ),
            UIKeyCommand(
                input: UIKeyCommand.inputEscape,
                modifierFlags: [],
                action: dismissSelector
            ),
        ]
    }
}
