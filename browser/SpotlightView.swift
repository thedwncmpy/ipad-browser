//
//  SpotlightView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct SpotlightView: View {
    private enum Style {
        static let fieldWidth: CGFloat = 620
        static let fieldHeight: CGFloat = 72
        static let suggestionRowHeight: CGFloat = 52
        static let cornerRadius: CGFloat = 18
        static let horizontalPadding: CGFloat = 24
        static let fontSize: CGFloat = 24
        static let fontName = "LilexNFM-Regular"
        static let backgroundColor = Color.black.opacity(0.82)
        static let borderColor = Color.white.opacity(0.18)
        static let textColor = Color.white
    }

    struct Suggestion: Identifiable {
        let id: String
        let title: String
        let subtitle: String?
        let isSelected: Bool
        let action: () -> Void
    }

    @Binding var text: String
    var isVisible = true
    var placeholder = ""
    var trailingText: String? = nil
    var pageURL: URL? = nil
    var showsFavicon = false
    var showsFaviconPlaceholder = true
    var focusRequestID: Int? = nil
    var suggestions: [Suggestion] = []
    var onTextChange: ((String) -> Void)? = nil
    var onSidebarShortcut: (() -> Void)? = nil
    var onFindShortcut: (() -> Void)? = nil
    var onSpotlightShortcut: (() -> Void)? = nil
    var onCommandPaletteShortcut: (() -> Void)? = nil
    var onNextSuggestionShortcut: (() -> Void)? = nil
    var onPreviousSuggestionShortcut: (() -> Void)? = nil
    let onSubmit: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        if showsFavicon {
                            FaviconView(pageURL: pageURL, typedText: text, showsPlaceholder: showsFaviconPlaceholder)
                        }

                        OverlayShortcutTextField(
                            text: $text,
                            placeholder: placeholder,
                            fontName: Style.fontName,
                            fontSize: Style.fontSize,
                            textColor: .white,
                            focusRequestID: focusRequestID,
                            onSubmit: onSubmit,
                            onTextChange: onTextChange,
                            onShortcut: handleShortcut
                        )

                        if let trailingText {
                            Text(trailingText)
                                .font(.custom(Style.fontName, size: 18))
                                .foregroundStyle(Color.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, Style.horizontalPadding)
                    .frame(height: Style.fieldHeight)

                    if !suggestions.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(suggestions) { suggestion in
                                Button(action: suggestion.action) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(suggestion.title)
                                                .font(.custom(Style.fontName, size: 16))
                                                .foregroundStyle(suggestion.isSelected ? Color.black : Color.white)
                                                .lineLimit(1)

                                            if let subtitle = suggestion.subtitle {
                                                Text(subtitle)
                                                    .font(.custom(Style.fontName, size: 12))
                                                    .foregroundStyle(suggestion.isSelected ? Color.black.opacity(0.72) : Color.white.opacity(0.6))
                                                    .lineLimit(1)
                                            }
                                        }

                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 18)
                                    .frame(height: Style.suggestionRowHeight, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .background(suggestion.isSelected ? Color.white : Color.clear)

                                if suggestion.id != suggestions.last?.id {
                                    Divider()
                                        .overlay(Color.white.opacity(0.08))
                                }
                            }
                        }
                    }
                }
                .frame(width: Style.fieldWidth)
                .background(Style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                        .stroke(Style.borderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous))
            }
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height * 0.25
            )
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .ignoresSafeArea()
    }

    private func handleShortcut(_ action: OverlayShortcutTextField.ShortcutAction) {
        switch action {
        case .sidebar:
            onSidebarShortcut?()
        case .spotlight:
            onSpotlightShortcut?()
        case .commandPalette:
            onCommandPaletteShortcut?()
        case .find:
            onFindShortcut?()
        case .nextOption:
            onNextSuggestionShortcut?()
        case .previousOption:
            onPreviousSuggestionShortcut?()
        case .dismiss:
            onDismiss()
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        SpotlightView(
            text: .constant("https://www.reddit.com"),
            onSubmit: {},
            onDismiss: {}
        )
    }
}
