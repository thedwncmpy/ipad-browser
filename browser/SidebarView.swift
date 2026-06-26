//
//  SidebarView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct SidebarView: View {
    private enum Style {
        static let inset: CGFloat = 20
        static let width: CGFloat = 360
        static let cornerRadius: CGFloat = 20
        static let contentPadding: CGFloat = 18
        static let itemSpacing: CGFloat = 16
        static let fieldCornerRadius: CGFloat = 14
        static let backgroundColor = Color.black.opacity(0.82)
        static let borderColor = Color.white.opacity(0.18)
        static let fieldBackgroundColor = Color.white.opacity(0.06)
        static let titleColor = Color.white.opacity(0.55)
        static let valueColor = Color.white
        static let titleFontSize: CGFloat = 12
        static let valueFontSize: CGFloat = 15
        static let fontName = "LilexNFM-Regular"
    }

    @Binding var urlText: String
    let currentPageURL: URL
    let onSubmit: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: Style.itemSpacing) {
                HStack(spacing: 12) {
                    FaviconView(pageURL: currentPageURL, typedText: urlText)

                    TextField("https://", text: $urlText, onCommit: onSubmit)
                        .textFieldStyle(.plain)
                        .font(.custom(Style.fontName, size: Style.valueFontSize))
                        .foregroundStyle(Style.valueColor)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Style.fieldBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Style.fieldCornerRadius, style: .continuous)
                        .stroke(Style.borderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Style.fieldCornerRadius, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(Style.contentPadding)
            .frame(
                width: Style.width,
                height: geometry.size.height - (Style.inset * 2),
                alignment: .topLeading
            )
            .background(Style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous)
                    .stroke(Style.borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Style.cornerRadius, style: .continuous))
            .padding(.leading, Style.inset)
            .padding(.top, Style.inset)
        }
        .ignoresSafeArea(edges: .vertical)
    }
}

#Preview {
    SidebarView(
        urlText: .constant("https://www.reddit.com/r/swift"),
        currentPageURL: URL(string: "https://www.reddit.com/r/swift")!,
        onSubmit: {}
    )
}
