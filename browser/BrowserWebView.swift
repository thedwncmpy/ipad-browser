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

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        currentURLString = url.absoluteString
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
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

        init(currentURLString: Binding<String>) {
            _currentURLString = currentURLString
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            currentURLString = webView.url?.absoluteString ?? currentURLString
        }
    }
}

#Preview {
    BrowserWebView(
        url: .constant(URL(string: "https://www.reddit.com")!),
        currentURLString: .constant("https://www.reddit.com")
    )
}
