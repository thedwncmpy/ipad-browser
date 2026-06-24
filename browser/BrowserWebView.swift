//
//  BrowserWebView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI
import WebKit

struct BrowserWebView: UIViewRepresentable {
    @Binding var url: URL
    @Binding var currentURLString: String
    let onToggleSidebar: () -> Void
    let onToggleSpotlight: () -> Void
    let onDismissSpotlight: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = BrowserShortcutWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.attach(to: webView)
        context.coordinator.lastRequestedURL = url
        webView.onToggleSidebar = onToggleSidebar
        webView.onToggleSpotlight = onToggleSpotlight
        webView.onDismissSpotlight = onDismissSpotlight
        let request = URLRequest(url: url)
        webView.load(request)
        currentURLString = url.absoluteString
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let webView = uiView as? BrowserShortcutWebView {
            webView.onToggleSidebar = onToggleSidebar
            webView.onToggleSpotlight = onToggleSpotlight
            webView.onDismissSpotlight = onDismissSpotlight
        }

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

final class BrowserShortcutWebView: WKWebView {
    var onToggleSidebar: (() -> Void)?
    var onToggleSpotlight: (() -> Void)?
    var onDismissSpotlight: (() -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        BrowserKeyboardCommands.makeKeyCommands(
            sidebarSelector: #selector(handleSidebarToggle),
            spotlightSelector: #selector(handleSpotlightToggle),
            dismissSelector: #selector(handleSpotlightDismiss)
        )
    }

    @objc private func handleSidebarToggle() {
        onToggleSidebar?()
    }

    @objc private func handleSpotlightToggle() {
        onToggleSpotlight?()
    }

    @objc private func handleSpotlightDismiss() {
        onDismissSpotlight?()
    }
}

#Preview {
    BrowserWebView(
        url: .constant(URL(string: "https://www.reddit.com")!),
        currentURLString: .constant("https://www.reddit.com"),
        onToggleSidebar: {},
        onToggleSpotlight: {},
        onDismissSpotlight: {}
    )
}
