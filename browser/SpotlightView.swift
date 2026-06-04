//
//  SpotlightView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct SpotlightView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onDismiss: () -> Void
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TextField("", text: $text, onCommit: onSubmit)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 20)
                    .frame(width: 620, height: 72)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button("") {
                    onDismiss()
                }
                .keyboardShortcut("l", modifiers: [.command])
                .opacity(0.001)
                .accessibilityHidden(true)

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
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
        }
        .ignoresSafeArea()
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
