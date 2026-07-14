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
        reopenClosedTabSelector: Selector,
        nextWorkspaceSelector: Selector,
        previousWorkspaceSelector: Selector,
        nextTabSelector: Selector,
        previousTabSelector: Selector,
        moveTabToNextWorkspaceSelector: Selector,
        moveTabToPreviousWorkspaceSelector: Selector,
        moveTabDownSelector: Selector,
        moveTabUpSelector: Selector,
        sidebarSelector: Selector,
        spotlightSelector: Selector,
        commandPaletteSelector: Selector,
        findSelector: Selector,
        historySelector: Selector,
        settingsSelector: Selector,
        dismissSelector: Selector,
        backSelector: Selector,
        forwardSelector: Selector,
        reloadSelector: Selector,
        networkToolsSelector: Selector,
        shortcuts: [BrowserShortcutAction: BrowserShortcut]
    ) -> [UIKeyCommand] {
        let selectorByAction: [BrowserShortcutAction: Selector] = [
            .newWorkspace: newWorkspaceSelector,
            .newTab: newTabSelector,
            .closeWorkspace: closeWorkspaceSelector,
            .closeTab: closeTabSelector,
            .reopenClosedTab: reopenClosedTabSelector,
            .previousWorkspace: previousWorkspaceSelector,
            .nextWorkspace: nextWorkspaceSelector,
            .nextTab: nextTabSelector,
            .previousTab: previousTabSelector,
            .moveTabToPreviousWorkspace: moveTabToPreviousWorkspaceSelector,
            .moveTabToNextWorkspace: moveTabToNextWorkspaceSelector,
            .moveTabDown: moveTabDownSelector,
            .moveTabUp: moveTabUpSelector,
            .sidebar: sidebarSelector,
            .spotlight: spotlightSelector,
            .spotlightAlternate: spotlightSelector,
            .commandPalette: commandPaletteSelector,
            .find: findSelector,
            .history: historySelector,
            .settings: settingsSelector,
            .dismiss: dismissSelector,
            .back: backSelector,
            .forward: forwardSelector,
            .reload: reloadSelector,
            .networkTools: networkToolsSelector
        ]

        let commands = BrowserShortcutAction.allCases.compactMap { action -> UIKeyCommand? in
            guard let selector = selectorByAction[action],
                  let fallback = BrowserShortcutStore.defaults[action]
            else { return nil }

            return shortcuts[action, default: fallback].makeCommand(action: selector)
        }

        return commands.map { command in
            command.wantsPriorityOverSystemBehavior = true
            return command
        }
    }
}
