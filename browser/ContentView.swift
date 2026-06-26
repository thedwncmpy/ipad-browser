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
        case sidebar
        case spotlight
        case find
        case dismiss
    }

    @State private var activeOverlay: ActiveOverlay = .none
    @State private var currentURLString = "https://www.reddit.com"
    @State private var spotlightText = ""
    @State private var findText = ""
    @State private var findStatus = BrowserFindStatus.empty
    @State private var currentPageURL = URL(string: "https://www.reddit.com")!
    @State private var lastShortcutAction: ShortcutAction?
    @State private var lastShortcutTimestamp = Date.distantPast
    private let navigationController = BrowserNavigationController()
    private let shortcutCoalescingInterval: TimeInterval = 0.08

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
            sidebar
            spotlight
            findOverlay
            keyboardCaptureLayer
        }
    }

    private var mainContent: some View {
        ZStack {
            BrowserWebView(
                url: $currentPageURL,
                currentURLString: $currentURLString,
                navigationController: navigationController,
                onToggleSidebar: toggleSidebar,
                onToggleSpotlight: toggleSpotlight,
                onToggleFind: toggleFind,
                onDismissOverlay: dismissSpotlight,
                onGoBack: goBack,
                onGoForward: goForward,
                onReload: reload
            )
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var sidebar: some View {
        if activeOverlay == .sidebar {
            SidebarView(
                urlText: $currentURLString,
                currentPageURL: currentPageURL,
                onSubmit: {
                    let raw = currentURLString.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let url = destinationURL(for: raw) else { return }

                    currentPageURL = url
                    currentURLString = url.absoluteString
                    withAnimation(.easeInOut(duration: 0.1)) {
                        activeOverlay = .none
                    }
                }
            )
                .transition(.move(edge: .leading))
                .zIndex(1)
        }
    }

    @ViewBuilder
    private var spotlight: some View {
        if activeOverlay == .spotlight {
            SpotlightView(
                text: $spotlightText,
                pageURL: currentPageURL,
                showsFavicon: true,
                onSidebarShortcut: toggleSidebar,
                onFindShortcut: toggleFind,
                onSpotlightShortcut: toggleSpotlight,
                onSubmit: {
                    let raw = spotlightText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let url = destinationURL(for: raw) else { return }

                    currentPageURL = url
                    currentURLString = url.absoluteString
                    activeOverlay = .none
                },
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
                navigationController.findNext { status in
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

    private func toggleSidebar() {
        guard canHandleShortcut(.sidebar) else { return }

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

        let shouldClearFind = activeOverlay == .find || !findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || findStatus != .empty

        withAnimation(.easeInOut(duration: 0.1)) {
            spotlightText = currentURLString
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

        let hasExistingFind = !findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || findStatus != .empty

        withAnimation(.easeInOut(duration: 0.1)) {
            if activeOverlay == .find {
                if findText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    activeOverlay = .none
                }
            } else {
                activeOverlay = .find
            }
        }

        if activeOverlay == .find || hasExistingFind {
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
        navigationController.goBack()
    }

    private func goForward() {
        navigationController.goForward()
    }

    private func reload() {
        navigationController.reload()
    }

    private func updateFindResults(_ text: String) {
        navigationController.find(text) { status in
            findStatus = status
        }
    }

    private func clearFindState() {
        findText = ""
        findStatus = .empty
        navigationController.clearFind()
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
