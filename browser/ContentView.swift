//
//  ContentView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = false
    @State private var isSpotlightVisible = false
    @State private var currentURLString = "https://www.reddit.com"
    @State private var spotlightText = ""
    @State private var currentPageURL = URL(string: "https://www.reddit.com")!

    var body: some View {
        ZStack(alignment: .leading) {
            mainContent
            sidebar
            spotlight
            keyboardCaptureLayer
        }
    }

    private var mainContent: some View {
        ZStack {
            BrowserWebView(
                url: $currentPageURL,
                currentURLString: $currentURLString,
                onToggleSidebar: toggleSidebar,
                onToggleSpotlight: toggleSpotlight,
                onDismissSpotlight: dismissSpotlight
            )
                .ignoresSafeArea()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var sidebar: some View {
        if isSidebarVisible {
            SidebarView()
                .transition(.move(edge: .leading))
                .zIndex(1)
        }
    }

    @ViewBuilder
    private var spotlight: some View {
        if isSpotlightVisible {
            SpotlightView(
                text: $spotlightText,
                onSubmit: {
                    let raw = spotlightText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let url = destinationURL(for: raw) else { return }

                    currentPageURL = url
                    currentURLString = url.absoluteString
                    isSpotlightVisible = false
                },
                onDismiss: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isSpotlightVisible = false
                    }
                }
            )
            .zIndex(1)
        }
    }

    private var keyboardCaptureLayer: some View {
        KeyboardCaptureView(
            onToggleSidebar: toggleSidebar,
            onToggleSpotlight: toggleSpotlight,
            onDismissSpotlight: dismissSpotlight
        )
        .frame(width: 0, height: 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func toggleSidebar() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                isSidebarVisible.toggle()
            }
        }
    }

    private func toggleSpotlight() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.1)) {
                spotlightText = currentURLString
                isSpotlightVisible.toggle()
            }
        }
    }

    private func dismissSpotlight() {
        guard isSpotlightVisible else { return }

        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.1)) {
                isSpotlightVisible = false
            }
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
}

#Preview {
    ContentView()
}
