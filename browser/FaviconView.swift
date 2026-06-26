//
//  FaviconView.swift
//  browser
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class FaviconStore: ObservableObject {
    static let shared = FaviconStore()

    @Published private(set) var images: [URL: UIImage] = [:]

    private let cache = NSCache<NSURL, UIImage>()
    private var inFlightURLs: Set<URL> = []

    func image(for url: URL) -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            if images[url] == nil {
                images[url] = cached
            }
            return cached
        }

        return images[url]
    }

    func load(_ url: URL) {
        if image(for: url) != nil || inFlightURLs.contains(url) {
            return
        }

        inFlightURLs.insert(url)

        Task {
            defer {
                Task { @MainActor in
                    self.inFlightURLs.remove(url)
                }
            }

            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    200..<300 ~= httpResponse.statusCode,
                    let image = UIImage(data: data)
                else {
                    return
                }

                await MainActor.run {
                    cache.setObject(image, forKey: url as NSURL)
                    images[url] = image
                }
            } catch {
                return
            }
        }
    }
}

struct FaviconView: View {
    private enum Style {
        static let size: CGFloat = 22
        static let cornerRadius: CGFloat = 6
        static let placeholderBackground = Color.white.opacity(0.08)
        static let placeholderForeground = Color.white.opacity(0.7)
    }

    let pageURL: URL?
    let typedText: String?
    @StateObject private var store = FaviconStore.shared

    private var faviconURL: URL? {
        if let typedURL = resolvedURL(from: typedText) {
            return faviconURL(for: typedURL)
        }

        if let pageURL {
            return faviconURL(for: pageURL)
        }

        return nil
    }

    var body: some View {
        Group {
            if let faviconURL, let image = store.image(for: faviconURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if faviconURL != nil {
                placeholder
            } else {
                placeholder
            }
        }
        .frame(width: Style.size, height: Style.size)
        .clipShape(RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous))
        .onAppear {
            if let faviconURL {
                store.load(faviconURL)
            }
        }
        .onChange(of: faviconURL) { _, newValue in
            if let newValue {
                store.load(newValue)
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
            .fill(Style.placeholderBackground)
            .overlay {
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Style.placeholderForeground)
            }
    }

    private func resolvedURL(from rawText: String?) -> URL? {
        guard let rawText else { return nil }
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let explicitURL = URL(string: trimmed), explicitURL.scheme != nil, explicitURL.host != nil {
            return explicitURL
        }

        if !trimmed.contains(" "), trimmed.contains("."), let hostURL = URL(string: "https://\(trimmed)") {
            return hostURL
        }

        return nil
    }

    private func faviconURL(for url: URL) -> URL? {
        guard let host = url.host else { return nil }
        var components = URLComponents()
        components.scheme = url.scheme ?? "https"
        components.host = host
        components.path = "/favicon.ico"
        return components.url
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FaviconView(
            pageURL: URL(string: "https://www.reddit.com/r/swift"),
            typedText: "https://www.reddit.com/r/swift"
        )
    }
}
