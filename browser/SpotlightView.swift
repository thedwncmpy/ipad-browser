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
        static let cornerRadius: CGFloat = 18
        static let horizontalPadding: CGFloat = 24
        static let fontSize: CGFloat = 24
        static let fontName = "LilexNFM-Regular"
        static let backgroundColor = Color.black.opacity(0.82)
        static let borderColor = Color.white.opacity(0.18)
        static let textColor = Color.white
    }

    @Binding var text: String
    var placeholder = ""
    var trailingText: String? = nil
    var onTextChange: ((String) -> Void)? = nil
    var onSidebarShortcut: (() -> Void)? = nil
    var onFindShortcut: (() -> Void)? = nil
    var onSpotlightShortcut: (() -> Void)? = nil
    let onSubmit: () -> Void
    let onDismiss: () -> Void
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 16) {
                    TextField(placeholder, text: $text, onCommit: onSubmit)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(.plain)
                        .font(.custom(Style.fontName, size: Style.fontSize))
                        .foregroundStyle(Style.textColor)
                        .onChange(of: text) { _, newValue in
                            onTextChange?(newValue)
                        }

                    if let trailingText {
                        Text(trailingText)
                            .font(.custom(Style.fontName, size: 18))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, Style.horizontalPadding)
                .frame(width: Style.fieldWidth, height: Style.fieldHeight)
                .background(Style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                        .stroke(Style.borderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous))

                if let onSpotlightShortcut {
                    Button("") {
                        onSpotlightShortcut()
                    }
                    .keyboardShortcut("l", modifiers: [.command])
                    .opacity(0.001)
                    .accessibilityHidden(true)
                }

                if let onFindShortcut {
                    Button("") {
                        onFindShortcut()
                    }
                    .keyboardShortcut("f", modifiers: [.command])
                    .opacity(0.001)
                    .accessibilityHidden(true)
                }

                if let onSidebarShortcut {
                    Button("") {
                        onSidebarShortcut()
                    }
                    .keyboardShortcut("/", modifiers: [.command])
                    .opacity(0.001)
                    .accessibilityHidden(true)
                }

                Button("") {
                    onDismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .opacity(0.001)
                .accessibilityHidden(true)

            }
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height * 0.25
            )
        }
        .onAppear {
            focusTextField()
        }
        .onChange(of: text) { _, _ in
            focusTextField()
        }
        .onChange(of: trailingText ?? "") { _, _ in
            focusTextField()
        }
        .ignoresSafeArea()
    }

    private func focusTextField() {
        DispatchQueue.main.async {
            isTextFieldFocused = true
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
