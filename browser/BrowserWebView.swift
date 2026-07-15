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

    func toggleErudaDeveloperTools(completion: ((Bool) -> Void)? = nil) {
        webView?.evaluateJavaScript("""
        (() => {
            const state = window.__browserDebugState || (window.__browserDebugState = {
                installed: false,
                visible: false,
                logs: [],
                requests: [],
                selectedTab: 'console',
                sourceMode: 'tree',
                selectedNodeID: '0',
                expandedNodeIDs: ['0'],
                selectedRequestID: null,
                nextRequestID: 1,
                networkListScrollTop: 0,
                networkDetailsScrollTop: 0,
                sourceBodyScrollTop: 0,
                sourceTreeScrollTop: 0,
                sourceNodeLimit: 600,
                renderScheduled: false,
                networkRenderScheduled: false,
                logVersion: 0,
                requestVersion: 0,
                sourceVersion: 0,
                cache: {},
                maxEntries: 120
            });
            if (state.sourceBodyScrollTop == null) state.sourceBodyScrollTop = 0;
            if (state.sourceTreeScrollTop == null) state.sourceTreeScrollTop = 0;
            if (state.sourceNodeLimit == null || state.sourceNodeLimit > 600) state.sourceNodeLimit = 600;
            if (state.renderScheduled == null) state.renderScheduled = false;
            if (state.networkRenderScheduled == null) state.networkRenderScheduled = false;
            if (state.logVersion == null) state.logVersion = 0;
            if (state.requestVersion == null) state.requestVersion = 0;
            if (state.sourceVersion == null) state.sourceVersion = 0;
            if (!state.cache) state.cache = {};

            const safeString = (value) => {
                try {
                    if (typeof value === 'string') return value;
                    if (value instanceof Error) return value.stack || value.message;
                    return JSON.stringify(value);
                } catch (_) {
                    return String(value);
                }
            };

            const trimEntries = (items) => {
                if (items.length > state.maxEntries) {
                    items.splice(0, items.length - state.maxEntries);
                }
            };

            const cachedValue = (name, key, producer) => {
                const entry = state.cache[name];
                if (entry && entry.key === key) return entry.value;
                const value = producer();
                state.cache[name] = { key, value };
                return value;
            };

            const cachedValueFor = (name, key, producer, ttl = 1000) => {
                const now = Date.now();
                const entry = state.cache[name];
                if (entry && entry.key === key && now - entry.time < ttl) return entry.value;
                const value = producer();
                state.cache[name] = { key, value, time: now };
                return value;
            };

            const headersToObject = (headers) => {
                const output = {};
                if (!headers) return output;
                try {
                    if (headers instanceof Headers) {
                        headers.forEach((value, key) => output[key] = value);
                    } else if (Array.isArray(headers)) {
                        headers.forEach(([key, value]) => output[key] = value);
                    } else {
                        Object.assign(output, headers);
                    }
                } catch (error) {
                    output.error = safeString(error);
                }
                return output;
            };

            const bodyPreview = (body) => {
                if (body == null) return '';
                if (typeof body === 'string') return body.slice(0, 5000);
                if (body instanceof URLSearchParams) return body.toString().slice(0, 5000);
                if (body instanceof FormData) {
                    const rows = [];
                    body.forEach((value, key) => rows.push(`${key}: ${value instanceof File ? value.name : value}`));
                    return rows.join('\\n').slice(0, 5000);
                }
                return safeString(body).slice(0, 5000);
            };

            const isDrawerVisible = () => {
                const drawer = document.getElementById('browser-debug-drawer');
                return !!(drawer && !drawer.hidden && state.visible);
            };

            const scheduleRender = () => {
                if (!isDrawerVisible() || state.renderScheduled) return;
                state.renderScheduled = true;
                setTimeout(() => {
                    state.renderScheduled = false;
                    if (isDrawerVisible() && window.__browserDebugRender) {
                        window.__browserDebugRender();
                    }
                }, 250);
            };

            const scheduleNetworkRender = (changedRequestID = null, forceDetails = false) => {
                if (!isDrawerVisible()) return;
                if (state.selectedTab !== 'network') {
                    scheduleRender();
                    return;
                }
                if (state.networkRenderScheduled) return;
                state.networkRenderScheduled = true;
                setTimeout(() => {
                    state.networkRenderScheduled = false;
                    if (isDrawerVisible() && window.__browserDebugRenderNetwork) {
                        window.__browserDebugRenderNetwork(changedRequestID, forceDetails);
                    }
                }, 250);
            };

            const addRequest = (request) => {
                const previousSelectedRequestID = state.selectedRequestID;
                state.requests.push(request);
                trimEntries(state.requests);

                if (previousSelectedRequestID == null) {
                    state.selectedRequestID = request.id;
                } else if (state.requests.some((entry) => entry.id === previousSelectedRequestID)) {
                    state.selectedRequestID = previousSelectedRequestID;
                } else {
                    state.selectedRequestID = state.requests.length ? state.requests[state.requests.length - 1].id : null;
                }

                state.requestVersion += 1;
                scheduleNetworkRender();
            };

            if (!state.installed) {
                state.installed = true;

                for (const level of ['log', 'info', 'warn', 'error']) {
                    const original = console[level];
                    console[level] = function(...args) {
                        state.logs.push({
                            level,
                            time: new Date().toLocaleTimeString(),
                            message: args.map(safeString).join(' ')
                        });
                        trimEntries(state.logs);
                        state.logVersion += 1;
                        scheduleRender();
                        return original.apply(this, args);
                    };
                }

                const originalFetch = window.fetch;
                if (originalFetch) {
                    window.fetch = async function(input, init) {
                        const startedAt = performance.now();
                        const method = String((init && init.method) || (input && input.method) || 'GET').toUpperCase();
                        const url = typeof input === 'string' ? input : (input && input.url) || '';
                        const requestID = state.nextRequestID++;
                        try {
                            const response = await originalFetch.apply(this, arguments);
                            const requestEntry = {
                                id: requestID,
                                type: 'fetch',
                                method,
                                url,
                                startedAt: new Date().toLocaleTimeString(),
                                status: response.status,
                                statusText: response.statusText,
                                ok: response.ok,
                                duration: Math.round(performance.now() - startedAt),
                                requestHeaders: headersToObject((init && init.headers) || (input && input.headers)),
                                requestBody: bodyPreview(init && init.body),
                                responseHeaders: headersToObject(response.headers),
                                responseBody: '',
                                responseBodySkipped: true
                            };
                            addRequest(requestEntry);
                            return response;
                        } catch (error) {
                            addRequest({
                                id: requestID,
                                type: 'fetch',
                                method,
                                url,
                                startedAt: new Date().toLocaleTimeString(),
                                status: 'ERR',
                                statusText: 'Request failed',
                                ok: false,
                                duration: Math.round(performance.now() - startedAt),
                                requestHeaders: headersToObject((init && init.headers) || (input && input.headers)),
                                requestBody: bodyPreview(init && init.body),
                                responseHeaders: {},
                                responseBody: '',
                                error: safeString(error)
                            });
                            throw error;
                        }
                    };
                }

                const originalOpen = XMLHttpRequest.prototype.open;
                const originalSend = XMLHttpRequest.prototype.send;
                XMLHttpRequest.prototype.open = function(method, url) {
                    this.__browserDebugRequest = {
                        id: state.nextRequestID++,
                        method: String(method || 'GET').toUpperCase(),
                        url: String(url),
                        startedAt: 0,
                        requestHeaders: {}
                    };
                    return originalOpen.apply(this, arguments);
                };
                const originalSetRequestHeader = XMLHttpRequest.prototype.setRequestHeader;
                XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
                    if (this.__browserDebugRequest) {
                        this.__browserDebugRequest.requestHeaders[name] = value;
                    }
                    return originalSetRequestHeader.apply(this, arguments);
                };
                XMLHttpRequest.prototype.send = function() {
                    const request = this.__browserDebugRequest;
                    if (request) {
                        request.startedAt = performance.now();
                        request.startedAtLabel = new Date().toLocaleTimeString();
                        request.requestBody = bodyPreview(arguments[0]);
                        this.addEventListener('loadend', () => {
                            addRequest({
                                id: request.id,
                                type: 'xhr',
                                method: request.method,
                                url: request.url,
                                startedAt: request.startedAtLabel,
                                status: this.status || 'ERR',
                                statusText: this.statusText || '',
                                ok: this.status >= 200 && this.status < 400,
                                duration: Math.round(performance.now() - request.startedAt),
                                requestHeaders: request.requestHeaders,
                                requestBody: request.requestBody,
                                responseHeaders: { raw: this.getAllResponseHeaders() },
                                responseBody: '',
                                responseBodySkipped: true
                            });
                        });
                    }
                    return originalSend.apply(this, arguments);
                };

                window.addEventListener('error', (event) => {
                    state.logs.push({
                        level: 'error',
                        time: new Date().toLocaleTimeString(),
                        message: event.message || 'Unhandled error'
                    });
                    trimEntries(state.logs);
                    state.logVersion += 1;
                    scheduleRender();
                });

                window.addEventListener('unhandledrejection', (event) => {
                    state.logs.push({
                        level: 'error',
                        time: new Date().toLocaleTimeString(),
                        message: 'Unhandled promise rejection: ' + safeString(event.reason)
                    });
                    trimEntries(state.logs);
                    state.logVersion += 1;
                    scheduleRender();
                });
            }

            function ensureDrawer() {
                let root = document.getElementById('browser-debug-drawer');
                if (root) return root;

                const style = document.createElement('style');
                style.id = 'browser-debug-style';
                style.textContent = `
                    #browser-debug-drawer {
                        --browser-debug-font: "LilexNFM-Regular", "Lilex Nerd Font Mono", "Lilex Nerd Font", ui-monospace, "SF Mono", Menlo, Consolas, monospace;
                        position: fixed;
                        left: 50%;
                        top: 50%;
                        width: min(96vw, 1180px);
                        height: min(calc(100vh - 48px), 820px);
                        z-index: 2147483647;
                        display: grid;
                        grid-template-rows: auto 1fr;
                        transform: translate(-50%, -50%);
                        background: #000000;
                        color: #ffffff;
                        border: 1px solid rgba(255,255,255,0.18);
                        border-radius: 10px;
                        box-shadow: none;
                        overflow: hidden;
                        font: 14px var(--browser-debug-font);
                    }
                    #browser-debug-drawer[hidden] { display: none !important; }
                    #browser-debug-drawer:focus { outline: none; }
                    #browser-debug-drawer * { box-sizing: border-box; }
                    .browser-debug-bar {
                        display: flex;
                        align-items: center;
                        gap: 10px;
                        min-height: 72px;
                        padding: 0 24px;
                        border-bottom: 1px solid rgba(255,255,255,0.08);
                    }
                    .browser-debug-title {
                        font-size: 28px;
                        font-weight: 400;
                        color: #ffffff;
                        margin-right: 8px;
                        line-height: 1;
                    }
                    .browser-debug-tab, .browser-debug-action {
                        appearance: none;
                        border: 0;
                        background: rgba(255,255,255,0.1);
                        color: rgba(255,255,255,0.82);
                        border-radius: 8px;
                        min-height: 36px;
                        padding: 0 14px;
                        font: inherit;
                    }
                    .browser-debug-action {
                        background: transparent;
                        color: rgba(255,255,255,0.72);
                    }
                    .browser-debug-tab:hover, .browser-debug-action:hover {
                        background: rgba(255,255,255,0.14);
                        color: #ffffff;
                    }
                    .browser-debug-tab[aria-selected="true"] {
                        color: #000000;
                        background: #ffffff;
                    }
                    .browser-debug-spacer { flex: 1; }
                    .browser-debug-body {
                        min-height: 0;
                        overflow: auto;
                        overscroll-behavior: contain;
                    }
                    .browser-debug-body-network {
                        min-height: 0;
                        overflow: hidden;
                    }
                    .browser-debug-empty {
                        color: rgba(255,255,255,0.6);
                        padding: 18px;
                    }
                    .browser-debug-row {
                        display: grid;
                        grid-template-columns: 96px 1fr;
                        gap: 16px;
                        padding: 0 22px;
                        min-height: 60px;
                        align-items: center;
                        border-bottom: 1px solid rgba(255,255,255,0.08);
                        white-space: pre-wrap;
                        overflow-wrap: anywhere;
                    }
                    .browser-debug-meta { color: rgba(255,255,255,0.6); }
                    .browser-debug-log-error { color: #ff9b9b; }
                    .browser-debug-log-warn { color: #ffd98a; }
                    .browser-debug-log-info { color: #9fd0ff; }
                    .browser-debug-request {
                        grid-template-columns: 14px 52px 48px 62px minmax(0, 1fr);
                        align-items: center;
                        gap: 10px;
                    }
                    .browser-debug-network-row {
                        box-sizing: border-box;
                        min-height: 0;
                        height: 48px;
                        font-size: 15px;
                        padding: 7px 12px 3px;
                    }
                    .browser-debug-network-route {
                        display: block;
                        min-width: 0;
                        line-height: 1.35;
                        overflow: hidden;
                        text-overflow: ellipsis;
                        white-space: nowrap;
                    }
                    .browser-debug-network-shell {
                        display: grid;
                        grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
                        height: 100%;
                        min-height: 100%;
                    }
                    .browser-debug-network-list {
                        min-width: 0;
                        min-height: 0;
                        overflow: auto;
                        overscroll-behavior: contain;
                        border-right: 1px solid rgba(255,255,255,0.1);
                        padding: 4px 0;
                    }
                    .browser-debug-network-item {
                        display: block;
                        width: calc(100% - 12px);
                        height: 48px;
                        margin: 0 6px;
                        border: 0;
                        background: transparent;
                        color: #ffffff;
                        border-radius: 6px;
                        font: inherit;
                        text-align: left;
                        cursor: default;
                        overflow: hidden;
                    }
                    .browser-debug-network-item + .browser-debug-network-item {
                        margin-top: 2px;
                    }
                    .browser-debug-network-item[aria-selected="true"] {
                        background: transparent;
                        color: #ffffff;
                    }
                    .browser-debug-method {
                        font: inherit;
                        font-weight: 400;
                    }
                    .browser-debug-selected-marker {
                        display: block;
                        color: #ffffff;
                        font-size: 18px;
                        padding-top: 0;
                        padding-bottom: 1px;
                        font-family: inherit;
                        font-weight: 400;
                        line-height: 1;
                    }
                    .browser-debug-network-item:hover {
                        background: rgba(255,255,255,0.08);
                    }
                    .browser-debug-network-details {
                        min-width: 0;
                        min-height: 0;
                        overflow: auto;
                        overscroll-behavior: contain;
                        padding: 10px 12px;
                    }
                    .browser-debug-network-title {
                        margin: 0 0 10px;
                        color: #ffffff;
                        font-size: 16px;
                        font-weight: 400;
                        overflow-wrap: anywhere;
                    }
                    .browser-debug-status-ok { color: #97e6b1; }
                    .browser-debug-status-bad { color: #ff9b9b; }
                    .browser-debug-kv {
                        display: grid;
                        grid-template-columns: minmax(150px, 260px) 1fr;
                        gap: 16px;
                        padding: 16px 22px;
                        border-bottom: 1px solid rgba(255,255,255,0.08);
                        overflow-wrap: anywhere;
                    }
                    .browser-debug-kv strong {
                        font-weight: 400;
                        color: #ffffff;
                    }
                    .browser-debug-source {
                        margin: 0;
                        padding: 12px;
                        min-height: 100%;
                        color: rgba(255,255,255,0.82);
                        background: transparent;
                        font: 13px var(--browser-debug-font);
                        line-height: 1.5;
                        tab-size: 2;
                        white-space: pre-wrap;
                        overflow-wrap: anywhere;
                    }
                    .browser-debug-source-shell {
                        min-height: 100%;
                    }
                    .browser-debug-source-tree {
                        min-width: 0;
                        min-height: 100%;
                        overflow: auto;
                        padding: 8px 0;
                        font: 13px var(--browser-debug-font);
                    }
                    .browser-debug-node {
                        display: flex;
                        align-items: center;
                        width: 100%;
                        min-height: 30px;
                        padding: 2px 8px;
                        border: 0;
                        background: transparent;
                        color: rgba(255,255,255,0.82);
                        font: inherit;
                        text-align: left;
                        white-space: nowrap;
                    }
                    .browser-debug-node:hover { background: rgba(255,255,255,0.08); }
                    .browser-debug-disclosure {
                        display: inline-block;
                        width: 18px;
                        color: rgba(255,255,255,0.6);
                    }
                    .browser-debug-token-tag { color: #8fc7ff; }
                    .browser-debug-token-attr { color: #ffd98a; }
                    .browser-debug-token-value { color: #b8e994; }
                    .browser-debug-token-muted { color: #9aa4af; }
                    .browser-debug-detail-title {
                        margin: 0 0 10px;
                        font-size: 16px;
                        font-weight: 400;
                        color: #ffffff;
                    }
                    .browser-debug-detail-code {
                        margin: 0;
                        padding: 10px;
                        border-radius: 8px;
                        background: rgba(255,255,255,0.1);
                        font: 13px var(--browser-debug-font);
                        line-height: 1.5;
                        white-space: pre-wrap;
                        overflow-wrap: anywhere;
                    }
                    @media (max-width: 720px) {
                        #browser-debug-drawer { width: 96vw; height: calc(100vh - 32px); }
                        .browser-debug-bar { overflow-x: auto; }
                        .browser-debug-row, .browser-debug-request, .browser-debug-kv { grid-template-columns: 1fr; gap: 4px; }
                        .browser-debug-network-row, .browser-debug-network-item { height: 76px; }
                        .browser-debug-network-shell { grid-template-columns: 1fr; }
                        .browser-debug-network-list { border-right: 0; border-bottom: 1px solid rgba(255,255,255,0.1); max-height: 50%; }
                        .browser-debug-source-tree { max-height: none; }
                    }
                `;
                document.head.appendChild(style);

                root = document.createElement('section');
                root.id = 'browser-debug-drawer';
                root.setAttribute('role', 'dialog');
                root.setAttribute('aria-label', 'Browser debug tools');
                root.tabIndex = -1;
                (document.body || document.documentElement).appendChild(root);
                return root;
            }

            const renderRows = (items, emptyText, rowRenderer) => {
                if (!items.length) return `<div class="browser-debug-empty">${emptyText}</div>`;
                return items.slice().reverse().map(rowRenderer).join('');
            };

            const consoleRows = () => cachedValue('consoleRows', `${state.logVersion}:${state.logs.length}`, () => (
                renderRows(state.logs, 'No console messages captured yet.', (entry) => `
                    <div class="browser-debug-row browser-debug-log-${escapeHTML(entry.level)}">
                        <span class="browser-debug-meta">${escapeHTML(entry.time)} ${escapeHTML(entry.level)}</span>
                        <span>${escapeHTML(entry.message)}</span>
                    </div>
                `)
            ));

            const escapeHTML = (value) => String(value).replace(/[&<>"']/g, (char) => ({
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#39;'
            })[char]);

            const storageRows = () => {
                const key = `${location.href}:${localStorage.length}:${sessionStorage.length}:${document.cookie.length}:${innerWidth}x${innerHeight}:${devicePixelRatio}`;
                return cachedValueFor('storageRows', key, () => {
                    const rows = [];
                    const maxStorageItemsPerArea = 80;
                    const maxStorageValueLength = 500;
                    const storagePreview = (value) => {
                        const text = value == null ? '' : String(value);
                        const suffix = text.length > maxStorageValueLength ? ` ... (${text.length} chars total)` : '';
                        return text.slice(0, maxStorageValueLength) + suffix;
                    };
                    const appendStorageArea = (label, storage) => {
                        const count = storage.length;
                        rows.push([`${label} keys`, count]);
                        const visibleCount = Math.min(count, maxStorageItemsPerArea);
                        for (let index = 0; index < visibleCount; index += 1) {
                            const itemKey = storage.key(index);
                            rows.push([`${label}.${itemKey}`, storagePreview(storage.getItem(itemKey))]);
                        }
                        if (count > visibleCount) {
                            rows.push([`${label} omitted`, `${count - visibleCount} additional keys hidden for performance.`]);
                        }
                    };
                    try {
                        rows.push(['URL', location.href]);
                        rows.push(['User agent', navigator.userAgent]);
                        rows.push(['Viewport', `${innerWidth} x ${innerHeight}`]);
                        rows.push(['Device pixel ratio', devicePixelRatio]);
                        rows.push(['Cookies', document.cookie ? document.cookie.split(';').length : 0]);
                        appendStorageArea('localStorage', localStorage);
                        appendStorageArea('sessionStorage', sessionStorage);
                    } catch (error) {
                        rows.push(['Storage error', safeString(error)]);
                    }
                    return rows.map(([key, value]) => `<div class="browser-debug-kv"><strong>${escapeHTML(key)}</strong><span>${escapeHTML(value)}</span></div>`).join('');
                });
            };

            const objectRows = (object, emptyText = 'None captured.') => {
                const entries = Object.entries(object || {});
                if (!entries.length) return `<div class="browser-debug-empty">${emptyText}</div>`;
                return entries.map(([key, value]) => (
                    `<div class="browser-debug-kv"><strong>${escapeHTML(key)}</strong><span>${escapeHTML(value)}</span></div>`
                )).join('');
            };

            const networkDetails = (entry) => {
                if (!entry) return '<div class="browser-debug-empty">Select a request.</div>';
                return cachedValue(`networkDetails:${entry.id}`, `${state.requestVersion}:${entry.id}:${entry.responseBody ? entry.responseBody.length : 0}`, () => `
                        <h3 class="browser-debug-network-title">${escapeHTML(entry.method)} ${escapeHTML(entry.url)}</h3>
                        <div class="browser-debug-kv"><strong>Status</strong><span class="${entry.ok ? 'browser-debug-status-ok' : 'browser-debug-status-bad'}">${escapeHTML(entry.status)} ${escapeHTML(entry.statusText || '')}</span></div>
                        <div class="browser-debug-kv"><strong>Type</strong><span>${escapeHTML(entry.type || 'request')}</span></div>
                        <div class="browser-debug-kv"><strong>Started</strong><span>${escapeHTML(entry.startedAt || '')}</span></div>
                        <div class="browser-debug-kv"><strong>Duration</strong><span>${escapeHTML(entry.duration)} ms</span></div>
                        ${entry.error ? `<div class="browser-debug-kv"><strong>Error</strong><span>${escapeHTML(entry.error)}</span></div>` : ''}
                        <h3 class="browser-debug-network-title">Request Headers</h3>
                        ${objectRows(entry.requestHeaders)}
                        <h3 class="browser-debug-network-title">Request Body</h3>
                        ${entry.requestBody ? `<pre class="browser-debug-detail-code">${escapeHTML(entry.requestBody)}</pre>` : '<div class="browser-debug-empty">None captured.</div>'}
                        <h3 class="browser-debug-network-title">Response Headers</h3>
                        ${objectRows(entry.responseHeaders)}
                        <h3 class="browser-debug-network-title">Response Body</h3>
                        ${entry.responseBody ? `<pre class="browser-debug-detail-code">${escapeHTML(entry.responseBody)}</pre>` : `<div class="browser-debug-empty">${entry.responseBodySkipped ? 'Response body capture disabled for performance.' : 'None captured yet.'}</div>`}
                    `);
            };

            const networkPanel = () => {
                if (!state.requests.length) return '<div class="browser-debug-empty">No fetch or XHR requests captured yet.</div>';
                if (!state.requests.some((entry) => entry.id === state.selectedRequestID)) {
                    state.selectedRequestID = state.requests[state.requests.length - 1].id;
                }
                const selected = state.requests.find((entry) => entry.id === state.selectedRequestID);

                return `
                    <div class="browser-debug-network-shell">
                        <div class="browser-debug-network-list">${networkRows()}</div>
                        <div class="browser-debug-network-details">${networkDetails(selected)}</div>
                    </div>
                `;
            };

            const networkRows = () => cachedValue('networkRows', `${state.requestVersion}:${state.selectedRequestID}:${state.requests.length}`, () => (
                state.requests.slice().reverse().map((entry) => `
                    <button class="browser-debug-network-item" data-request-id="${escapeHTML(entry.id)}" aria-selected="${entry.id === state.selectedRequestID}">
                        <div class="browser-debug-row browser-debug-request browser-debug-network-row">
                            <span class="browser-debug-selected-marker">${entry.id === state.selectedRequestID ? '*' : ''}</span>
                            <strong class="browser-debug-method">${escapeHTML(entry.method)}</strong>
                            <span class="${entry.ok ? 'browser-debug-status-ok' : 'browser-debug-status-bad'}">${escapeHTML(entry.status)}</span>
                            <span class="browser-debug-meta">${escapeHTML(entry.duration)} ms</span>
                            <span class="browser-debug-network-route">${escapeHTML(entry.url)}${entry.error ? `<br>${escapeHTML(entry.error)}` : ''}</span>
                        </div>
                    </button>
                `).join('')
            ));

            const selectNetworkRequest = (requestID, resetDetailsScroll = true) => {
                state.selectedRequestID = Number(requestID);
                if (resetDetailsScroll) state.networkDetailsScrollTop = 0;
                window.__browserDebugRenderNetwork ? window.__browserDebugRenderNetwork(state.selectedRequestID, resetDetailsScroll) : window.__browserDebugRender();
                requestAnimationFrame(() => {
                    const root = document.getElementById('browser-debug-drawer');
                    const selectedButton = root && root.querySelector(`[data-request-id="${state.selectedRequestID}"]`);
                    root && root.focus();
                    selectedButton && selectedButton.scrollIntoView({ block: 'nearest' });
                });
            };

            const moveNetworkSelection = (delta) => {
                if (state.selectedTab !== 'network' || !state.requests.length) return false;
                const visibleRequests = state.requests.slice().reverse();
                let currentIndex = visibleRequests.findIndex((entry) => entry.id === state.selectedRequestID);
                if (currentIndex === -1) currentIndex = 0;
                const nextIndex = Math.max(0, Math.min(visibleRequests.length - 1, currentIndex + delta));
                if (nextIndex === currentIndex) return true;
                selectNetworkRequest(visibleRequests[nextIndex].id);
                return true;
            };

            const bindNetworkRequestEvents = (root) => {
                root.querySelectorAll('[data-request-id]').forEach((button) => {
                    button.addEventListener('click', () => {
                        selectNetworkRequest(button.dataset.requestId);
                    });
                });
            };

            const inspectableChildren = (node) => {
                if (!node || !node.childNodes) return [];
                if (node.nodeType === Node.ELEMENT_NODE && ['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEMPLATE'].includes(node.tagName)) return [];

                const children = [];
                for (const child of node.childNodes) {
                    if (child.nodeType === Node.ELEMENT_NODE) {
                        if (child.id === 'browser-debug-drawer' || child.id === 'browser-debug-style') continue;
                        children.push(child);
                    } else if (child.nodeType === Node.COMMENT_NODE) {
                        children.push(child);
                    } else if (child.nodeType === Node.TEXT_NODE && (child.textContent || '').trim()) {
                        children.push(child);
                    }
                    if (children.length >= 200) break;
                }
                return children;
            };

            const sourceRootNode = () => document.body || document.documentElement;

            const nodeForID = (id) => {
                if (id === '0') return sourceRootNode();

                let node = sourceRootNode();
                const parts = String(id).split('.').slice(1);
                for (const part of parts) {
                    const index = Number(part);
                    if (!Number.isInteger(index) || index < 0) return null;
                    const children = inspectableChildren(node);
                    node = children[index];
                    if (!node) return null;
                }
                return node;
            };

            const nodeLabel = (node) => {
                if (!node) return '';
                if (node.nodeType === Node.TEXT_NODE) {
                    const text = (node.textContent || '').replace(/\\s+/g, ' ').trim();
                    return text ? `"${escapeHTML(text.slice(0, 100))}"` : '#text';
                }
                if (node.nodeType === Node.COMMENT_NODE) {
                    return `&lt;!-- ${escapeHTML((node.textContent || '').trim().slice(0, 100))} --&gt;`;
                }
                if (node.nodeType !== Node.ELEMENT_NODE) return escapeHTML(node.nodeName.toLowerCase());

                const attrs = Array.from(node.attributes).slice(0, 4).map((attr) => (
                    ` <span class="browser-debug-token-attr">${escapeHTML(attr.name)}</span>=<span class="browser-debug-token-value">"${escapeHTML(attr.value)}"</span>`
                )).join('');
                const extra = node.attributes.length > 4 ? ' <span class="browser-debug-token-muted">...</span>' : '';
                return `<span class="browser-debug-token-muted">&lt;</span><span class="browser-debug-token-tag">${escapeHTML(node.tagName.toLowerCase())}</span>${attrs}${extra}<span class="browser-debug-token-muted">&gt;</span>`;
            };

            const sourceTreeRows = (node, id, depth, budget) => {
                if (budget.count >= state.sourceNodeLimit) {
                    budget.limitReached = true;
                    return '';
                }
                if (![Node.ELEMENT_NODE, Node.TEXT_NODE, Node.COMMENT_NODE].includes(node.nodeType)) return '';
                if (node.nodeType === Node.TEXT_NODE && !(node.textContent || '').trim()) return '';

                budget.count += 1;
                const children = inspectableChildren(node);
                const isExpanded = state.expandedNodeIDs.includes(id);
                const hasChildren = children.length > 0;
                let html = `
                    <button class="browser-debug-node" data-node-id="${escapeHTML(id)}" style="padding-left: ${8 + depth * 14}px">
                        <span class="browser-debug-disclosure">${hasChildren ? (isExpanded ? '&#9662;' : '&#9656;') : ''}</span>
                        <span>${nodeLabel(node)}</span>
                    </button>
                `;
                if (hasChildren && isExpanded) {
                    html += children.map((child, index) => sourceTreeRows(child, `${id}.${index}`, depth + 1, budget)).join('');
                }
                return html;
            };

            const sourcePanel = () => {
                const sourceKey = `${state.sourceVersion}:${state.sourceMode}:${state.expandedNodeIDs.join(',')}:${location.href}`;
                return cachedValue('sourcePanel', sourceKey, () => {
                if (state.sourceMode === 'raw') {
                    const doctype = document.doctype
                        ? `<!DOCTYPE ${document.doctype.name}${document.doctype.publicId ? ` PUBLIC "${document.doctype.publicId}"` : ''}${document.doctype.systemId ? ` "${document.doctype.systemId}"` : ''}>\\n`
                        : '';
                    const html = doctype + document.documentElement.outerHTML;
                    const limit = 200000;
                    const truncated = html.length > limit;
                    return `<pre class="browser-debug-source">${escapeHTML(html.slice(0, limit))}${truncated ? `\\n\\n&lt;!-- Raw source truncated at ${limit} characters for performance. --&gt;` : ''}</pre>`;
                }

                state.expandedNodeIDs = state.expandedNodeIDs.filter((id) => !!nodeForID(id));
                if (!state.expandedNodeIDs.includes('0')) state.expandedNodeIDs.unshift('0');
                if (!nodeForID(state.selectedNodeID)) state.selectedNodeID = '0';
                const budget = { count: 0, limitReached: false };

                return `
                    <div class="browser-debug-source-shell">
                        <div class="browser-debug-source-tree">
                            ${sourceTreeRows(sourceRootNode(), '0', 0, budget)}
                            ${budget.limitReached ? `<div class="browser-debug-empty">Showing first ${escapeHTML(state.sourceNodeLimit)} visible nodes. Expand fewer branches to inspect deeper nodes.</div>` : ''}
                        </div>
                    </div>
                `;
                });
            };

            const environmentRows = () => cachedValueFor('environmentRows', `${location.href}:${document.title}:${document.readyState}:${navigator.onLine}:${innerWidth}x${innerHeight}`, () => (
                [
                    ['Location', location.href],
                    ['Title', document.title || '(untitled)'],
                    ['Ready state', document.readyState],
                    ['Language', navigator.language],
                    ['Online', navigator.onLine],
                    ['Platform', navigator.platform],
                    ['Screen', `${screen.width} x ${screen.height}`],
                    ['Timezone', Intl.DateTimeFormat().resolvedOptions().timeZone || 'unknown']
                ].map(([key, value]) => `<div class="browser-debug-kv"><strong>${escapeHTML(key)}</strong><span>${escapeHTML(value)}</span></div>`).join('')
            ));

            window.__browserDebugRenderNetwork = (changedRequestID = null, forceDetails = false) => {
                const root = document.getElementById('browser-debug-drawer');
                if (!root || root.hidden || state.selectedTab !== 'network') {
                    window.__browserDebugRender && window.__browserDebugRender();
                    return;
                }

                const tab = root.querySelector('[data-tab="network"]');
                if (tab) tab.textContent = `Network (${state.requests.length})`;

                const list = root.querySelector('.browser-debug-network-list');
                const details = root.querySelector('.browser-debug-network-details');
                if (!list || !details) {
                    window.__browserDebugRender && window.__browserDebugRender();
                    return;
                }

                if (!state.requests.length) {
                    window.__browserDebugRender && window.__browserDebugRender();
                    return;
                }

                if (!state.requests.some((entry) => entry.id === state.selectedRequestID)) {
                    state.selectedRequestID = state.requests[state.requests.length - 1].id;
                    forceDetails = true;
                }

                const previousListScrollTop = list.scrollTop;
                const previousListScrollHeight = list.scrollHeight;
                const wasListAtTop = previousListScrollTop <= 2;
                const previousDetailsScrollTop = details.scrollTop;
                const selectedBefore = details.dataset.requestId ? Number(details.dataset.requestId) : null;
                const selected = state.requests.find((entry) => entry.id === state.selectedRequestID);

                const nextRows = networkRows();
                if (list.__browserDebugHTML !== nextRows) {
                    list.__browserDebugHTML = nextRows;
                    list.innerHTML = nextRows;
                    bindNetworkRequestEvents(list);
                }
                list.scrollTop = wasListAtTop ? 0 : previousListScrollTop + Math.max(0, list.scrollHeight - previousListScrollHeight);
                state.networkListScrollTop = list.scrollTop;

                if (forceDetails || selectedBefore !== state.selectedRequestID || changedRequestID === state.selectedRequestID) {
                    const nextDetails = networkDetails(selected);
                    if (details.__browserDebugHTML !== nextDetails) {
                        details.__browserDebugHTML = nextDetails;
                        details.innerHTML = nextDetails;
                    }
                    details.dataset.requestId = String(state.selectedRequestID);
                    details.scrollTop = forceDetails ? state.networkDetailsScrollTop : previousDetailsScrollTop;
                    state.networkDetailsScrollTop = details.scrollTop;
                }
            };

            window.__browserDebugRender = () => {
                const root = ensureDrawer();
                const previousNetworkList = root.querySelector('.browser-debug-network-list');
                const previousNetworkDetails = root.querySelector('.browser-debug-network-details');
                const previousSourceBody = state.selectedTab === 'sources' ? root.querySelector('.browser-debug-body') : null;
                const previousSourceTree = root.querySelector('.browser-debug-source-tree');
                if (previousNetworkList) state.networkListScrollTop = previousNetworkList.scrollTop;
                if (previousNetworkDetails) state.networkDetailsScrollTop = previousNetworkDetails.scrollTop;
                if (previousSourceBody) state.sourceBodyScrollTop = previousSourceBody.scrollTop;
                if (previousSourceTree) state.sourceTreeScrollTop = previousSourceTree.scrollTop;

                const tabs = [
                    ['console', `Console (${state.logs.length})`],
                    ['network', `Network (${state.requests.length})`],
                    ['sources', 'Sources'],
                    ['storage', 'Storage'],
                    ['environment', 'Environment']
                ];

                let body = '';
                if (state.selectedTab === 'console') {
                    body = consoleRows();
                } else if (state.selectedTab === 'network') {
                    body = networkPanel();
                } else if (state.selectedTab === 'sources') {
                    body = sourcePanel();
                } else if (state.selectedTab === 'storage') {
                    body = storageRows();
                } else {
                    body = environmentRows();
                }

                const nextHTML = `
                    <div class="browser-debug-bar">
                        <span class="browser-debug-title">Debug</span>
                        ${tabs.map(([id, label]) => `<button class="browser-debug-tab" data-tab="${id}" aria-selected="${state.selectedTab === id}">${escapeHTML(label)}</button>`).join('')}
                        <span class="browser-debug-spacer"></span>
                        ${state.selectedTab === 'sources' ? `<button class="browser-debug-action" data-action="source-mode">${state.sourceMode === 'tree' ? 'Raw' : 'Tree'}</button>` : ''}
                        <button class="browser-debug-action" data-action="clear">${state.selectedTab === 'sources' ? 'Refresh' : 'Clear'}</button>
                        <button class="browser-debug-action" data-action="close">Close</button>
                    </div>
                    <div class="browser-debug-body ${state.selectedTab === 'network' ? 'browser-debug-body-network' : ''}">${body}</div>
                `;
                if (root.__browserDebugHTML === nextHTML) return;
                root.__browserDebugHTML = nextHTML;
                root.innerHTML = nextHTML;

                root.querySelectorAll('[data-tab]').forEach((button) => {
                    button.addEventListener('click', () => {
                        state.selectedTab = button.dataset.tab;
                        window.__browserDebugRender();
                        requestAnimationFrame(() => {
                            const root = document.getElementById('browser-debug-drawer');
                            root && root.focus();
                        });
                    });
                });
                const focusDebugRoot = () => {
                    requestAnimationFrame(() => {
                        const root = document.getElementById('browser-debug-drawer');
                        root && root.focus();
                    });
                };
                const scrollDebugBody = (delta) => {
                    const body = root.querySelector('.browser-debug-body');
                    if (!body) return;
                    body.scrollTop += delta * 56;
                    if (state.selectedTab === 'sources') state.sourceBodyScrollTop = body.scrollTop;
                };
                const moveDebugTab = (delta) => {
                    const tabIDs = tabs.map(([id]) => id);
                    const currentIndex = Math.max(0, tabIDs.indexOf(state.selectedTab));
                    const nextIndex = (currentIndex + delta + tabIDs.length) % tabIDs.length;
                    state.selectedTab = tabIDs[nextIndex];
                    window.__browserDebugRender();
                    focusDebugRoot();
                };
                root.onkeydown = (event) => {
                    if (event.key === 'h' || event.key === 'ArrowLeft') {
                        event.preventDefault();
                        moveDebugTab(-1);
                    } else if (event.key === 'l' || event.key === 'ArrowRight') {
                        event.preventDefault();
                        moveDebugTab(1);
                    } else if (event.key === 'j' || event.key === 'ArrowDown') {
                        event.preventDefault();
                        if (state.selectedTab !== 'network' || !moveNetworkSelection(1)) {
                            scrollDebugBody(1);
                            focusDebugRoot();
                        }
                    } else if (event.key === 'k' || event.key === 'ArrowUp') {
                        event.preventDefault();
                        if (state.selectedTab !== 'network' || !moveNetworkSelection(-1)) {
                            scrollDebugBody(-1);
                            focusDebugRoot();
                        }
                    }
                };
                root.querySelector('[data-action="clear"]').addEventListener('click', () => {
                    if (state.selectedTab === 'console') {
                        state.logs.length = 0;
                        state.logVersion += 1;
                    }
                    if (state.selectedTab === 'network') {
                        state.requests.length = 0;
                        state.selectedRequestID = null;
                        state.requestVersion += 1;
                    }
                    if (state.selectedTab === 'sources') {
                        state.sourceVersion += 1;
                    }
                    window.__browserDebugRender();
                    focusDebugRoot();
                });
                root.querySelector('[data-action="source-mode"]')?.addEventListener('click', () => {
                    state.sourceMode = state.sourceMode === 'tree' ? 'raw' : 'tree';
                    state.sourceVersion += 1;
                    window.__browserDebugRender();
                    focusDebugRoot();
                });
                root.querySelectorAll('[data-node-id]').forEach((button) => {
                    button.addEventListener('click', (event) => {
                        event.preventDefault();
                        const sourceBody = root.querySelector('.browser-debug-body');
                        const sourceTree = root.querySelector('.browser-debug-source-tree');
                        if (sourceBody) state.sourceBodyScrollTop = sourceBody.scrollTop;
                        if (sourceTree) state.sourceTreeScrollTop = sourceTree.scrollTop;
                        const id = button.dataset.nodeId;
                        if (state.expandedNodeIDs.includes(id)) {
                            state.expandedNodeIDs = state.expandedNodeIDs.filter((item) => item !== id);
                        } else {
                            state.expandedNodeIDs.push(id);
                        }
                        state.sourceVersion += 1;
                        window.__browserDebugRender();
                    });
                });
                const networkList = root.querySelector('.browser-debug-network-list');
                const networkDetails = root.querySelector('.browser-debug-network-details');
                const sourceBody = state.selectedTab === 'sources' ? root.querySelector('.browser-debug-body') : null;
                const sourceTree = root.querySelector('.browser-debug-source-tree');
                bindNetworkRequestEvents(root);
                if (networkList) {
                    networkList.scrollTop = state.networkListScrollTop;
                    requestAnimationFrame(() => {
                        networkList.scrollTop = state.networkListScrollTop;
                    });
                    networkList.addEventListener('scroll', () => {
                        state.networkListScrollTop = networkList.scrollTop;
                    });
                }
                if (networkDetails) {
                    networkDetails.dataset.requestId = String(state.selectedRequestID);
                    networkDetails.scrollTop = state.networkDetailsScrollTop;
                    requestAnimationFrame(() => {
                        networkDetails.scrollTop = state.networkDetailsScrollTop;
                    });
                    networkDetails.addEventListener('scroll', () => {
                        state.networkDetailsScrollTop = networkDetails.scrollTop;
                    });
                }
                if (sourceTree) {
                    sourceTree.scrollTop = state.sourceTreeScrollTop;
                    requestAnimationFrame(() => {
                        sourceTree.scrollTop = state.sourceTreeScrollTop;
                    });
                    sourceTree.addEventListener('scroll', () => {
                        state.sourceTreeScrollTop = sourceTree.scrollTop;
                    });
                }
                if (sourceBody) {
                    sourceBody.scrollTop = state.sourceBodyScrollTop;
                    requestAnimationFrame(() => {
                        sourceBody.scrollTop = state.sourceBodyScrollTop;
                    });
                    sourceBody.addEventListener('scroll', () => {
                        state.sourceBodyScrollTop = sourceBody.scrollTop;
                    });
                }
                root.querySelector('[data-action="close"]').addEventListener('click', () => {
                    state.visible = false;
                    root.hidden = true;
                });
            };

            const drawer = ensureDrawer();
            state.visible = !state.visible;
            drawer.hidden = !state.visible;
            if (state.visible) {
                window.__browserDebugRender();
                requestAnimationFrame(() => drawer.focus());
            }
            return state.visible;
        })();
        """) { result, error in
            if error != nil {
                completion?(false)
                return
            }
            completion?(result as? Bool ?? false)
        }
    }

    func hideErudaDeveloperTools() {
        webView?.evaluateJavaScript("""
        (() => {
            const state = window.__browserDebugState;
            const drawer = document.getElementById('browser-debug-drawer');
            if (state) state.visible = false;
            if (drawer) drawer.hidden = true;
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
