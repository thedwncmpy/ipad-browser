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
        }
    }

    private var mainContent: some View {
        ZStack {
            BrowserWebView(url: $currentPageURL, currentURLString: $currentURLString)
                .ignoresSafeArea()

            KeyboardCaptureView(
                onToggleSidebar: {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSidebarVisible.toggle()
                        }
                    }
                },
                onToggleSpotlight: {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            spotlightText = currentURLString
                            isSpotlightVisible.toggle()
                        }
                    }
                },
                onDismissSpotlight: {
                    guard isSpotlightVisible else { return }

                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isSpotlightVisible = false
                        }
                    }
                }
            )
            .frame(width: 0, height: 0)
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
                    let normalized = raw.hasPrefix("http") ? raw : "https://\(raw)"

                    guard let url = URL(string: normalized) else { return }

                    currentPageURL = url
                    currentURLString = normalized
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
}

#Preview {
    ContentView()
}
