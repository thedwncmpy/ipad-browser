//
//  BrowserShortcut.swift
//  browser
//

import UIKit

enum BrowserShortcutAction: String, CaseIterable, Codable, Identifiable {
    case newWorkspace
    case newTab
    case closeWorkspace
    case closeTab
    case previousWorkspace
    case nextWorkspace
    case nextTab
    case previousTab
    case moveTabToPreviousWorkspace
    case moveTabToNextWorkspace
    case moveTabDown
    case moveTabUp
    case sidebar
    case spotlight
    case spotlightAlternate
    case commandPalette
    case find
    case settings
    case dismiss
    case back
    case forward
    case reload
    case sidebarModePreviousWorkspace
    case sidebarModeNextWorkspace
    case sidebarModeNextTab
    case sidebarModePreviousTab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newWorkspace:
            return "New Workspace"
        case .newTab:
            return "New Tab"
        case .closeWorkspace:
            return "Close Workspace"
        case .closeTab:
            return "Close Tab"
        case .previousWorkspace:
            return "Previous Workspace"
        case .nextWorkspace:
            return "Next Workspace"
        case .nextTab:
            return "Next Tab"
        case .previousTab:
            return "Previous Tab"
        case .moveTabToPreviousWorkspace:
            return "Move Tab to Previous Workspace"
        case .moveTabToNextWorkspace:
            return "Move Tab to Next Workspace"
        case .moveTabDown:
            return "Move Tab Down"
        case .moveTabUp:
            return "Move Tab Up"
        case .sidebar:
            return "Sidebar"
        case .spotlight:
            return "Spotlight"
        case .spotlightAlternate:
            return "Spotlight Alternate"
        case .commandPalette:
            return "Command Palette"
        case .find:
            return "Find"
        case .settings:
            return "Settings"
        case .dismiss:
            return "Dismiss Overlay"
        case .back:
            return "Back"
        case .forward:
            return "Forward"
        case .reload:
            return "Reload"
        case .sidebarModePreviousWorkspace:
            return "Sidebar Mode Previous Workspace"
        case .sidebarModeNextWorkspace:
            return "Sidebar Mode Next Workspace"
        case .sidebarModeNextTab:
            return "Sidebar Mode Next Tab"
        case .sidebarModePreviousTab:
            return "Sidebar Mode Previous Tab"
        }
    }
}

struct BrowserShortcut: Codable, Equatable {
    let input: String
    let modifierRawValue: Int

    var modifiers: UIKeyModifierFlags {
        UIKeyModifierFlags(rawValue: modifierRawValue)
    }

    init(input: String, modifiers: UIKeyModifierFlags) {
        self.input = input
        self.modifierRawValue = modifiers.rawValue
    }

    func makeCommand(action: Selector) -> UIKeyCommand {
        let command = UIKeyCommand(input: input, modifierFlags: modifiers, action: action)
        command.wantsPriorityOverSystemBehavior = true
        return command
    }

    var displayText: String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("Cmd") }
        if modifiers.contains(.shift) { parts.append("Shift") }
        if modifiers.contains(.alternate) { parts.append("Option") }
        if modifiers.contains(.control) { parts.append("Ctrl") }
        parts.append(displayInput)
        return parts.joined(separator: " ")
    }

    private var displayInput: String {
        switch input {
        case " ":
            return "Space"
        case UIKeyCommand.inputEscape:
            return "Esc"
        case UIKeyCommand.inputUpArrow:
            return "Up"
        case UIKeyCommand.inputDownArrow:
            return "Down"
        case UIKeyCommand.inputLeftArrow:
            return "Left"
        case UIKeyCommand.inputRightArrow:
            return "Right"
        default:
            return input.uppercased()
        }
    }
}

enum BrowserShortcutStore {
    private static let defaultsKey = "browser.shortcuts.v1"

    static let defaults: [BrowserShortcutAction: BrowserShortcut] = [
        .newWorkspace: BrowserShortcut(input: "n", modifiers: [.command]),
        .newTab: BrowserShortcut(input: "t", modifiers: [.command]),
        .closeWorkspace: BrowserShortcut(input: "w", modifiers: [.command, .shift]),
        .closeTab: BrowserShortcut(input: "w", modifiers: [.command]),
        .previousWorkspace: BrowserShortcut(input: "h", modifiers: [.control]),
        .nextWorkspace: BrowserShortcut(input: "l", modifiers: [.control]),
        .nextTab: BrowserShortcut(input: "j", modifiers: [.control]),
        .previousTab: BrowserShortcut(input: "k", modifiers: [.control]),
        .moveTabToPreviousWorkspace: BrowserShortcut(input: "h", modifiers: [.control, .shift]),
        .moveTabToNextWorkspace: BrowserShortcut(input: "l", modifiers: [.control, .shift]),
        .moveTabDown: BrowserShortcut(input: "j", modifiers: [.control, .shift]),
        .moveTabUp: BrowserShortcut(input: "k", modifiers: [.control, .shift]),
        .sidebar: BrowserShortcut(input: "/", modifiers: [.command]),
        .spotlight: BrowserShortcut(input: "l", modifiers: [.command]),
        .spotlightAlternate: BrowserShortcut(input: " ", modifiers: [.command, .shift]),
        .commandPalette: BrowserShortcut(input: " ", modifiers: [.alternate]),
        .find: BrowserShortcut(input: "f", modifiers: [.command]),
        .settings: BrowserShortcut(input: ",", modifiers: [.command]),
        .dismiss: BrowserShortcut(input: UIKeyCommand.inputEscape, modifiers: []),
        .back: BrowserShortcut(input: "[", modifiers: [.command]),
        .forward: BrowserShortcut(input: "]", modifiers: [.command]),
        .reload: BrowserShortcut(input: "r", modifiers: [.command]),
        .sidebarModePreviousWorkspace: BrowserShortcut(input: "h", modifiers: []),
        .sidebarModeNextWorkspace: BrowserShortcut(input: "l", modifiers: []),
        .sidebarModeNextTab: BrowserShortcut(input: "j", modifiers: []),
        .sidebarModePreviousTab: BrowserShortcut(input: "k", modifiers: [])
    ]

    static func load() -> [BrowserShortcutAction: BrowserShortcut] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([BrowserShortcutAction: BrowserShortcut].self, from: data)
        else {
            return defaults
        }

        return defaults.merging(decoded) { _, custom in custom }
    }

    static func save(_ shortcuts: [BrowserShortcutAction: BrowserShortcut]) {
        guard let data = try? JSONEncoder().encode(shortcuts) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
