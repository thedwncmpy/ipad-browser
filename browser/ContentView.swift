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

    private enum ClosedTabStore {
        static let limit = 20
    }

    private enum ActiveOverlay {
        case none
        case sidebar
        case history
        case spotlight
        case commandPalette
        case find
        case settings
    }

    private enum KeyboardFocusTarget {
        case browser
        case capture
        case sidebarURL
        case history
        case spotlight
        case commandPalette
        case find
    }

    private enum ShortcutAction {
        case newWorkspace
        case newTab
        case closeWorkspace
        case closeTab
        case reopenClosedTab
        case nextWorkspace
        case previousWorkspace
        case nextTab
        case previousTab
        case moveTabToNextWorkspace
        case moveTabToPreviousWorkspace
        case moveTabDown
        case moveTabUp
        case sidebar
        case history
        case spotlight
        case commandPalette
        case find
        case settings
        case dismiss
    }

    private enum BrowserCommand: CaseIterable {
        case newWorkspace
        case newTab
        case closeWorkspace
        case closeTab
        case reopenClosedTab
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
            case .reopenClosedTab:
                return "Reopen Closed Tab"
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
            case .reopenClosedTab: ["rt", "reopen tab", "restore tab", "undo close tab", "reopen closed tab"]
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
        case command(BrowserCommand)
        case commandCompletion(String)
        case reopenClosedTab(ClosedTabEntry)
        case openNew(String)
        case openTabMatch(CommandPaletteTabMatch)
    }

    private struct CommandPaletteSuggestionItem: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let kind: CommandPaletteSuggestionKind
    }

    private struct CommandPaletteCompletion {
        let id: String
        let title: String
        let subtitle: String
        let completion: String
        let tokens: [String]
    }

    private struct ClosedTabEntry: Identifiable {
        let id = UUID()
        let tab: BrowserTab
        let closedFromWorkspaceID: UUID
        let closedAt: Date
    }

    @State private var activeOverlay: ActiveOverlay = .none
    @State private var workspaces: [BrowserWorkspace] = [BrowserWorkspace()]
    @State private var recentlyClosedTabs: [ClosedTabEntry] = []
    @State private var selectedWorkspaceID: UUID? = nil
    @State private var sidebarURLText = BrowserHomePage.url.absoluteString
    @State private var historySearchText = ""
    @State private var selectedHistoryItemID: UUID? = nil
    @State private var spotlightText = ""
    @State private var spotlightFocusRequestID = 0
    @State private var commandPaletteText = ""
    @State private var commandPaletteFocusRequestID = 0
    @State private var commandPaletteSelectionIndex = 0
    @State private var commandPaletteOriginWorkspaceID: UUID? = nil
    @State private var commandPaletteOriginTabID: UUID? = nil
    @State private var findText = ""
    @State private var findFocusRequestID = 0
    @State private var findStatus = BrowserFindStatus.empty
    @State private var sidebarURLFocusRequestID = 0
    @State private var historyFocusRequestID = 0
    @State private var browserFocusRequestID = 0
    @State private var captureFocusRequestID = 0
    @State private var keyboardFocusTarget: KeyboardFocusTarget = .browser
    @State private var favorites: [BrowserFavorite] = []
    @State private var shortcuts: [BrowserShortcutAction: BrowserShortcut] = BrowserShortcutStore.load()
    @State private var tabRenderVersion = 0
    @State private var lastShortcutAction: ShortcutAction?
    @State private var lastShortcutTimestamp = Date.distantPast
    private let shortcutCoalescingInterval: TimeInterval = 0.08

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
            sidebar
            historySidebar
            spotlight
            commandPalette
            findOverlay
            settingsOverlay
            keyboardCaptureLayer
        }
        .onAppear {
            if selectedWorkspaceID == nil {
                selectedWorkspaceID = workspaces.first?.id
            }
            favorites = loadFavorites()
            syncSidebarURLText()
            restoreDefaultKeyboardFocus()
        }
        .onChange(of: activeOverlay) { _, newOverlay in
            if newOverlay == .none {
                restoreDefaultKeyboardFocus()
            }
        }
        .onChange(of: selectedWorkspaceID) { _, _ in
            ensureWorkspaceSelectionIntegrity()
            syncSidebarURLText()
            clearFindState()
            if activeOverlay == .none {
                restoreDefaultKeyboardFocus()
            }
        }
        .onChange(of: activeWorkspace?.selectedTabID) { _, _ in
            syncSidebarURLText()
            clearFindState()
            if activeOverlay == .none {
                restoreDefaultKeyboardFocus()
            }
        }
        .onChange(of: historySearchText) { _, _ in
            syncHistorySelection()
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

    private var historySidebarItems: [SidebarTabItem] {
        let query = historySearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return recentlyClosedTabs.compactMap { closedTab in
            let tabTitle = title(for: closedTab.tab, index: 0)
            let haystack = "\(tabTitle) \(closedTab.tab.currentURLString)".lowercased()
            guard query.isEmpty || haystack.contains(query) else { return nil }

            return SidebarTabItem(
                id: closedTab.id,
                title: tabTitle,
                currentURLString: closedTab.tab.currentURLString,
                currentPageURL: closedTab.tab.currentPageURL
            )
        }
    }

    private var historyPreviewTab: BrowserTab? {
        guard activeOverlay == .history, let selectedHistoryItemID else { return nil }
        return recentlyClosedTabs.first(where: { $0.id == selectedHistoryItemID })?.tab
    }

    private var mainContent: some View {
        ZStack {
            ForEach(workspaces) { workspace in
                ForEach(tabsToRender(in: workspace)) { tab in
                    BrowserWebView(
                        url: binding(for: tab, keyPath: \.currentPageURL),
                        currentURLString: binding(for: tab, keyPath: \.currentURLString),
                        pageTitle: binding(for: tab, keyPath: \.pageTitle),
                        navigationController: tab.navigationController,
                        focusRequestID: browserFocusRequestID(for: tab, in: workspace),
                        isSidebarNavigationEnabled: activeOverlay == .sidebar || activeOverlay == .history,
                        onNewWorkspace: createNewWorkspace,
                        onNewTab: createNewTab,
                        onCloseWorkspace: closeCurrentWorkspace,
                        onCloseTab: closeCurrentTab,
                        onReopenClosedTab: reopenClosedTabInCurrentWorkspace,
                        onNextWorkspace: selectNextWorkspace,
                        onPreviousWorkspace: selectPreviousWorkspace,
                        onNextTab: selectNextTab,
                        onPreviousTab: selectPreviousTab,
                        onMoveTabToNextWorkspace: moveCurrentTabToNextWorkspace,
                        onMoveTabToPreviousWorkspace: moveCurrentTabToPreviousWorkspace,
                        onMoveTabDown: moveCurrentTabDown,
                        onMoveTabUp: moveCurrentTabUp,
                        onToggleSidebar: toggleSidebar,
                        onToggleSpotlight: toggleSpotlight,
                        onToggleCommandPalette: toggleCommandPalette,
                        onToggleFind: toggleFind,
                        onToggleHistory: toggleHistory,
                        onToggleSettings: toggleSettings,
                        onDismissOverlay: dismissSpotlight,
                        onGoBack: goBack,
                        onGoForward: goForward,
                        onReload: reload,
                        onPageTitleChange: refreshTabTitles,
                        shortcuts: shortcuts
                    )
                    .ignoresSafeArea()
                    .opacity(isVisible(tab: tab, in: workspace) ? 1 : 0)
                    .allowsHitTesting(isVisible(tab: tab, in: workspace))
                }
            }

            if let historyPreviewTab {
                BrowserWebView(
                    url: binding(for: historyPreviewTab, keyPath: \.currentPageURL),
                    currentURLString: binding(for: historyPreviewTab, keyPath: \.currentURLString),
                    pageTitle: binding(for: historyPreviewTab, keyPath: \.pageTitle),
                    navigationController: historyPreviewTab.navigationController,
                    focusRequestID: nil,
                    isSidebarNavigationEnabled: true,
                    onNewWorkspace: createNewWorkspace,
                    onNewTab: createNewTab,
                    onCloseWorkspace: closeCurrentWorkspace,
                    onCloseTab: closeCurrentTab,
                    onReopenClosedTab: reopenClosedTabInCurrentWorkspace,
                    onNextWorkspace: selectNextWorkspace,
                    onPreviousWorkspace: selectPreviousWorkspace,
                    onNextTab: selectNextTab,
                    onPreviousTab: selectPreviousTab,
                    onMoveTabToNextWorkspace: moveCurrentTabToNextWorkspace,
                    onMoveTabToPreviousWorkspace: moveCurrentTabToPreviousWorkspace,
                    onMoveTabDown: moveCurrentTabDown,
                    onMoveTabUp: moveCurrentTabUp,
                    onToggleSidebar: toggleSidebar,
                    onToggleSpotlight: toggleSpotlight,
                    onToggleCommandPalette: toggleCommandPalette,
                    onToggleFind: toggleFind,
                    onToggleHistory: toggleHistory,
                    onToggleSettings: toggleSettings,
                    onDismissOverlay: dismissSpotlight,
                    onGoBack: goBack,
                    onGoForward: goForward,
                    onReload: reload,
                    onPageTitleChange: refreshTabTitles,
                    shortcuts: shortcuts
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
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
                onHoverTab: nil,
                onCloseTab: closeTab,
                onSidebarShortcut: toggleSidebar,
                onSpotlightShortcut: toggleSpotlight,
                onCommandPaletteShortcut: toggleCommandPalette,
                onFindShortcut: toggleFind,
                onHistoryShortcut: toggleHistory,
                onSettingsShortcut: toggleSettings,
                onNextItemShortcut: nil,
                onPreviousItemShortcut: nil,
                onDismiss: dismissSpotlight,
                onSubmit: submitSidebarURL,
                shortcuts: shortcuts
            )
            .transition(.move(edge: .leading))
            .zIndex(1)
        }
    }

    @ViewBuilder
    private var historySidebar: some View {
        if activeOverlay == .history {
            SidebarView(
                urlText: $historySearchText,
                currentPageURL: BrowserHomePage.url,
                tabs: historySidebarItems,
                selectedTabID: selectedHistoryItemID,
                workspaceCount: workspaces.count,
                selectedWorkspaceIndex: activeWorkspaceIndex ?? 0,
                urlFieldFocusRequestID: historyFocusRequestID == 0 ? nil : historyFocusRequestID,
                placeholder: "History",
                showsCurrentPageFavicon: false,
                showsWorkspaceIndicator: false,
                showsCloseButtons: false,
                usesBareNavigationShortcuts: true,
                onSelectTab: reopenClosedTabFromHistory,
                onHoverTab: selectHistoryItem,
                onCloseTab: { _ in },
                onSidebarShortcut: toggleSidebar,
                onSpotlightShortcut: toggleSpotlight,
                onCommandPaletteShortcut: toggleCommandPalette,
                onFindShortcut: toggleFind,
                onHistoryShortcut: toggleHistory,
                onSettingsShortcut: toggleSettings,
                onNextItemShortcut: { moveHistorySelection(by: 1) },
                onPreviousItemShortcut: { moveHistorySelection(by: -1) },
                onDismiss: dismissSpotlight,
                onSubmit: submitHistorySearch,
                shortcuts: shortcuts
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
                onHistoryShortcut: toggleHistory,
                onSpotlightShortcut: toggleSpotlight,
                onSettingsShortcut: toggleSettings,
                shortcuts: shortcuts,
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
                pageURL: commandPaletteFaviconURL,
                showsFavicon: commandPaletteFaviconURL != nil,
                showsFaviconPlaceholder: false,
                focusRequestID: commandPaletteFocusRequestID == 0 ? nil : commandPaletteFocusRequestID,
                autocompleteText: commandPaletteAutocompleteText,
                suggestions: commandPaletteSuggestions,
                onTextChange: { _ in resetCommandPaletteSelection() },
                onSidebarShortcut: toggleSidebar,
                onFindShortcut: toggleFind,
                onHistoryShortcut: toggleHistory,
                onSpotlightShortcut: toggleSpotlight,
                onCommandPaletteShortcut: toggleCommandPalette,
                onSettingsShortcut: toggleSettings,
                onNextSuggestionShortcut: selectNextCommandPaletteSuggestion,
                onPreviousSuggestionShortcut: selectPreviousCommandPaletteSuggestion,
                onCompleteSuggestionShortcut: completeSelectedCommandPaletteSuggestion,
                shortcuts: shortcuts,
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
            focusRequestID: findFocusRequestID == 0 ? nil : findFocusRequestID,
            onTextChange: updateFindResults,
            onSidebarShortcut: toggleSidebar,
            onFindShortcut: toggleFind,
            onHistoryShortcut: toggleHistory,
            onSpotlightShortcut: toggleSpotlight,
            onSettingsShortcut: toggleSettings,
            shortcuts: shortcuts,
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
    private var settingsOverlay: some View {
        if activeOverlay == .settings {
            SettingsView(
                shortcuts: $shortcuts,
                onDismiss: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        activeOverlay = .none
                    }
                }
            )
            .zIndex(2)
        }
    }

    @ViewBuilder
    private var keyboardCaptureLayer: some View {
        if activeOverlay == .sidebar || activeOverlay == .history || (activeOverlay == .none && keyboardFocusTarget == .capture) {
            KeyboardCaptureView(
                onNewWorkspace: createNewWorkspace,
                onNewTab: createNewTab,
                onCloseWorkspace: closeCurrentWorkspace,
                onCloseTab: closeCurrentTab,
                onReopenClosedTab: reopenClosedTabInCurrentWorkspace,
                onNextWorkspace: selectNextWorkspace,
                onPreviousWorkspace: selectPreviousWorkspace,
                onNextTab: selectNextTab,
                onPreviousTab: selectPreviousTab,
                onMoveTabToNextWorkspace: moveCurrentTabToNextWorkspace,
                onMoveTabToPreviousWorkspace: moveCurrentTabToPreviousWorkspace,
                onMoveTabDown: moveCurrentTabDown,
                onMoveTabUp: moveCurrentTabUp,
                onToggleSidebar: toggleSidebar,
                onToggleSpotlight: toggleSpotlight,
                onToggleCommandPalette: toggleCommandPalette,
                onToggleFind: toggleFind,
                onToggleHistory: toggleHistory,
                onToggleSettings: toggleSettings,
                onSubmitSelection: submitHistorySearch,
                onFocusFilter: focusHistoryFilter,
                onDismissSpotlight: dismissSpotlight,
                onGoBack: goBack,
                onGoForward: goForward,
                onReload: reload,
                shortcuts: shortcuts,
                focusRequestID: captureFocusRequestID == 0 ? nil : captureFocusRequestID
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

    private func browserFocusRequestID(for tab: BrowserTab, in workspace: BrowserWorkspace) -> Int? {
        guard keyboardFocusTarget == .browser, isVisible(tab: tab, in: workspace), browserFocusRequestID > 0 else {
            return nil
        }

        return browserFocusRequestID
    }

    private func requestKeyboardFocus(_ target: KeyboardFocusTarget) {
        keyboardFocusTarget = target

        switch target {
        case .browser:
            browserFocusRequestID += 1
        case .capture:
            captureFocusRequestID += 1
        case .sidebarURL:
            sidebarURLFocusRequestID += 1
        case .history:
            historyFocusRequestID += 1
        case .spotlight:
            spotlightFocusRequestID += 1
        case .commandPalette:
            commandPaletteFocusRequestID += 1
        case .find:
            findFocusRequestID += 1
        }
    }

    private func restoreDefaultKeyboardFocus() {
        requestKeyboardFocus(.browser)
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

    private func reopenClosedTabInCurrentWorkspace() {
        handleShortcut(.reopenClosedTab) {
            reopenMostRecentlyClosedTab()
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
        if activeOverlay == .history {
            moveHistorySelection(by: 1)
            return
        }

        handleShortcut(.nextTab) {
            perform(.nextTab)
        }
    }

    private func selectPreviousTab() {
        if activeOverlay == .history {
            moveHistorySelection(by: -1)
            return
        }

        handleShortcut(.previousTab) {
            perform(.previousTab)
        }
    }

    private func moveCurrentTabToNextWorkspace() {
        handleShortcut(.moveTabToNextWorkspace) {
            moveCurrentTabToWorkspace(by: 1)
        }
    }

    private func moveCurrentTabToPreviousWorkspace() {
        handleShortcut(.moveTabToPreviousWorkspace) {
            moveCurrentTabToWorkspace(by: -1)
        }
    }

    private func moveCurrentTabDown() {
        handleShortcut(.moveTabDown) {
            reorderCurrentTab(by: 1)
        }
    }

    private func moveCurrentTabUp() {
        handleShortcut(.moveTabUp) {
            reorderCurrentTab(by: -1)
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
        let closingTab = workspace.tabs[closingIndex]
        rememberClosedTab(closingTab, from: workspace)

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

    private func rememberClosedTab(_ tab: BrowserTab, from workspace: BrowserWorkspace) {
        guard tab.currentPageURL != BrowserHomePage.url else { return }

        recentlyClosedTabs.removeAll { $0.tab.id == tab.id }
        recentlyClosedTabs.insert(
            ClosedTabEntry(tab: tab, closedFromWorkspaceID: workspace.id, closedAt: Date()),
            at: 0
        )

        if recentlyClosedTabs.count > ClosedTabStore.limit {
            recentlyClosedTabs.removeLast(recentlyClosedTabs.count - ClosedTabStore.limit)
        }
    }

    private func reopenMostRecentlyClosedTab() {
        guard let closedTab = recentlyClosedTabs.first else { return }
        recentlyClosedTabs.removeFirst()
        restoreClosedTab(closedTab, in: activeWorkspace)
    }

    private func restoreClosedTab(_ closedTab: ClosedTabEntry, in preferredWorkspace: BrowserWorkspace? = nil) {
        let targetWorkspace = preferredWorkspace ?? workspaces.first(where: { $0.id == closedTab.closedFromWorkspaceID }) ?? activeWorkspace
        guard let targetWorkspace else { return }

        targetWorkspace.tabs.append(closedTab.tab)
        targetWorkspace.selectedTabID = closedTab.tab.id
        selectedWorkspaceID = targetWorkspace.id
        closedTab.tab.navigationController.webView?.removeFromSuperview()
        refreshAfterStructuralChange()
    }

    private func reopenClosedTabFromHistory(_ id: UUID) {
        guard let index = recentlyClosedTabs.firstIndex(where: { $0.id == id }) else { return }
        let closedTab = recentlyClosedTabs.remove(at: index)
        restoreClosedTab(closedTab, in: activeWorkspace)
        selectedHistoryItemID = nil
        activeOverlay = .none
    }

    private func selectHistoryItem(_ id: UUID) {
        guard activeOverlay == .history else { return }
        selectedHistoryItemID = id
    }

    private func syncHistorySelection() {
        let items = historySidebarItems
        guard !items.isEmpty else {
            selectedHistoryItemID = nil
            return
        }

        if let selectedHistoryItemID,
           items.contains(where: { $0.id == selectedHistoryItemID }) {
            return
        }

        selectedHistoryItemID = items.first?.id
    }

    private func moveHistorySelection(by offset: Int) {
        let items = historySidebarItems
        guard !items.isEmpty else {
            selectedHistoryItemID = nil
            return
        }

        let currentIndex = selectedHistoryItemID.flatMap { selectedID in
            items.firstIndex(where: { $0.id == selectedID })
        } ?? 0
        let nextIndex = (currentIndex + offset + items.count) % items.count
        selectedHistoryItemID = items[nextIndex].id
    }

    private func closeWorkspace(_ id: UUID) {
        guard let closingIndex = workspaces.firstIndex(where: { $0.id == id }) else { return }
        let closingWorkspace = workspaces[closingIndex]
        rememberClosedTabs(from: closingWorkspace)

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

    private func rememberClosedTabs(from workspace: BrowserWorkspace) {
        for tab in workspace.tabs.reversed() {
            rememberClosedTab(tab, from: workspace)
        }
    }

    private func reorderCurrentTab(by offset: Int) {
        guard let workspace = activeWorkspace else { return }
        guard let selectedTabID = workspace.selectedTabID else { return }
        guard let currentIndex = workspace.tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }

        let destinationIndex = currentIndex + offset
        guard workspace.tabs.indices.contains(destinationIndex) else { return }

        workspace.tabs.swapAt(currentIndex, destinationIndex)
        workspace.selectedTabID = selectedTabID
        refreshAfterStructuralChange()
    }

    private func moveCurrentTabToWorkspace(by offset: Int) {
        guard let sourceWorkspaceIndex = activeWorkspaceIndex else { return }
        let destinationWorkspaceIndex = sourceWorkspaceIndex + offset
        guard workspaces.indices.contains(destinationWorkspaceIndex) else { return }

        let sourceWorkspace = workspaces[sourceWorkspaceIndex]
        let destinationWorkspace = workspaces[destinationWorkspaceIndex]
        guard let selectedTabID = sourceWorkspace.selectedTabID else { return }
        guard let tabIndex = sourceWorkspace.tabs.firstIndex(where: { $0.id == selectedTabID }) else { return }

        let movingTab = sourceWorkspace.tabs.remove(at: tabIndex)
        destinationWorkspace.tabs.append(movingTab)
        destinationWorkspace.selectedTabID = movingTab.id
        selectedWorkspaceID = destinationWorkspace.id

        if sourceWorkspace.tabs.isEmpty {
            let replacementTab = BrowserTab()
            sourceWorkspace.tabs = [replacementTab]
            sourceWorkspace.selectedTabID = replacementTab.id
        } else if tabIndex < sourceWorkspace.tabs.count {
            sourceWorkspace.selectedTabID = sourceWorkspace.tabs[tabIndex].id
        } else {
            sourceWorkspace.selectedTabID = sourceWorkspace.tabs.last?.id
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

    private func submitHistorySearch() {
        guard activeOverlay == .history else { return }
        syncHistorySelection()
        if let selectedHistoryItemID {
            reopenClosedTabFromHistory(selectedHistoryItemID)
        }
    }

    private func focusHistoryFilter() {
        guard activeOverlay == .history else { return }
        requestKeyboardFocus(.history)
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
        tab.pageTitle = ""
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
        case .reopenClosedTab:
            reopenMostRecentlyClosedTab()
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
            let destination = favorite(forAlias: argument)?.urlString ?? argument
            _ = createTab(in: activeWorkspace, rawInput: destination.isEmpty ? nil : destination)
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

        var suggestions = matchingCommandSuggestions(for: query)
        suggestions.append(contentsOf: matchingCommandCompletionSuggestions(for: query))
        suggestions.append(contentsOf: matchingFavoriteAliasCompletionSuggestions(for: query))
        suggestions.append(contentsOf: matchingClosedTabSuggestions(for: query))

        let matches = matchingOpenTabs(for: query)

        if shouldShowOpenNewTabSuggestion(for: query) {
            suggestions.append(CommandPaletteSuggestionItem(
                id: "open-new-\(query.lowercased())",
                title: "Open New Tab",
                subtitle: query,
                kind: .openNew(query)
            ))
        }

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

    private var commandPaletteAutocompleteText: String? {
        guard !commandPaletteSuggestionItems.isEmpty else { return nil }
        let query = commandPaletteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }

        let completion: String?
        switch commandPaletteSuggestionItems[normalizedCommandPaletteSelectionIndex].kind {
        case .command(let command):
            completion = bestCommandCompletion(for: query, command: command)
        case .commandCompletion(let commandCompletion):
            completion = commandCompletion
        case .reopenClosedTab, .openNew, .openTabMatch:
            completion = nil
        }

        guard let completion else { return nil }
        return autocompleteSuffix(for: query, completion: completion)
    }

    private var commandPaletteFaviconURL: URL? {
        let lookupText = commandPaletteFaviconLookupText()
        guard !lookupText.isEmpty else { return nil }

        if let favoriteURL = favoriteURLForCommandPaletteLookup(lookupText) {
            return favoriteURL
        }

        if let typedURL = directURL(for: lookupText) {
            return typedURL
        }

        if let match = matchingOpenTabs(for: lookupText).first {
            return workspaces
                .first(where: { $0.id == match.workspaceID })?
                .tabs
                .first(where: { $0.id == match.tabID })?
                .currentPageURL
        }

        return nil
    }

    private func commandPaletteFaviconLookupText() -> String {
        let query = commandPaletteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return "" }

        let parts = query.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let commandToken = parts.first?.lowercased(), parts.count > 1 else {
            return query
        }

        let argument = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        switch commandToken {
        case "ot", "unfav":
            return argument
        case "fav":
            let favoriteParts = argument.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
            if favoriteParts.first?.lowercased() == "add", favoriteParts.count > 1 {
                return favoriteParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return argument
        default:
            return query
        }
    }

    private func favoriteURLForCommandPaletteLookup(_ rawLookup: String) -> URL? {
        let lookup = rawLookup.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lookup.isEmpty else { return nil }

        let matchingFavorite = favorites.first { favorite in
            favorite.alias.lowercased() == lookup ||
                favorite.title.lowercased().contains(lookup) ||
                favorite.urlString.lowercased().contains(lookup)
        }

        guard let urlString = matchingFavorite?.urlString else { return nil }
        return URL(string: urlString)
    }

    private func shouldShowCommandPaletteSuggestions(for query: String) -> Bool {
        guard !query.isEmpty else { return false }
        return true
    }

    private func shouldShowOpenNewTabSuggestion(for query: String) -> Bool {
        !query.lowercased().hasPrefix("fav add ")
    }

    private func matchingCommandSuggestions(for query: String) -> [CommandPaletteSuggestionItem] {
        let normalizedQuery = query.lowercased()
        guard !normalizedQuery.isEmpty else { return [] }

        return BrowserCommand.allCases.compactMap { command in
            let candidates = [command.title.lowercased()] + command.queryTokens
            guard candidates.contains(where: { $0.hasPrefix(normalizedQuery) }) else { return nil }

            return CommandPaletteSuggestionItem(
                id: "command-\(command.title.lowercased().replacingOccurrences(of: " ", with: "-"))",
                title: command.title,
                subtitle: command.queryTokens.first,
                kind: .command(command)
            )
        }
    }

    private func bestCommandCompletion(for query: String, command: BrowserCommand) -> String {
        let normalizedQuery = query.lowercased()
        let candidates = [command.title] + command.queryTokens
        return candidates.first { candidate in
            candidate.lowercased().hasPrefix(normalizedQuery)
        } ?? command.title
    }

    private func autocompleteSuffix(for query: String, completion: String) -> String? {
        guard completion.count > query.count else { return nil }
        guard completion.lowercased().hasPrefix(query.lowercased()) else { return nil }

        let suffixStart = completion.index(completion.startIndex, offsetBy: query.count)
        let suffix = String(completion[suffixStart...])
        return suffix.isEmpty ? nil : suffix
    }

    private func matchingCommandCompletionSuggestions(for query: String) -> [CommandPaletteSuggestionItem] {
        let normalizedQuery = query.lowercased()
        guard !normalizedQuery.isEmpty else { return [] }

        return commandCompletions.compactMap { completion in
            guard completion.tokens.contains(where: { $0.hasPrefix(normalizedQuery) }) else { return nil }

            return CommandPaletteSuggestionItem(
                id: "completion-\(completion.id)",
                title: completion.title,
                subtitle: completion.subtitle,
                kind: .commandCompletion(completion.completion)
            )
        }
    }

    private var commandCompletions: [CommandPaletteCompletion] {
        [
            CommandPaletteCompletion(
                id: "open-new-tab-with-input",
                title: "Open New Tab",
                subtitle: "ot <url or search>",
                completion: "ot ",
                tokens: ["ot", "open new tab", "open tab", "new tab with url", "new tab search"]
            ),
            CommandPaletteCompletion(
                id: "open-favorite",
                title: "Open Favorite",
                subtitle: "fav <alias>",
                completion: "fav",
                tokens: ["fav", "favorite", "open favorite", "open bookmark"]
            ),
            CommandPaletteCompletion(
                id: "add-favorite",
                title: "Add Favorite",
                subtitle: "fav add <alias>",
                completion: "fav add",
                tokens: ["fav add", "add favorite", "bookmark add", "save favorite"]
            ),
            CommandPaletteCompletion(
                id: "remove-favorite",
                title: "Remove Favorite",
                subtitle: "unfav <alias>",
                completion: "unfav",
                tokens: ["unfav", "remove favorite", "delete favorite", "remove bookmark"]
            )
        ]
    }

    private func matchingFavoriteAliasCompletionSuggestions(for query: String) -> [CommandPaletteSuggestionItem] {
        let parts = query.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let firstPart = parts.first?.lowercased() else { return [] }

        let commandPrefix: String
        let aliasQuery: String
        let titlePrefix: String

        switch firstPart {
        case "ot":
            commandPrefix = "ot "
            aliasQuery = parts.count > 1 ? parts[1] : ""
            titlePrefix = "Open Favorite in New Tab"
        case "fav":
            commandPrefix = "fav "
            aliasQuery = parts.count > 1 ? parts[1] : ""
            titlePrefix = "Open Favorite"
        case "unfav":
            commandPrefix = "unfav "
            aliasQuery = parts.count > 1 ? parts[1] : ""
            titlePrefix = "Remove Favorite"
        default:
            guard parts.count == 1 else { return [] }
            commandPrefix = ""
            aliasQuery = query
            titlePrefix = "Open Favorite"
        }

        let normalizedAliasQuery = aliasQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedAliasQuery.isEmpty else { return [] }

        return favorites
            .filter { favorite in
                favorite.alias.lowercased().hasPrefix(normalizedAliasQuery) ||
                    favorite.title.lowercased().hasPrefix(normalizedAliasQuery)
            }
            .map { favorite in
                CommandPaletteSuggestionItem(
                    id: "favorite-alias-\(commandPrefix)-\(favorite.id.uuidString)",
                    title: "\(titlePrefix) \(favorite.alias)",
                    subtitle: favorite.urlString,
                    kind: .commandCompletion("\(commandPrefix)\(favorite.alias)")
                )
            }
    }

    private func matchingClosedTabSuggestions(for query: String) -> [CommandPaletteSuggestionItem] {
        let normalizedQuery = query.lowercased()
        let shouldShowClosedTabs =
            "reopen closed tab".hasPrefix(normalizedQuery) ||
            "restore tab".hasPrefix(normalizedQuery) ||
            "history".hasPrefix(normalizedQuery) ||
            normalizedQuery.hasPrefix("rt ") ||
            normalizedQuery.hasPrefix("reopen ") ||
            normalizedQuery.hasPrefix("restore ") ||
            normalizedQuery.hasPrefix("history ")

        guard shouldShowClosedTabs else { return [] }

        let searchText = closedTabSearchText(from: normalizedQuery)

        return recentlyClosedTabs.compactMap { closedTab in
            let tabTitle = title(for: closedTab.tab, index: 0)
            let haystack = "\(tabTitle) \(closedTab.tab.currentURLString)".lowercased()
            guard searchText.isEmpty || haystack.contains(searchText) else { return nil }

            return CommandPaletteSuggestionItem(
                id: "closed-tab-\(closedTab.id.uuidString)",
                title: "Reopen \(tabTitle)",
                subtitle: closedTab.tab.currentURLString,
                kind: .reopenClosedTab(closedTab)
            )
        }
    }

    private func closedTabSearchText(from normalizedQuery: String) -> String {
        for prefix in ["rt ", "reopen ", "restore ", "history "] {
            if normalizedQuery.hasPrefix(prefix) {
                return String(normalizedQuery.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return ""
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

        let pageTitle = activeTab.pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = pageTitle.isEmpty ? (siteLabel(for: activeTab.currentPageURL) ?? activeTab.currentPageURL.host() ?? activeTab.currentURLString) : pageTitle
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

    private func refreshTabTitles() {
        tabRenderVersion += 1
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
                requestKeyboardFocus(.capture)
            }
        }

        clearFindState()
    }

    private func toggleHistory() {
        guard canHandleShortcut(.history) else { return }

        let shouldClearFind = activeOverlay == .find || !findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || findStatus != .empty

        withAnimation(.easeInOut(duration: 0.25)) {
            if activeOverlay == .history {
                historyFocusRequestID = 0
                selectedHistoryItemID = nil
                activeOverlay = .none
            } else {
                historySearchText = ""
                selectedHistoryItemID = historySidebarItems.first?.id
                if activeOverlay == .sidebar {
                    sidebarURLFocusRequestID = 0
                }
                if activeOverlay == .spotlight {
                    spotlightFocusRequestID = 0
                }
                activeOverlay = .history
                requestKeyboardFocus(.history)
            }
        }

        if shouldClearFind {
            clearFindState()
        }
    }

    private func toggleSpotlight() {
        guard canHandleShortcut(.spotlight) else { return }
        if activeOverlay == .sidebar {
            requestKeyboardFocus(.sidebarURL)
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
                activeOverlay = .spotlight
                requestKeyboardFocus(.spotlight)
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
            activeOverlay = .commandPalette
            requestKeyboardFocus(.commandPalette)
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

    private func completeSelectedCommandPaletteSuggestion() {
        guard !commandPaletteSuggestionItems.isEmpty else { return }

        switch commandPaletteSuggestionItems[normalizedCommandPaletteSelectionIndex].kind {
        case .command(let command):
            commandPaletteText = bestCommandCompletion(for: commandPaletteText.trimmingCharacters(in: .whitespacesAndNewlines), command: command)
            commandPaletteSelectionIndex = 0
            requestKeyboardFocus(.commandPalette)
        case .commandCompletion(let completion):
            commandPaletteText = completion
            commandPaletteSelectionIndex = 0
            requestKeyboardFocus(.commandPalette)
        case .reopenClosedTab:
            break
        case .openNew, .openTabMatch:
            break
        }
    }

    private func executeCommandPaletteSuggestion(at index: Int) {
        guard commandPaletteSuggestionItems.indices.contains(index) else { return }

        switch commandPaletteSuggestionItems[index].kind {
        case .command(let command):
            closeCommandPalette(restoreSelection: false)
            perform(command)
        case .commandCompletion(let completion):
            commandPaletteText = completion
            commandPaletteSelectionIndex = 0
            requestKeyboardFocus(.commandPalette)
        case .reopenClosedTab(let closedTab):
            closeCommandPalette(restoreSelection: false)
            if let index = recentlyClosedTabs.firstIndex(where: { $0.id == closedTab.id }) {
                let entry = recentlyClosedTabs.remove(at: index)
                restoreClosedTab(entry)
            }
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
        case .command, .commandCompletion, .reopenClosedTab, .openNew:
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
        let trimmedFindText = findText.trimmingCharacters(in: .whitespacesAndNewlines)

        if activeOverlay == .find {
            if trimmedFindText.isEmpty {
                findFocusRequestID = 0
                withAnimation(.easeInOut(duration: 0.1)) {
                    activeOverlay = .none
                }
            } else {
                clearFindState()
            }
            return
        }

        guard canHandleShortcut(.find) else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            activeOverlay = .find
            requestKeyboardFocus(.find)
        }

        if !trimmedFindText.isEmpty || findStatus != .empty {
            clearFindState()
        }
    }

    private func toggleSettings() {
        guard canHandleShortcut(.settings) else { return }

        let shouldClearFind = activeOverlay == .find || !findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || findStatus != .empty

        withAnimation(.easeInOut(duration: 0.1)) {
            if activeOverlay == .settings {
                activeOverlay = .none
            } else {
                if activeOverlay == .sidebar {
                    sidebarURLFocusRequestID = 0
                }
                if activeOverlay == .spotlight {
                    spotlightFocusRequestID = 0
                }
                activeOverlay = .settings
            }
        }

        if shouldClearFind {
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

    private func directURL(for rawInput: String) -> URL? {
        guard !rawInput.isEmpty else { return nil }

        if let explicitURL = URL(string: rawInput), explicitURL.scheme != nil {
            return explicitURL
        }

        if looksLikeHost(rawInput), let hostURL = URL(string: "https://\(rawInput)") {
            return hostURL
        }

        return nil
    }

    private func looksLikeHost(_ input: String) -> Bool {
        !input.contains(" ") && input.contains(".")
    }

    private func title(for tab: BrowserTab, index: Int) -> String {
        if tab.currentPageURL == BrowserHomePage.url {
            return "Tab \(index + 1)"
        }

        let pageTitle = tab.pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pageTitle.isEmpty {
            return pageTitle
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
