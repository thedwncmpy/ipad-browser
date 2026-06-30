//
//  BrowserWorkspace.swift
//  browser
//

import Foundation

@MainActor
final class BrowserWorkspace: Identifiable {
    let id = UUID()
    var tabs: [BrowserTab]
    var selectedTabID: UUID?

    init(tabs: [BrowserTab]? = nil, selectedTabID: UUID? = nil) {
        let resolvedTabs = tabs ?? [BrowserTab()]
        self.tabs = resolvedTabs
        self.selectedTabID = selectedTabID ?? resolvedTabs.first?.id
    }
}
