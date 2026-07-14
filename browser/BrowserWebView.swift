//
//  BrowserWebView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI
import WebKit

final class BrowserWKWebView: WKWebView {
    var onNewWorkspace: (() -> Void)?
    var onNewTab: (() -> Void)?
    var onCloseWorkspace: (() -> Void)?
    var onCloseTab: (() -> Void)?
    var onReopenClosedTab: (() -> Void)?
    var onNextWorkspace: (() -> Void)?
    var onPreviousWorkspace: (() -> Void)?
    var onNextTab: (() -> Void)?
    var onPreviousTab: (() -> Void)?
    var onMoveTabToNextWorkspace: (() -> Void)?
    var onMoveTabToPreviousWorkspace: (() -> Void)?
    var onMoveTabDown: (() -> Void)?
    var onMoveTabUp: (() -> Void)?
    var onToggleSidebar: (() -> Void)?
    var onToggleSpotlight: (() -> Void)?
    var onToggleCommandPalette: (() -> Void)?
    var onToggleFind: (() -> Void)?
    var onToggleHistory: (() -> Void)?
    var onToggleSettings: (() -> Void)?
    var onDismissOverlay: (() -> Void)?
    var onGoBackShortcut: (() -> Void)?
    var onGoForwardShortcut: (() -> Void)?
    var onReloadShortcut: (() -> Void)?
    var onToggleNetworkTools: (() -> Void)?
    var isSidebarNavigationEnabled = false
    var shortcuts = BrowserShortcutStore.defaults

