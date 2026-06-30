//
//  ContentView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct ContentView: View {
    private enum ActiveOverlay {
        case none
        case sidebar
        case spotlight
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
        case find
        case dismiss
    }

    @State private var activeOverlay: ActiveOverlay = .none
    @State private var workspaces: [BrowserWorkspace] = [BrowserWorkspace()]
    @State private var selectedWorkspaceID: UUID? = nil
    @State private var sidebarURLText = BrowserHomePage.url.absoluteString
    @State private var spotlightText = ""
    @State private var findText = ""
    @State private var findStatus = BrowserFindStatus.empty
    @State private var tabRenderVersion = 0
    @State private var lastShortcutAction: ShortcutAction?
    @State private var lastShortcutTimestamp = Date.distantPast
    private let shortcutCoalescingInterval: TimeInterval = 0.08

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
            sidebar
            spotlight
            findOverlay
            keyboardCaptureLayer
        }
        .onAppear {
            if selectedWorkspaceID == nil {
                selectedWorkspaceID = workspaces.first?.id
            }
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
                if let tab = selectedTab(in: workspace) {
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
                        onToggleFind: toggleFind,
                        onDismissOverlay: dismissSpotlight,
                        onGoBack: goBack,
                        onGoForward: goForward,
                        onReload: reload
                    )
                    .ignoresSafeArea()
                    .opacity(workspace.id == activeWorkspace?.id ? 1 : 0)
                    .allowsHitTesting(workspace.id == activeWorkspace?.id)
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
                onSelectTab: selectTab,
                onCloseTab: closeTab,
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

    private var keyboardCaptureLayer: some View {
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

    private func createNewWorkspace() {
        guard canHandleShortcut(.newWorkspace) else { return }

        let workspace = BrowserWorkspace()
        workspaces.append(workspace)
        selectedWorkspaceID = workspace.id
        tabRenderVersion += 1
        syncSidebarURLText()
        clearFindState()
    }

    private func createNewTab() {
        guard canHandleShortcut(.newTab) else { return }
        guard let workspace = activeWorkspace else { return }

        let newTab = BrowserTab()
        workspace.tabs.append(newTab)
        workspace.selectedTabID = newTab.id
        tabRenderVersion += 1
        syncSidebarURLText()

        clearFindState()
    }

    private func closeCurrentTab() {
        guard canHandleShortcut(.closeTab) else { return }
        guard let selectedTabID = activeWorkspace?.selectedTabID else { return }
        closeTab(selectedTabID)
    }

    private func closeCurrentWorkspace() {
        guard canHandleShortcut(.closeWorkspace) else { return }
        guard let selectedWorkspaceID else { return }
        closeWorkspace(selectedWorkspaceID)
    }

    private func selectNextWorkspace() {
        guard canHandleShortcut(.nextWorkspace) else { return }
        guard !workspaces.isEmpty else { return }

        let currentIndex = activeWorkspaceIndex ?? 0
        let nextIndex = (currentIndex + 1) % workspaces.count
        selectedWorkspaceID = workspaces[nextIndex].id
        tabRenderVersion += 1
    }

    private func selectPreviousWorkspace() {
        guard canHandleShortcut(.previousWorkspace) else { return }
        guard !workspaces.isEmpty else { return }

        let currentIndex = activeWorkspaceIndex ?? 0
        let previousIndex = (currentIndex - 1 + workspaces.count) % workspaces.count
        selectedWorkspaceID = workspaces[previousIndex].id
        tabRenderVersion += 1
    }

    private func selectNextTab() {
        guard canHandleShortcut(.nextTab) else { return }
        guard let workspace = activeWorkspace, !workspace.tabs.isEmpty else { return }

        let currentIndex = activeTabIndex ?? 0
        let nextIndex = (currentIndex + 1) % workspace.tabs.count
        workspace.selectedTabID = workspace.tabs[nextIndex].id
        tabRenderVersion += 1
        syncSidebarURLText()
        clearFindState()
    }

    private func selectPreviousTab() {
        guard canHandleShortcut(.previousTab) else { return }
        guard let workspace = activeWorkspace, !workspace.tabs.isEmpty else { return }

        let currentIndex = activeTabIndex ?? 0
        let previousIndex = (currentIndex - 1 + workspace.tabs.count) % workspace.tabs.count
        workspace.selectedTabID = workspace.tabs[previousIndex].id
        tabRenderVersion += 1
        syncSidebarURLText()
        clearFindState()
    }

    private func selectTab(_ id: UUID) {
        activeWorkspace?.selectedTabID = id
        tabRenderVersion += 1
        syncSidebarURLText()
        clearFindState()
    }

    private func closeTab(_ id: UUID) {
        guard let workspace = activeWorkspace else { return }
        guard let closingIndex = workspace.tabs.firstIndex(where: { $0.id == id }) else { return }

        if workspace.tabs.count == 1 {
            let replacementTab = BrowserTab()
            workspace.tabs = [replacementTab]
            workspace.selectedTabID = replacementTab.id
            tabRenderVersion += 1
            syncSidebarURLText()
            clearFindState()
            return
        }

        let fallbackTabID: UUID
        if closingIndex < workspace.tabs.count - 1 {
            fallbackTabID = workspace.tabs[closingIndex + 1].id
        } else {
            fallbackTabID = workspace.tabs[closingIndex - 1].id
        }

        workspace.tabs.remove(at: closingIndex)
        tabRenderVersion += 1

        if workspace.selectedTabID == id {
            workspace.selectedTabID = fallbackTabID
        }

        syncSidebarURLText()
        clearFindState()
    }

    private func closeWorkspace(_ id: UUID) {
        guard let closingIndex = workspaces.firstIndex(where: { $0.id == id }) else { return }

        if workspaces.count == 1 {
            let replacementWorkspace = BrowserWorkspace()
            workspaces = [replacementWorkspace]
            selectedWorkspaceID = replacementWorkspace.id
            tabRenderVersion += 1
            syncSidebarURLText()
            clearFindState()
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

        tabRenderVersion += 1
        ensureWorkspaceSelectionIntegrity()
        syncSidebarURLText()
        clearFindState()
    }

    private func submitSidebarURL() {
        guard let activeTab else { return }
        navigate(rawInput: sidebarURLText, in: activeTab)

        withAnimation(.easeInOut(duration: 0.1)) {
            activeOverlay = .none
        }
    }

    private func submitSpotlight() {
        guard let activeTab else { return }
        navigate(rawInput: spotlightText, in: activeTab)
        activeOverlay = .none
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

    private func toggleSidebar() {
        guard canHandleShortcut(.sidebar) else { return }

        syncSidebarURLText()

        withAnimation(.easeInOut(duration: 0.25)) {
            if activeOverlay == .sidebar {
                activeOverlay = .none
            } else {
                activeOverlay = .sidebar
            }
        }

        clearFindState()
    }

    private func toggleSpotlight() {
        guard canHandleShortcut(.spotlight) else { return }
        guard let activeTab else { return }

        let shouldClearFind = activeOverlay == .find || !findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || findStatus != .empty

        withAnimation(.easeInOut(duration: 0.1)) {
            spotlightText = activeTab.currentURLString
            if activeOverlay == .spotlight {
                activeOverlay = .none
            } else {
                activeOverlay = .spotlight
            }
        }

        if shouldClearFind {
            clearFindState()
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
