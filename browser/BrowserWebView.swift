//
//  BrowserWebView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI
import WebKit

struct BrowserFindStatus: Equatable {
    let current: Int
    let total: Int

    static let empty = BrowserFindStatus(current: 0, total: 0)
}

@MainActor
final class BrowserNavigationController {
    weak var webView: WKWebView?
    private(set) var lastFindQuery = ""

    func attach(webView: WKWebView) {
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
    let navigationController: BrowserNavigationController

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.attach(to: webView)
        context.coordinator.lastRequestedURL = url
        navigationController.attach(webView: webView)
        let request = URLRequest(url: url)
        webView.load(request)
        currentURLString = url.absoluteString
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.lastRequestedURL != url {
            context.coordinator.lastRequestedURL = url
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentURLString: $currentURLString)
    }
}

extension BrowserWebView {
    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding private var currentURLString: String
        var lastRequestedURL: URL?
        private var urlObservation: NSKeyValueObservation?

        init(currentURLString: Binding<String>) {
            _currentURLString = currentURLString
        }

        func attach(to webView: WKWebView) {
            urlObservation = webView.observe(\.url, options: [.initial, .new]) { [weak self] webView, _ in
                guard let self, let urlString = webView.url?.absoluteString else { return }
                self.currentURLString = urlString
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            currentURLString = webView.url?.absoluteString ?? currentURLString
        }
    }
}

#Preview {
    BrowserWebView(
        url: .constant(URL(string: "https://www.reddit.com")!),
        currentURLString: .constant("https://www.reddit.com"),
        navigationController: BrowserNavigationController()
    )
}