    override var keyCommands: [UIKeyCommand]? {
        var commands = BrowserKeyboardCommands.makeKeyCommands(
            newWorkspaceSelector: #selector(handleNewWorkspace(_:)),
            newTabSelector: #selector(handleNewTab(_:)),
            closeWorkspaceSelector: #selector(handleCloseWorkspace(_:)),
            closeTabSelector: #selector(handleCloseTab(_:)),
            reopenClosedTabSelector: #selector(handleReopenClosedTab(_:)),
            nextWorkspaceSelector: #selector(handleNextWorkspace(_:)),
            previousWorkspaceSelector: #selector(handlePreviousWorkspace(_:)),
            nextTabSelector: #selector(handleNextTab(_:)),
            previousTabSelector: #selector(handlePreviousTab(_:)),
            moveTabToNextWorkspaceSelector: #selector(handleMoveTabToNextWorkspace(_:)),
            moveTabToPreviousWorkspaceSelector: #selector(handleMoveTabToPreviousWorkspace(_:)),
            moveTabDownSelector: #selector(handleMoveTabDown(_:)),
            moveTabUpSelector: #selector(handleMoveTabUp(_:)),
            sidebarSelector: #selector(handleSidebarToggle(_:)),
            spotlightSelector: #selector(handleSpotlightToggle(_:)),
            commandPaletteSelector: #selector(handleCommandPaletteToggle(_:)),
            findSelector: #selector(handleFindToggle(_:)),
            historySelector: #selector(handleHistoryToggle(_:)),
            settingsSelector: #selector(handleSettingsToggle(_:)),
            dismissSelector: #selector(handleDismiss(_:)),
            backSelector: #selector(handleGoBack(_:)),
            forwardSelector: #selector(handleGoForward(_:)),
            reloadSelector: #selector(handleReload(_:)),
            networkToolsSelector: #selector(handleNetworkToolsToggle(_:)),
            shortcuts: shortcuts
        )

        if isSidebarNavigationEnabled {
            commands.append(contentsOf: [
                shortcuts[.sidebarModeNextTab, default: BrowserShortcutStore.defaults[.sidebarModeNextTab]!].makeCommand(action: #selector(handleNextTab(_:))),
                sidebarNavigationCommand(input: UIKeyCommand.inputDownArrow, action: #selector(handleNextTab(_:))),
                shortcuts[.sidebarModePreviousTab, default: BrowserShortcutStore.defaults[.sidebarModePreviousTab]!].makeCommand(action: #selector(handlePreviousTab(_:))),
                sidebarNavigationCommand(input: UIKeyCommand.inputUpArrow, action: #selector(handlePreviousTab(_:))),
                shortcuts[.sidebarModePreviousWorkspace, default: BrowserShortcutStore.defaults[.sidebarModePreviousWorkspace]!].makeCommand(action: #selector(handlePreviousWorkspace(_:))),
                sidebarNavigationCommand(input: UIKeyCommand.inputLeftArrow, action: #selector(handlePreviousWorkspace(_:))),
                shortcuts[.sidebarModeNextWorkspace, default: BrowserShortcutStore.defaults[.sidebarModeNextWorkspace]!].makeCommand(action: #selector(handleNextWorkspace(_:))),
                sidebarNavigationCommand(input: UIKeyCommand.inputRightArrow, action: #selector(handleNextWorkspace(_:)))
            ])
        }

        return commands
    }

    private func sidebarNavigationCommand(input: String, action: Selector) -> UIKeyCommand {
        let command = UIKeyCommand(input: input, modifierFlags: [], action: action)
        command.wantsPriorityOverSystemBehavior = true
        return command
    }

    @objc private func handleNewTab(_ sender: UIKeyCommand) {
        onNewTab?()
    }

    @objc private func handleNewWorkspace(_ sender: UIKeyCommand) {
        onNewWorkspace?()
    }

    @objc private func handleCloseTab(_ sender: UIKeyCommand) {
        onCloseTab?()
    }

    @objc private func handleReopenClosedTab(_ sender: UIKeyCommand) {
        onReopenClosedTab?()
    }

    @objc private func handleCloseWorkspace(_ sender: UIKeyCommand) {
        onCloseWorkspace?()
    }

    @objc private func handleNextTab(_ sender: UIKeyCommand) {
        onNextTab?()
    }

    @objc private func handlePreviousTab(_ sender: UIKeyCommand) {
        onPreviousTab?()
    }

    @objc private func handleMoveTabToNextWorkspace(_ sender: UIKeyCommand) {
        onMoveTabToNextWorkspace?()
    }

    @objc private func handleMoveTabToPreviousWorkspace(_ sender: UIKeyCommand) {
        onMoveTabToPreviousWorkspace?()
    }

    @objc private func handleMoveTabDown(_ sender: UIKeyCommand) {
        onMoveTabDown?()
    }

    @objc private func handleMoveTabUp(_ sender: UIKeyCommand) {
        onMoveTabUp?()
    }

    @objc private func handleNextWorkspace(_ sender: UIKeyCommand) {
        onNextWorkspace?()
    }

    @objc private func handlePreviousWorkspace(_ sender: UIKeyCommand) {
        onPreviousWorkspace?()
    }

    @objc private func handleSidebarToggle(_ sender: UIKeyCommand) {
        onToggleSidebar?()
    }

    @objc private func handleSpotlightToggle(_ sender: UIKeyCommand) {
        onToggleSpotlight?()
    }

    @objc private func handleCommandPaletteToggle(_ sender: UIKeyCommand) {
        onToggleCommandPalette?()
    }

    @objc private func handleFindToggle(_ sender: UIKeyCommand) {
        onToggleFind?()
    }

    @objc private func handleHistoryToggle(_ sender: UIKeyCommand) {
        onToggleHistory?()
    }

    @objc private func handleSettingsToggle(_ sender: UIKeyCommand) {
        onToggleSettings?()
    }

    @objc private func handleDismiss(_ sender: UIKeyCommand) {
        onDismissOverlay?()
    }

    @objc private func handleGoBack(_ sender: UIKeyCommand) {
        onGoBackShortcut?()
    }

    @objc private func handleGoForward(_ sender: UIKeyCommand) {
        onGoForwardShortcut?()
    }

    @objc private func handleReload(_ sender: UIKeyCommand) {
        onReloadShortcut?()
    }

    @objc private func handleNetworkToolsToggle(_ sender: UIKeyCommand) {
        onToggleNetworkTools?()
    }
}

struct BrowserFindStatus: Equatable {
    let current: Int
    let total: Int

    static let empty = BrowserFindStatus(current: 0, total: 0)
}

@MainActor
final class BrowserNavigationController {
    private(set) var webView: BrowserWKWebView?
    private(set) var lastFindQuery = ""

    func attach(webView: BrowserWKWebView) {
        self.webView = webView
    }

    func goBack() {
        guard let webView, webView.canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        guard let webView, webView.canGoForward else { return }
        webView.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func pauseMedia() {
        webView?.evaluateJavaScript("""
        (() => {
            for (const media of document.querySelectorAll('audio, video')) {
                media.pause();
            }
        })();
        """)
    }

    func toggleErudaDeveloperTools() {
        webView?.evaluateJavaScript("""
        (() => {
            function hideEntryButton() {
                for (const node of Array.from(document.querySelectorAll('.eruda-entry-btn'))) {
                    node.style.setProperty('display', 'none', 'important');
                }
            }

            function showTools() {
                if (!window.__browserErudaInitialized && window.eruda) {
                    window.eruda.init({
                        tool: ['console', 'elements', 'network', 'resources', 'sources', 'info']
                    });
                    window.__browserErudaInitialized = true;
                }

                if (window.eruda) {
                    window.eruda.show();
                    hideEntryButton();
                    requestAnimationFrame(hideEntryButton);
                    setTimeout(hideEntryButton, 100);
                }
            }

            if (window.eruda && window.__browserErudaVisible) {
                window.eruda.hide();
                window.__browserErudaVisible = false;
                return;
            }

            if (window.eruda) {
                showTools();
                window.__browserErudaVisible = true;
                return;
            }

            const script = document.createElement('script');
            script.src = 'https://cdn.jsdelivr.net/npm/eruda';
            script.onload = () => {
                showTools();
                window.__browserErudaVisible = true;
            };
            document.head.appendChild(script);
        })();
        """)
    }

    func find(_ text: String, completion: @escaping (BrowserFindStatus) -> Void) {
        guard let webView else { return }
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        lastFindQuery = query

        guard !query.isEmpty else {
            clearFind(completion: completion)
            return
        }

        let script = """
        (function(query) {
            const highlightClass = 'browser-find-match';
            const activeClass = 'browser-find-match-active';

            function clearHighlights() {
                const matches = Array.from(document.querySelectorAll('.' + highlightClass));
                for (const match of matches) {
                    const parent = match.parentNode;
                    if (!parent) continue;
                    parent.replaceChild(document.createTextNode(match.textContent || ''), match);
                    parent.normalize();
                }
            }

            function setActive(index) {
                const matches = Array.from(document.querySelectorAll('.' + highlightClass));
                matches.forEach((match, idx) => {
                    if (idx === index) {
                        match.classList.add(activeClass);
                        match.scrollIntoView({ block: 'center', inline: 'nearest', behavior: 'smooth' });
                    } else {
                        match.classList.remove(activeClass);
                    }
                });
                window.__browserFindCurrentIndex = index;
            }

            clearHighlights();
            const normalizedQuery = query.toLocaleLowerCase();
            if (!normalizedQuery) {
                window.__browserFindCurrentIndex = -1;
                return JSON.stringify({ current: 0, total: 0 });
            }

            const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
                acceptNode(node) {
                    const parent = node.parentElement;
                    if (!parent) return NodeFilter.FILTER_REJECT;
                    const tag = parent.tagName;
                    if (['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEXTAREA'].includes(tag)) {
                        return NodeFilter.FILTER_REJECT;
                    }
                    if (!node.textContent || !node.textContent.trim()) {
                        return NodeFilter.FILTER_REJECT;
                    }
                    return NodeFilter.FILTER_ACCEPT;
                }
            });

            const textNodes = [];
            while (walker.nextNode()) {
                textNodes.push(walker.currentNode);
            }

            let matchCount = 0;
            for (const node of textNodes) {
                const text = node.textContent || '';
                const lower = text.toLocaleLowerCase();
                let searchIndex = 0;
                let matchIndex = lower.indexOf(normalizedQuery, searchIndex);
                if (matchIndex === -1) continue;

                const fragment = document.createDocumentFragment();
                while (matchIndex !== -1) {
                    if (matchIndex > searchIndex) {
                        fragment.appendChild(document.createTextNode(text.slice(searchIndex, matchIndex)));
                    }

                    const span = document.createElement('span');
                    span.className = highlightClass;
                    span.textContent = text.slice(matchIndex, matchIndex + query.length);
                    span.setAttribute('data-browser-find-index', String(matchCount));
                    fragment.appendChild(span);
                    matchCount += 1;

                    searchIndex = matchIndex + query.length;
                    matchIndex = lower.indexOf(normalizedQuery, searchIndex);
                }

                if (searchIndex < text.length) {
                    fragment.appendChild(document.createTextNode(text.slice(searchIndex)));
                }

                node.parentNode.replaceChild(fragment, node);
            }

            if (!document.getElementById('browser-find-style')) {
                const style = document.createElement('style');
                style.id = 'browser-find-style';
                style.textContent = `
                    .${highlightClass} { background: rgba(255, 224, 102, 0.72); color: inherit; border-radius: 2px; }
                    .${activeClass} { background: rgba(255, 153, 51, 0.95); outline: 1px solid rgba(255,255,255,0.5); }
                `;
                document.head.appendChild(style);
            }

            if (matchCount > 0) {
                setActive(0);
                return JSON.stringify({ current: 1, total: matchCount });
            }

            window.__browserFindCurrentIndex = -1;
            return JSON.stringify({ current: 0, total: 0 });
        })(\(javaScriptStringLiteral(query)));
        """

        webView.evaluateJavaScript(script) { [weak self] result, _ in
            let status = self?.parseFindStatus(result) ?? .empty
            completion(status)
        }
    }

    func findNext(completion: @escaping (BrowserFindStatus) -> Void) {
        guard let webView else { return }

        let script = """
        (function() {
            const highlightClass = 'browser-find-match';
            const activeClass = 'browser-find-match-active';
            const matches = Array.from(document.querySelectorAll('.' + highlightClass));
            if (!matches.length) {
                window.__browserFindCurrentIndex = -1;
                return JSON.stringify({ current: 0, total: 0 });
            }

            let currentIndex = typeof window.__browserFindCurrentIndex === 'number' ? window.__browserFindCurrentIndex : -1;
            currentIndex = (currentIndex + 1 + matches.length) % matches.length;
            matches.forEach((match, idx) => {
                if (idx === currentIndex) {
                    match.classList.add(activeClass);
                    match.scrollIntoView({ block: 'center', inline: 'nearest', behavior: 'smooth' });
                } else {
                    match.classList.remove(activeClass);
                }
            });
            window.__browserFindCurrentIndex = currentIndex;
            return JSON.stringify({ current: currentIndex + 1, total: matches.length });
        })();
        """

        webView.evaluateJavaScript(script) { [weak self] result, _ in
            let status = self?.parseFindStatus(result) ?? .empty
            completion(status)
        }
    }

    func clearFind(completion: ((BrowserFindStatus) -> Void)? = nil) {
        lastFindQuery = ""
        guard let webView else {
            completion?(.empty)
            return
        }

        let script = """
        (function() {
            const matches = Array.from(document.querySelectorAll('.browser-find-match'));
            for (const match of matches) {
                const parent = match.parentNode;
                if (!parent) continue;
                parent.replaceChild(document.createTextNode(match.textContent || ''), match);
                parent.normalize();
            }
            window.__browserFindCurrentIndex = -1;
            return JSON.stringify({ current: 0, total: 0 });
        })();
        """

        webView.evaluateJavaScript(script) { [weak self] result, _ in
            let status = self?.parseFindStatus(result) ?? .empty
            completion?(status)
        }
    }

    private func parseFindStatus(_ result: Any?) -> BrowserFindStatus {
        guard
            let jsonString = result as? String,
            let data = jsonString.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let current = object["current"] as? Int,
            let total = object["total"] as? Int
        else {
            return .empty
        }

        return BrowserFindStatus(current: current, total: total)
    }

    private func javaScriptStringLiteral(_ value: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [value], options: [])
        guard
            let data,
            let json = String(data: data, encoding: .utf8),
            json.count >= 2
        else {
            return "\"\""
        }

        return String(json.dropFirst().dropLast())
    }
}

struct BrowserWebView: UIViewRepresentable {
    @Binding var url: URL
    @Binding var currentURLString: String
    @Binding var pageTitle: String
    let navigationController: BrowserNavigationController
    let focusRequestID: Int?
    let isSidebarNavigationEnabled: Bool
    let onNewWorkspace: () -> Void
    let onNewTab: () -> Void
    let onCloseWorkspace: () -> Void
    let onCloseTab: () -> Void
    let onReopenClosedTab: () -> Void
    let onNextWorkspace: () -> Void
    let onPreviousWorkspace: () -> Void
    let onNextTab: () -> Void
    let onPreviousTab: () -> Void
    let onMoveTabToNextWorkspace: () -> Void
    let onMoveTabToPreviousWorkspace: () -> Void
    let onMoveTabDown: () -> Void
    let onMoveTabUp: () -> Void
    let onToggleSidebar: () -> Void
    let onToggleSpotlight: () -> Void
    let onToggleCommandPalette: () -> Void
    let onToggleFind: () -> Void
    let onToggleHistory: () -> Void
    let onToggleSettings: () -> Void
    let onToggleNetworkTools: () -> Void
    let onDismissOverlay: () -> Void
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onReload: () -> Void
    let onPageTitleChange: () -> Void
    let shortcuts: [BrowserShortcutAction: BrowserShortcut]

    private static func makeWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop

        return configuration
    }

    private static let desktopSafariUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"

    private static func desktopRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(desktopSafariUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("?0", forHTTPHeaderField: "Sec-CH-UA-Mobile")
        return request
    }

    func makeUIView(context: Context) -> BrowserWKWebView {
        let webView: BrowserWKWebView
        let shouldLoadInitialURL: Bool

        if let cachedWebView = navigationController.webView {
            webView = cachedWebView
            webView.removeFromSuperview()
            shouldLoadInitialURL = false
        } else {
            let configuration = Self.makeWebViewConfiguration()
            webView = BrowserWKWebView(frame: .zero, configuration: configuration)
            webView.customUserAgent = Self.desktopSafariUserAgent
            shouldLoadInitialURL = true
        }

        configureInspection(for: webView)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.onPageTitleChange = onPageTitleChange
        context.coordinator.attach(to: webView)
        context.coordinator.lastRequestedURL = url
        navigationController.attach(webView: webView)
        configureShortcuts(for: webView)

        if shouldLoadInitialURL {
            load(url, in: webView, deferUntilLaidOut: true)
        }

        currentURLString = url.absoluteString
        return webView
    }

    func updateUIView(_ uiView: BrowserWKWebView, context: Context) {
        configureInspection(for: uiView)
        context.coordinator.onPageTitleChange = onPageTitleChange
        configureShortcuts(for: uiView)
        syncSidebarNavigationMode(in: uiView, context: context)

        if let focusRequestID, context.coordinator.lastAppliedFocusRequestID != focusRequestID {
            context.coordinator.lastAppliedFocusRequestID = focusRequestID
            DispatchQueue.main.async {
                _ = uiView.becomeFirstResponder()
                if uiView.url?.scheme == "about" || self.url == BrowserHomePage.url {
                    uiView.evaluateJavaScript("window.__browserFocusSelectedFavorite && window.__browserFocusSelectedFavorite();")
                }
            }
        }

        if context.coordinator.lastRequestedURL != url {
            context.coordinator.lastRequestedURL = url
            load(url, in: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: $url, currentURLString: $currentURLString, pageTitle: $pageTitle)
    }

    private func configureShortcuts(for webView: BrowserWKWebView) {
        webView.onNewWorkspace = onNewWorkspace
        webView.onNewTab = onNewTab
        webView.onCloseWorkspace = onCloseWorkspace
        webView.onCloseTab = onCloseTab
        webView.onReopenClosedTab = onReopenClosedTab
        webView.onNextWorkspace = onNextWorkspace
        webView.onPreviousWorkspace = onPreviousWorkspace
        webView.onNextTab = onNextTab
        webView.onPreviousTab = onPreviousTab
        webView.onMoveTabToNextWorkspace = onMoveTabToNextWorkspace
        webView.onMoveTabToPreviousWorkspace = onMoveTabToPreviousWorkspace
        webView.onMoveTabDown = onMoveTabDown
        webView.onMoveTabUp = onMoveTabUp
        webView.onToggleSidebar = onToggleSidebar
        webView.onToggleSpotlight = onToggleSpotlight
        webView.onToggleCommandPalette = onToggleCommandPalette
        webView.onToggleFind = onToggleFind
        webView.onToggleHistory = onToggleHistory
        webView.onToggleSettings = onToggleSettings
        webView.onToggleNetworkTools = onToggleNetworkTools
        webView.onDismissOverlay = onDismissOverlay
        webView.onGoBackShortcut = onGoBack
        webView.onGoForwardShortcut = onGoForward
        webView.onReloadShortcut = onReload
        webView.isSidebarNavigationEnabled = isSidebarNavigationEnabled
        webView.shortcuts = shortcuts
    }

    private func configureInspection(for webView: BrowserWKWebView) {
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
    }

    private func syncSidebarNavigationMode(in webView: WKWebView, context: Context) {
        context.coordinator.isSidebarNavigationEnabled = isSidebarNavigationEnabled
        guard context.coordinator.lastAppliedSidebarNavigationEnabled != isSidebarNavigationEnabled else { return }
        context.coordinator.lastAppliedSidebarNavigationEnabled = isSidebarNavigationEnabled

        context.coordinator.applySidebarNavigationMode(to: webView)
    }

    private func load(_ url: URL, in webView: WKWebView, deferUntilLaidOut: Bool = false, attempt: Int = 0) {
        if deferUntilLaidOut,
           url != BrowserHomePage.url,
           webView.bounds.width <= 0,
           attempt < 20
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                load(url, in: webView, deferUntilLaidOut: true, attempt: attempt + 1)
            }
            return
        }

        if url == BrowserHomePage.url {
            webView.loadHTMLString(BrowserHomePage.html(), baseURL: nil)
        } else {
            webView.load(Self.desktopRequest(for: url))
        }
    }
}

extension BrowserWebView {
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        @Binding private var url: URL
        @Binding private var currentURLString: String
        @Binding private var pageTitle: String
        var lastRequestedURL: URL?
        var lastAppliedFocusRequestID: Int?
        var lastAppliedSidebarNavigationEnabled: Bool?
        var isSidebarNavigationEnabled = false
        var onPageTitleChange: (() -> Void)?
        private var urlObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?

        init(url: Binding<URL>, currentURLString: Binding<String>, pageTitle: Binding<String>) {
            _url = url
            _currentURLString = currentURLString
            _pageTitle = pageTitle
        }

        func attach(to webView: WKWebView) {
            urlObservation = webView.observe(\.url, options: [.initial, .new]) { [weak self] webView, _ in
                guard let self else { return }
                self.syncObservedURL(from: webView.url)
            }
            titleObservation = webView.observe(\.title, options: [.initial, .new]) { [weak self] webView, _ in
                guard let self else { return }
                self.syncObservedTitle(from: webView.title)
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            syncObservedURL(from: webView.url)
            applySidebarNavigationMode(to: webView)

            if url == BrowserHomePage.url {
                webView.becomeFirstResponder()
                webView.evaluateJavaScript("window.__browserFocusSelectedFavorite && window.__browserFocusSelectedFavorite();")
            }
        }

        func applySidebarNavigationMode(to webView: WKWebView) {
            let value = isSidebarNavigationEnabled ? "true" : "false"
            webView.evaluateJavaScript("window.__browserSidebarNavigationEnabled = \(value);")
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let requestURL = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if requestURL.scheme == "browser",
               requestURL.host() == "open",
               let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false),
               let targetURLString = components.queryItems?.first(where: { $0.name == "url" })?.value,
               let targetURL = URL(string: targetURLString)
            {
                decisionHandler(.cancel)
                lastRequestedURL = targetURL
                url = targetURL
                currentURLString = targetURL.absoluteString
                webView.load(BrowserWebView.desktopRequest(for: targetURL))
                return
            }

            if shouldCancelExternalNavigation(to: requestURL) {
                decisionHandler(.cancel)
                return
            }

            if navigationAction.navigationType == .linkActivated,
               requestURL.scheme?.hasPrefix("http") == true
            {
                decisionHandler(.cancel)
                loadInCurrentWebView(requestURL, webView: webView)
                return
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil, let requestURL = navigationAction.request.url else {
                return nil
            }

            guard !shouldCancelExternalNavigation(to: requestURL) else {
                return nil
            }

            loadInCurrentWebView(requestURL, webView: webView)
            return nil
        }

        private func loadInCurrentWebView(_ requestURL: URL, webView: WKWebView) {
            lastRequestedURL = requestURL
            url = requestURL
            currentURLString = requestURL.absoluteString
            webView.load(BrowserWebView.desktopRequest(for: requestURL))
        }

        private func shouldCancelExternalNavigation(to requestURL: URL) -> Bool {
            guard let scheme = requestURL.scheme?.lowercased() else { return false }

            switch scheme {
            case "http", "https", "about", "blob", "data", "browser":
                return false
            default:
                return true
            }
        }

        private func syncObservedURL(from observedURL: URL?) {
            guard let observedURL else { return }

            if observedURL.scheme == "about", lastRequestedURL == BrowserHomePage.url {
                url = BrowserHomePage.url
                currentURLString = BrowserHomePage.url.absoluteString
                lastRequestedURL = BrowserHomePage.url
                return
            }

            if observedURL.scheme == "browser", observedURL.host() == "open" {
                return
            }

            url = observedURL
            currentURLString = observedURL.absoluteString
            lastRequestedURL = observedURL
        }

        private func syncObservedTitle(from observedTitle: String?) {
            let title = observedTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard pageTitle != title else { return }
            pageTitle = title
            onPageTitleChange?()
        }
    }
}

#Preview {
    BrowserWebView(
        url: .constant(URL(string: "https://www.reddit.com")!),
        currentURLString: .constant("https://www.reddit.com"),
        pageTitle: .constant("Reddit"),
        navigationController: BrowserNavigationController(),
        focusRequestID: nil,
        isSidebarNavigationEnabled: false,
        onNewWorkspace: {},
        onNewTab: {},
        onCloseWorkspace: {},
        onCloseTab: {},
        onReopenClosedTab: {},
        onNextWorkspace: {},
        onPreviousWorkspace: {},
        onNextTab: {},
        onPreviousTab: {},
        onMoveTabToNextWorkspace: {},
        onMoveTabToPreviousWorkspace: {},
        onMoveTabDown: {},
        onMoveTabUp: {},
        onToggleSidebar: {},
        onToggleSpotlight: {},
        onToggleCommandPalette: {},
        onToggleFind: {},
        onToggleHistory: {},
        onToggleSettings: {},
        onToggleNetworkTools: {},
        onDismissOverlay: {},
        onGoBack: {},
        onGoForward: {},
        onReload: {},
        onPageTitleChange: {},
        shortcuts: BrowserShortcutStore.defaults
    )
}
