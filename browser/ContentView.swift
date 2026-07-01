//
//  ContentView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct ContentView: View {
    private enum FavoriteStore {
        static let defaultsKey = "browser.favorites"
    }

    private enum ActiveOverlay {
        case none
        case sidebar
        case spotlight
        case commandPalette
        case find
    }

    private enum ShortcutAction {
        case newWorkspace
        case newTab
        case closeWorkspace
        case closeTab
        case nextWorkspace
        case previousWorkspace
        case nextTab
        case previousTab
        case sidebar
        case spotlight
        case commandPalette
        case find
        case dismiss
    }

    private enum BrowserCommand: CaseIterable {
        case newWorkspace
        case newTab
        case closeWorkspace
        case closeTab
        case nextWorkspace
        case previousWorkspace
        case nextTab
        case previousTab

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
            case .nextWorkspace:
                return "Next Workspace"
            case .previousWorkspace:
                return "Previous Workspace"
            case .nextTab:
                return "Next Tab"
            case .previousTab:
                return "Previous Tab"
            }
        }

        var queryTokens: [String] {
            switch self {
            case .newWorkspace: ["ow", "new workspace", "workspace", "create workspace", "open workspace"]
            case .newTab: ["ot", "new tab", "tab", "create tab", "open tab"]
            case .closeWorkspace: ["cw", "close workspace", "delete workspace", "kill workspace"]
            case .closeTab: ["ct", "close tab", "delete tab", "kill tab", "close current tab"]
            case .nextWorkspace: ["next workspace", "workspace right"]
            case .previousWorkspace: ["previous workspace", "workspace left"]
            case .nextTab: ["next tab", "tab right"]
            case .previousTab: ["previous tab", "tab left"]
            }
        }
    }

    private struct CommandPaletteTabMatch: Identifiable {
        let id: String
        let workspaceID: UUID
        let tabID: UUID
        let title: String
        let subtitle: String
    }

    private enum CommandPaletteSuggestionKind {
        case openNew(String)
        case openTabMatch(CommandPaletteTabMatch)
    }

    private struct CommandPaletteSuggestionItem: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let kind: CommandPaletteSuggestionKind
    }

    @State private var activeOverlay: ActiveOverlay = .none
    @State private var workspaces: [BrowserWorkspace] = [BrowserWorkspace()]
    @State private var selectedWorkspaceID: UUID? = nil
    @State private var sidebarURLText = BrowserHomePage.url.absoluteString
    @State private var spotlightText = ""
    @State private var spotlightFocusRequestID = 0
    @State private var commandPaletteText = ""
    @State private var commandPaletteFocusRequestID = 0
    @State private var commandPaletteSelectionIndex = 0
    @State private var commandPaletteOriginWorkspaceID: UUID? = nil
    @State private var commandPaletteOriginTabID: UUID? = nil
    @State private var findText = ""
    @State private var findStatus = BrowserFindStatus.empty
    @State private var sidebarURLFocusRequestID = 0
    @State private var favorites: [BrowserFavorite] = []
    @State private var tabRenderVersion = 0
    @State private var lastShortcutAction: ShortcutAction?
    @State private var lastShortcutTimestamp = Date.distantPast
    private let shortcutCoalescingInterval: TimeInterval = 0.08

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
            sidebar
            spotlight
            commandPalette
            findOverlay
            keyboardCaptureLayer
        }
        .onAppear {
            if selectedWorkspaceID == nil {
                selectedWorkspaceID = workspaces.first?.id
            }
            favorites = loadFavorites()
            syncSidebarURLText()
        }
        .onChange(of: selectedWorkspaceID) { _, _ in
            ensureWorkspaceSelectionIntegrity()
            syncSidebarURLText()
            clearFindState()
        }
        .onChange(of: activeWorkspace?.selectedTabID) { _, _ in
            syncSidebarURLText()
            clearFindState()
        }
    }

    private var activeWorkspace: BrowserWorkspace? {
        guard let selectedWorkspaceID else { return workspaces.first }
        return workspaces.first(where: { $0.id == selectedWorkspaceID }) ?? workspaces.first
    }

    private var activeWorkspaceIndex: Int? {
        guard let selectedWorkspaceID else { return workspaces.isEmpty ? nil : 0 }
        return workspaces.firstIndex(where: { $0.id == selectedWorkspaceID })
    }

    private var activeTabs: [BrowserTab] {
        activeWorkspace?.tabs ?? []
    }

    private var activeTab: BrowserTab? {
        guard let workspace = activeWorkspace else { return nil }
        guard let selectedTabID = workspace.selectedTabID else { return workspace.tabs.first }
        return workspace.tabs.first(where: { $0.id == selectedTabID }) ?? workspace.tabs.first
    }

    private var activeTabIndex: Int? {
        guard let workspace = activeWorkspace else { return nil }
        guard let selectedTabID = workspace.selectedTabID else { return workspace.tabs.isEmpty ? nil : 0 }
        return workspace.tabs.firstIndex(where: { $0.id == selectedTabID })
    }

    private var sidebarItems: [SidebarTabItem] {
        _ = tabRenderVersion
        return activeTabs.enumerated().map { index, tab in
            SidebarTabItem(
                id: tab.id,
                title: title(for: tab, index: index),
                currentURLString: tab.currentURLString,
                currentPageURL: tab.currentPageURL
            )
        }
    }

    private var mainContent: some View {
        ZStack {
            ForEach(workspaces) { workspace in
                ForEach(tabsToRender(in: workspace)) { tab in
                    BrowserWebView(
                        url: binding(for: tab, keyPath: \.currentPageURL),
                        currentURLString: binding(for: tab, keyPath: \.currentURLString),
                        navigationController: tab.navigationController,
                        onNewWorkspace: createNewWorkspace,
                        onNewTab: createNewTab,
                        onCloseWorkspace: closeCurrentWorkspace,
                        onCloseTab: closeCurrentTab,
                        onNextWorkspace: selectNextWorkspace,
                        onPreviousWorkspace: selectPreviousWorkspace,
                        onNextTab: selectNextTab,
                        onPreviousTab: selectPreviousTab,
                        onToggleSidebar: toggleSidebar,
                        onToggleSpotlight: toggleSpotlight,
                        onToggleCommandPalette: toggleCommandPalette,
                        onToggleFind: toggleFind,
                        onDismissOverlay: dismissSpotlight,
                        onGoBack: goBack,
                        onGoForward: goForward,
                        onReload: reload
                    )
                    .ignoresSafeArea()
                    .opacity(isVisible(tab: tab, in: workspace) ? 1 : 0)
                    .allowsHitTesting(isVisible(tab: tab, in: workspace))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var sidebar: some View {
        if activeOverlay == .sidebar, let activeTab {
            SidebarView(
                urlText: $sidebarURLText,
                currentPageURL: activeTab.currentPageURL,
                tabs: sidebarItems,
                selectedTabID: activeTab.id,
                workspaceCount: workspaces.count,
                selectedWorkspaceIndex: activeWorkspaceIndex ?? 0,
                urlFieldFocusRequestID: sidebarURLFocusRequestID == 0 ? nil : sidebarURLFocusRequestID,
                onSelectTab: selectTab,
                onCloseTab: closeTab,
                onSidebarShortcut: toggleSidebar,
                onSpotlightShortcut: toggleSpotlight,
                onCommandPaletteShortcut: toggleCommandPalette,
                onFindShortcut: toggleFind,
                onDismiss: dismissSpotlight,
                onSubmit: submitSidebarURL
            )
            .transition(.move(edge: .leading))
            .zIndex(1)
        }
    }

    @ViewBuilder
    private var spotlight: some View {
        if activeOverlay == .spotlight, let activeTab {
            SpotlightView(
                text: $spotlightText,
                pageURL: activeTab.currentPageURL,
                showsFavicon: true,
                focusRequestID: spotlightFocusRequestID == 0 ? nil : spotlightFocusRequestID,
                onSidebarShortcut: toggleSidebar,
                onFindShortcut: toggleFind,
                onSpotlightShortcut: toggleSpotlight,
                onSubmit: submitSpotlight,
                onDismiss: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        activeOverlay = .none
                    }
                }
            )
            .zIndex(1)
        }
    }

    @ViewBuilder
    private var commandPalette: some View {
        if activeOverlay == .commandPalette {
            SpotlightView(
                text: $commandPaletteText,
                placeholder: "Command",
                focusRequestID: commandPaletteFocusRequestID == 0 ? nil : commandPaletteFocusRequestID,
                suggestions: commandPaletteSuggestions,
                onTextChange: { _ in resetCommandPaletteSelection() },
                onSidebarShortcut: toggleSidebar,
                onFindShortcut: toggleFind,
                onSpotlightShortcut: toggleSpotlight,
                onCommandPaletteShortcut: toggleCommandPalette,
                onNextSuggestionShortcut: selectNextCommandPaletteSuggestion,
                onPreviousSuggestionShortcut: selectPreviousCommandPaletteSuggestion,
                onSubmit: submitCommandPalette,
                onDismiss: {
                    closeCommandPalette(restoreSelection: true)
                }
            )
            .zIndex(1)
        }
    }

    private var findOverlay: some View {
        SpotlightView(
            text: $findText,
            isVisible: activeOverlay == .find,
            placeholder: "Find on page",
            trailingText: findStatus.total > 0 ? "\(findStatus.current)/\(findStatus.total)" : nil,
            onTextChange: updateFindResults,
            onSidebarShortcut: toggleSidebar,
            onFindShortcut: toggleFind,
            onSpotlightShortcut: toggleSpotlight,
            onSubmit: {
                activeTab?.navigationController.findNext { status in
                    findStatus = status
                }
            },
            onDismiss: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    activeOverlay = .none
                }
                clearFindState()
            }
        )
        .zIndex(activeOverlay == .find ? 1 : -1)
    }

    @ViewBuilder
    private var keyboardCaptureLayer: some View {
        if activeOverlay == .none || activeOverlay == .sidebar {
            KeyboardCaptureView(
                onNewWorkspace: createNewWorkspace,
                onNewTab: createNewTab,
                onCloseWorkspace: closeCurrentWorkspace,
                onCloseTab: closeCurrentTab,
                onNextWorkspace: selectNextWorkspace,
                onPreviousWorkspace: selectPreviousWorkspace,
                onNextTab: selectNextTab,
                onPreviousTab: selectPreviousTab,
                onToggleSidebar: toggleSidebar,
                onToggleSpotlight: toggleSpotlight,
                onToggleCommandPalette: toggleCommandPalette,
                onToggleFind: toggleFind,
                onDismissSpotlight: dismissSpotlight,
                onGoBack: goBack,
                onGoForward: goForward,
                onReload: reload
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func binding<Value>(for tab: BrowserTab, keyPath: ReferenceWritableKeyPath<BrowserTab, Value>) -> Binding<Value> {
        Binding(
            get: { tab[keyPath: keyPath] },
            set: { newValue in
                tab[keyPath: keyPath] = newValue
                tabRenderVersion += 1
                if tab.id == activeTab?.id {
                    syncSidebarURLText()
                }
            }
        )
    }

    private func selectedTab(in workspace: BrowserWorkspace) -> BrowserTab? {
        guard let selectedTabID = workspace.selectedTabID else {
            return workspace.tabs.first
        }

        return workspace.tabs.first(where: { $0.id == selectedTabID }) ?? workspace.tabs.first
    }

    private func tabsToRender(in workspace: BrowserWorkspace) -> [BrowserTab] {
        if workspace.id == activeWorkspace?.id {
            return workspace.tabs
        }

        if let selectedTab = selectedTab(in: workspace) {
            return [selectedTab]
        }

        return []
    }

    private func isVisible(tab: BrowserTab, in workspace: BrowserWorkspace) -> Bool {
        workspace.id == activeWorkspace?.id && tab.id == activeTab?.id
    }

    private func createNewWorkspace() {
        handleShortcut(.newWorkspace) {
            perform(.newWorkspace)
        }
    }

    private func createWorkspace() {
        let workspace = BrowserWorkspace()
        workspaces.append(workspace)
        selectedWorkspaceID = workspace.id
        refreshAfterStructuralChange()
    }

    private func createNewTab() {
        handleShortcut(.newTab) {
            perform(.newTab)
        }
    }

    private func closeCurrentTab() {
        handleShortcut(.closeTab) {
            perform(.closeTab)
        }
    }

    private func closeCurrentWorkspace() {
        handleShortcut(.closeWorkspace) {
            perform(.closeWorkspace)
        }
    }

    private func selectNextWorkspace() {
        handleShortcut(.nextWorkspace) {
            perform(.nextWorkspace)
        }
    }

    private func selectPreviousWorkspace() {
        handleShortcut(.previousWorkspace) {
            perform(.previousWorkspace)
        }
    }

    private func selectNextTab() {
        handleShortcut(.nextTab) {
            perform(.nextTab)
        }
    }

    private func selectPreviousTab() {
        handleShortcut(.previousTab) {
            perform(.previousTab)
        }
    }

    private func selectTab(_ id: UUID) {
        selectTab(id, in: activeWorkspace)
    }

    private func selectTab(_ id: UUID, in workspace: BrowserWorkspace?) {
        guard let workspace else { return }
        workspace.selectedTabID = id
        refreshAfterSelectionChange()
    }

    private func closeTab(_ id: UUID) {
        guard let workspace = activeWorkspace else { return }
        guard let closingIndex = workspace.tabs.firstIndex(where: { $0.id == id }) else { return }

        if workspace.tabs.count == 1 {
            let replacementTab = BrowserTab()
            workspace.tabs = [replacementTab]
            workspace.selectedTabID = replacementTab.id
            refreshAfterStructuralChange()
            return
        }

        let fallbackTabID: UUID
        if closingIndex < workspace.tabs.count - 1 {
            fallbackTabID = workspace.tabs[closingIndex + 1].id
        } else {
            fallbackTabID = workspace.tabs[closingIndex - 1].id
        }

        workspace.tabs.remove(at: closingIndex)

        if workspace.selectedTabID == id {
            workspace.selectedTabID = fallbackTabID
        }

        refreshAfterStructuralChange()
    }

    private func closeWorkspace(_ id: UUID) {
        guard let closingIndex = workspaces.firstIndex(where: { $0.id == id }) else { return }

        if workspaces.count == 1 {
            let replacementWorkspace = BrowserWorkspace()
            workspaces = [replacementWorkspace]
            selectedWorkspaceID = replacementWorkspace.id
            refreshAfterStructuralChange()
            return
        }

        let fallbackWorkspaceID: UUID
        if closingIndex < workspaces.count - 1 {
            fallbackWorkspaceID = workspaces[closingIndex + 1].id
        } else {
            fallbackWorkspaceID = workspaces[closingIndex - 1].id
        }

        workspaces.remove(at: closingIndex)

        if selectedWorkspaceID == id {
            selectedWorkspaceID = fallbackWorkspaceID
        }

        ensureWorkspaceSelectionIntegrity()
        refreshAfterStructuralChange()
    }

    private func submitSidebarURL() {
        guard let activeTab else { return }
        navigate(rawInput: sidebarURLText, in: activeTab)
        sidebarURLFocusRequestID = 0

        withAnimation(.easeInOut(duration: 0.1)) {
            activeOverlay = .none
        }
    }

    private func submitSpotlight() {
        guard let activeTab else { return }
        navigate(rawInput: spotlightText, in: activeTab)
        activeOverlay = .none
    }

    private func submitCommandPalette() {
        let query = commandPaletteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if handleParameterizedCommand(query) {
            closeCommandPalette(restoreSelection: false)
            return
        }

        if let command = matchingCommand(for: query) {
            closeCommandPalette(restoreSelection: false)
            perform(command)
            return
        }

        if executeSelectedCommandPaletteSuggestion() {
            return
        }

        closeCommandPalette(restoreSelection: false)
    }

    private func navigate(rawInput: String, in tab: BrowserTab) {
        let raw = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = destinationURL(for: raw) else { return }

        tab.currentPageURL = url
        tab.currentURLString = url.absoluteString
        tabRenderVersion += 1
        if tab.id == activeTab?.id {
            sidebarURLText = url.absoluteString
        }
    }

    private func perform(_ command: BrowserCommand) {
        switch command {
        case .newWorkspace:
            createWorkspace()
        case .newTab:
            createTab(in: activeWorkspace)
        case .closeWorkspace:
            if let selectedWorkspaceID {
                closeWorkspace(selectedWorkspaceID)
            }
        case .closeTab:
            if let selectedTabID = activeWorkspace?.selectedTabID {
                closeTab(selectedTabID)
            }
        case .nextWorkspace:
            moveWorkspaceSelection(by: 1)
        case .previousWorkspace:
            moveWorkspaceSelection(by: -1)
        case .nextTab:
            moveTabSelection(by: 1)
        case .previousTab:
            moveTabSelection(by: -1)
        }
    }

    private func createTab(in workspace: BrowserWorkspace?) {
        guard let workspace else { return }

        let newTab = BrowserTab()
        workspace.tabs.append(newTab)
        workspace.selectedTabID = newTab.id
        refreshAfterStructuralChange()
    }

    @discardableResult
    private func createTab(in workspace: BrowserWorkspace?, rawInput: String?) -> BrowserTab? {
        guard let workspace else { return nil }

        let newTab = BrowserTab()
        workspace.tabs.append(newTab)
        workspace.selectedTabID = newTab.id

        if let rawInput, !rawInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            navigate(rawInput: rawInput, in: newTab)
        } else {
            refreshAfterStructuralChange()
        }

        return newTab
    }

    private func moveWorkspaceSelection(by offset: Int) {
        guard !workspaces.isEmpty else { return }

        let currentIndex = activeWorkspaceIndex ?? 0
        let nextIndex = (currentIndex + offset + workspaces.count) % workspaces.count
        selectedWorkspaceID = workspaces[nextIndex].id
        refreshAfterSelectionChange()
    }

    private func moveTabSelection(by offset: Int) {
        guard let workspace = activeWorkspace, !workspace.tabs.isEmpty else { return }

        let currentIndex = activeTabIndex ?? 0
        let nextIndex = (currentIndex + offset + workspace.tabs.count) % workspace.tabs.count
        workspace.selectedTabID = workspace.tabs[nextIndex].id
        refreshAfterSelectionChange()
    }

    private func matchingCommand(for query: String) -> BrowserCommand? {
        guard !query.isEmpty else { return nil }

        let normalizedQuery = query.lowercased()
        return BrowserCommand.allCases.first { command in
            command.title.lowercased() == normalizedQuery ||
            command.queryTokens.contains(where: { $0 == normalizedQuery })
        }
    }

    private func handleParameterizedCommand(_ query: String) -> Bool {
        guard !query.isEmpty else { return false }

        let parts = query.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let commandToken = parts.first?.lowercased() else { return false }
        let argument = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""

        switch commandToken {
        case "ot":
            _ = createTab(in: activeWorkspace, rawInput: argument.isEmpty ? nil : argument)
            return true
        case "fav":
            return handleFavoriteCommand(argument)
        case "unfav":
            return removeFavorite(alias: argument)
        default:
            if let favorite = handleExactFavoriteAliasLookup(commandToken) {
                _ = createTab(in: activeWorkspace, rawInput: favorite.urlString)
                return true
            }
            return false
        }
    }

    private var commandPaletteSuggestionItems: [CommandPaletteSuggestionItem] {
        let query = commandPaletteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard shouldShowCommandPaletteSuggestions(for: query) else { return [] }

        let matches = matchingOpenTabs(for: query)
        var suggestions: [CommandPaletteSuggestionItem] = [
            CommandPaletteSuggestionItem(
                id: "open-new-\(query.lowercased())",
                title: "Open New Tab",
                subtitle: query,
                kind: .openNew(query)
            )
        ]

        suggestions.append(contentsOf: matches.map { match in
            CommandPaletteSuggestionItem(
                id: match.id,
                title: match.title,
                subtitle: match.subtitle,
                kind: .openTabMatch(match)
            )
        })

        return suggestions
    }

    private var commandPaletteSuggestions: [SpotlightView.Suggestion] {
        commandPaletteSuggestionItems.enumerated().map { index, item in
            SpotlightView.Suggestion(
                id: item.id,
                title: item.title,
                subtitle: item.subtitle,
                isSelected: index == normalizedCommandPaletteSelectionIndex,
                action: { executeCommandPaletteSuggestion(at: index) }
            )
        }
    }

    private func shouldShowCommandPaletteSuggestions(for query: String) -> Bool {
        guard !query.isEmpty else { return false }
        if matchingCommand(for: query) != nil { return false }
        return !query.lowercased().hasPrefix("fav add ")
    }

    private func matchingOpenTabs(for query: String) -> [CommandPaletteTabMatch] {
        let normalizedQuery = query.lowercased()
        let favoriteAliasTarget = favorite(forAlias: normalizedQuery)?.urlString.lowercased()

        return workspaces.enumerated().flatMap { workspaceIndex, workspace in
            workspace.tabs.enumerated().compactMap { tabIndex, tab in
                guard tab.currentPageURL != BrowserHomePage.url else { return nil }

                let site = siteLabel(for: tab.currentPageURL) ?? ""
                let host = tab.currentPageURL.host()?.lowercased() ?? ""
                let url = tab.currentURLString.lowercased()
                let title = title(for: tab, index: tabIndex)
                let normalizedTitle = title.lowercased()

                let isMatch =
                    normalizedTitle.contains(normalizedQuery) ||
                    site.lowercased().contains(normalizedQuery) ||
                    host.contains(normalizedQuery) ||
                    url.contains(normalizedQuery) ||
                    matchesFavoriteAliasTarget(
                        favoriteAliasTarget,
                        tabURLString: url,
                        host: host,
                        title: normalizedTitle,
                        site: site.lowercased()
                    )

                guard isMatch else { return nil }

                return CommandPaletteTabMatch(
                    id: "\(workspace.id.uuidString)-\(tab.id.uuidString)",
                    workspaceID: workspace.id,
                    tabID: tab.id,
                    title: title,
                    subtitle: "Workspace \(workspaceIndex + 1)  \(tab.currentURLString)"
                )
            }
        }
    }

    private func matchesFavoriteAliasTarget(
        _ favoriteURLString: String?,
        tabURLString: String,
        host: String,
        title: String,
        site: String
    ) -> Bool {
        guard let favoriteURLString, let favoriteURL = URL(string: favoriteURLString) else {
            return false
        }

        let favoriteHost = favoriteURL.host()?.lowercased() ?? ""
        let favoriteAbsoluteString = favoriteURL.absoluteString.lowercased()

        guard !favoriteHost.isEmpty || !favoriteAbsoluteString.isEmpty else {
            return false
        }

        return
            (!favoriteHost.isEmpty && (host.contains(favoriteHost) || favoriteHost.contains(host) || site.contains(favoriteHost) || title.contains(favoriteHost))) ||
            (!favoriteAbsoluteString.isEmpty && (tabURLString.contains(favoriteAbsoluteString) || favoriteAbsoluteString.contains(tabURLString)))
    }

    private func openCommandPaletteQueryInNewTab(_ query: String) {
        _ = createTab(in: activeWorkspace, rawInput: query)
        closeCommandPalette(restoreSelection: false)
    }

    private func selectCommandPaletteMatch(_ match: CommandPaletteTabMatch) {
        selectedWorkspaceID = match.workspaceID
        if let workspace = workspaces.first(where: { $0.id == match.workspaceID }) {
            selectTab(match.tabID, in: workspace)
        }
        closeCommandPalette(restoreSelection: false)
    }

    private func closeCommandPalette(restoreSelection: Bool) {
        if restoreSelection {
            restoreCommandPaletteOriginSelection()
        }
        commandPaletteText = ""
        commandPaletteFocusRequestID = 0
        commandPaletteSelectionIndex = 0
        commandPaletteOriginWorkspaceID = nil
        commandPaletteOriginTabID = nil
        withAnimation(.easeInOut(duration: 0.1)) {
            activeOverlay = .none
        }
    }

    private func handleExactFavoriteAliasLookup(_ query: String) -> BrowserFavorite? {
        favorite(forAlias: query)
    }

    private func handleFavoriteCommand(_ argument: String) -> Bool {
        let trimmedArgument = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedArgument.isEmpty else { return false }

        let parts = trimmedArgument.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let subcommand = parts.first?.lowercased() else { return false }

        if subcommand == "add" {
            guard parts.count > 1 else { return false }
            return addCurrentPageToFavorites(alias: parts[1])
        }

        if let favorite = favorite(forAlias: subcommand) {
            _ = createTab(in: activeWorkspace, rawInput: favorite.urlString)
            return true
        }

        return false
    }

    private func addCurrentPageToFavorites(alias rawAlias: String) -> Bool {
        guard let activeTab else { return false }
        guard activeTab.currentPageURL != BrowserHomePage.url else { return false }

        let alias = normalizedAlias(rawAlias)
        guard !alias.isEmpty else { return false }

        let title = siteLabel(for: activeTab.currentPageURL) ?? activeTab.currentPageURL.host() ?? activeTab.currentURLString
        let favorite = BrowserFavorite(
            title: title,
            alias: alias,
            urlString: activeTab.currentURLString
        )

        if let existingIndex = favorites.firstIndex(where: { $0.alias == alias }) {
            favorites[existingIndex] = favorite
        } else {
            favorites.append(favorite)
        }

        persistFavorites()
        return true
    }

    private func favorite(forAlias rawAlias: String) -> BrowserFavorite? {
        let alias = normalizedAlias(rawAlias)
        guard !alias.isEmpty else { return nil }
        return favorites.first(where: { $0.alias == alias })
    }

    private func removeFavorite(alias rawAlias: String) -> Bool {
        let alias = normalizedAlias(rawAlias)
        guard !alias.isEmpty else { return false }
        guard let index = favorites.firstIndex(where: { $0.alias == alias }) else { return false }

        favorites.remove(at: index)
        persistFavorites()
        return true
    }

    private func normalizedAlias(_ rawAlias: String) -> String {
        rawAlias
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func loadFavorites() -> [BrowserFavorite] {
        guard let data = UserDefaults.standard.data(forKey: FavoriteStore.defaultsKey) else {
            return []
        }

        return (try? JSONDecoder().decode([BrowserFavorite].self, from: data)) ?? []
    }

    private func persistFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: FavoriteStore.defaultsKey)
    }

    private func refreshAfterStructuralChange() {
        tabRenderVersion += 1
        syncSidebarURLText()
        clearFindState()
    }

    private func refreshAfterSelectionChange() {
        tabRenderVersion += 1
        syncSidebarURLText()
        clearFindState()
    }

    private func handleShortcut(_ action: ShortcutAction, perform operation: () -> Void) {
        guard canHandleShortcut(action) else { return }
        operation()
    }

    private func toggleSidebar() {
        guard canHandleShortcut(.sidebar) else { return }

        syncSidebarURLText()

        withAnimation(.easeInOut(duration: 0.25)) {
            if activeOverlay == .sidebar {
                sidebarURLFocusRequestID = 0
                activeOverlay = .none
            } else {
                activeOverlay = .sidebar
            }
        }

        clearFindState()
    }

    private func toggleSpotlight() {
        guard canHandleShortcut(.spotlight) else { return }
        if activeOverlay == .sidebar {
            sidebarURLFocusRequestID += 1
            return
        }
        guard let activeTab else { return }

        let shouldClearFind = activeOverlay == .find || !findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || findStatus != .empty

        withAnimation(.easeInOut(duration: 0.1)) {
            spotlightText = activeTab.currentURLString
            if activeOverlay == .spotlight {
                spotlightFocusRequestID = 0
                activeOverlay = .none
            } else {
                spotlightFocusRequestID += 1
                activeOverlay = .spotlight
            }
        }

        if shouldClearFind {
            clearFindState()
        }
    }

    private func toggleCommandPalette() {
        guard canHandleShortcut(.commandPalette) else { return }
        if activeOverlay == .commandPalette {
            closeCommandPalette(restoreSelection: true)
            return
        }

        let shouldClearFind = activeOverlay == .find || !findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || findStatus != .empty
        let previousOverlay = activeOverlay

        withAnimation(.easeInOut(duration: 0.1)) {
            if previousOverlay == .sidebar {
                sidebarURLFocusRequestID = 0
            }
            if previousOverlay == .spotlight {
                spotlightFocusRequestID = 0
            }
            commandPaletteOriginWorkspaceID = selectedWorkspaceID
            commandPaletteOriginTabID = activeWorkspace?.selectedTabID
            commandPaletteSelectionIndex = 0
            commandPaletteText = ""
            commandPaletteFocusRequestID += 1
            activeOverlay = .commandPalette
        }

        if shouldClearFind {
            clearFindState()
        }
    }

    private var normalizedCommandPaletteSelectionIndex: Int {
        let count = commandPaletteSuggestionItems.count
        guard count > 0 else { return 0 }
        return min(max(commandPaletteSelectionIndex, 0), count - 1)
    }

    private func resetCommandPaletteSelection() {
        commandPaletteSelectionIndex = 0
        previewSelectedCommandPaletteSuggestion()
    }

    private func selectNextCommandPaletteSuggestion() {
        guard !commandPaletteSuggestionItems.isEmpty else { return }
        commandPaletteSelectionIndex = (normalizedCommandPaletteSelectionIndex + 1) % commandPaletteSuggestionItems.count
        previewSelectedCommandPaletteSuggestion()
    }

    private func selectPreviousCommandPaletteSuggestion() {
        guard !commandPaletteSuggestionItems.isEmpty else { return }
        commandPaletteSelectionIndex = (normalizedCommandPaletteSelectionIndex - 1 + commandPaletteSuggestionItems.count) % commandPaletteSuggestionItems.count
        previewSelectedCommandPaletteSuggestion()
    }

    private func executeSelectedCommandPaletteSuggestion() -> Bool {
        guard !commandPaletteSuggestionItems.isEmpty else { return false }
        executeCommandPaletteSuggestion(at: normalizedCommandPaletteSelectionIndex)
        return true
    }

    private func executeCommandPaletteSuggestion(at index: Int) {
        guard commandPaletteSuggestionItems.indices.contains(index) else { return }

        switch commandPaletteSuggestionItems[index].kind {
        case .openNew(let query):
            openCommandPaletteQueryInNewTab(query)
        case .openTabMatch(let match):
            selectCommandPaletteMatch(match)
        }
    }

    private func previewSelectedCommandPaletteSuggestion() {
        guard !commandPaletteSuggestionItems.isEmpty else {
            restoreCommandPaletteOriginSelection()
            return
        }

        switch commandPaletteSuggestionItems[normalizedCommandPaletteSelectionIndex].kind {
        case .openNew:
            restoreCommandPaletteOriginSelection()
        case .openTabMatch(let match):
            selectedWorkspaceID = match.workspaceID
            if let workspace = workspaces.first(where: { $0.id == match.workspaceID }) {
                selectTab(match.tabID, in: workspace)
            }
        }
    }

    private func restoreCommandPaletteOriginSelection() {
        guard let originWorkspaceID = commandPaletteOriginWorkspaceID else { return }
        selectedWorkspaceID = originWorkspaceID
        if let workspace = workspaces.first(where: { $0.id == originWorkspaceID }),
           let originTabID = commandPaletteOriginTabID {
            selectTab(originTabID, in: workspace)
        }
    }

    private func toggleFind() {
        guard canHandleShortcut(.find) else { return }
        let trimmedFindText = findText.trimmingCharacters(in: .whitespacesAndNewlines)

        if activeOverlay == .find {
            if trimmedFindText.isEmpty {
                withAnimation(.easeInOut(duration: 0.1)) {
                    activeOverlay = .none
                }
            } else {
                clearFindState()
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.1)) {
            activeOverlay = .find
        }

        if !trimmedFindText.isEmpty || findStatus != .empty {
            clearFindState()
        }
    }

    private func dismissSpotlight() {
        guard activeOverlay != .none else { return }
        guard canHandleShortcut(.dismiss) else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            activeOverlay = .none
        }

        clearFindState()
    }

    private func goBack() {
        activeTab?.navigationController.goBack()
    }

    private func goForward() {
        activeTab?.navigationController.goForward()
    }

    private func reload() {
        activeTab?.navigationController.reload()
    }

    private func updateFindResults(_ text: String) {
        activeTab?.navigationController.find(text) { status in
            findStatus = status
        }
    }

    private func clearFindState() {
        findText = ""
        findStatus = .empty
        activeTab?.navigationController.clearFind()
    }

    private func syncSidebarURLText() {
        sidebarURLText = activeTab?.currentURLString ?? BrowserHomePage.url.absoluteString
    }

    private func ensureWorkspaceSelectionIntegrity() {
        guard let workspace = activeWorkspace else { return }

        if workspace.tabs.isEmpty {
            let replacementTab = BrowserTab()
            workspace.tabs = [replacementTab]
            workspace.selectedTabID = replacementTab.id
            tabRenderVersion += 1
            return
        }

        if workspace.selectedTabID == nil || !workspace.tabs.contains(where: { $0.id == workspace.selectedTabID }) {
            workspace.selectedTabID = workspace.tabs.first?.id
        }
    }

    private func destinationURL(for rawInput: String) -> URL? {
        guard !rawInput.isEmpty else { return nil }

        if let explicitURL = URL(string: rawInput), explicitURL.scheme != nil {
            return explicitURL
        }

        if looksLikeHost(rawInput), let hostURL = URL(string: "https://\(rawInput)") {
            return hostURL
        }

        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: rawInput)]
        return components?.url
    }

    private func looksLikeHost(_ input: String) -> Bool {
        !input.contains(" ") && input.contains(".")
    }

    private func title(for tab: BrowserTab, index: Int) -> String {
        if tab.currentPageURL == BrowserHomePage.url {
            return "Tab \(index + 1)"
        }

        return siteLabel(for: tab.currentPageURL) ?? "Tab \(index + 1)"
    }

    private func siteLabel(for url: URL) -> String? {
        guard let host = url.host()?.lowercased() else { return nil }

        let components = host.split(separator: ".").map(String.init)
        let ignoredPrefixes = Set(["www", "m", "mobile"])
        let filteredComponents = components.filter { !ignoredPrefixes.contains($0) }

        guard !filteredComponents.isEmpty else { return nil }

        let root: String
        if filteredComponents.count >= 2 {
            root = filteredComponents[filteredComponents.count - 2]
        } else {
            root = filteredComponents[0]
        }

        return root.prefix(1).uppercased() + root.dropFirst()
    }

    private func canHandleShortcut(_ action: ShortcutAction) -> Bool {
        let now = Date()
        let isDuplicate = lastShortcutAction == action &&
            now.timeIntervalSince(lastShortcutTimestamp) < shortcutCoalescingInterval

        guard !isDuplicate else { return false }

        lastShortcutAction = action
        lastShortcutTimestamp = now
        return true
    }
}

#Preview {
    ContentView()
}
