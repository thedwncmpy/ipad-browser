//
//  SidebarView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct SidebarTabItem: Identifiable {
    let id: UUID
    let title: String
    let currentURLString: String
    let currentPageURL: URL
}

struct SidebarView: View {
    private enum Style {
        static let inset: CGFloat = 20
        static let width: CGFloat = 360
        static let cornerRadius: CGFloat = 20
        static let contentPadding: CGFloat = 18
        static let itemSpacing: CGFloat = 16
        static let fieldCornerRadius: CGFloat = 14
        static let rowCornerRadius: CGFloat = 14
        static let backgroundColor = Color.black.opacity(0.82)
        static let borderColor = Color.white.opacity(0.18)
        static let fieldBackgroundColor = Color.white.opacity(0.06)
        static let rowBackgroundColor = Color.white.opacity(0.04)
        static let activeRowBackgroundColor = Color.white.opacity(0.1)
        static let titleColor = Color.white
        static let secondaryColor = Color.white.opacity(0.55)
        static let valueColor = Color.white
        static let titleFontSize: CGFloat = 15
        static let valueFontSize: CGFloat = 15
        static let fontName = "LilexNFM-Regular"
        static let workspaceDotSize: CGFloat = 8
    }

    @Binding var urlText: String
    let currentPageURL: URL
    let tabs: [SidebarTabItem]
    let selectedTabID: UUID?
    let workspaceCount: Int
    let selectedWorkspaceIndex: Int
    let urlFieldFocusRequestID: Int?
    let onSelectTab: (UUID) -> Void
    let onCloseTab: (UUID) -> Void
    let onSidebarShortcut: (() -> Void)?
    let onSpotlightShortcut: (() -> Void)?
    let onCommandPaletteShortcut: (() -> Void)?
    let onFindShortcut: (() -> Void)?
    let onSettingsShortcut: (() -> Void)?
    let onDismiss: (() -> Void)?
    let onSubmit: () -> Void
    let shortcuts: [BrowserShortcutAction: BrowserShortcut]

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: Style.itemSpacing) {
                urlField
                tabList
                Spacer(minLength: 0)
                workspaceIndicator
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

    private var urlField: some View {
        HStack(spacing: 12) {
            FaviconView(pageURL: currentPageURL, typedText: urlText)

            OverlayShortcutTextField(
                text: $urlText,
                placeholder: "https://",
                fontName: Style.fontName,
                fontSize: Style.valueFontSize,
                textColor: .white,
                focusRequestID: urlFieldFocusRequestID,
                onSubmit: onSubmit,
                onTextChange: nil,
                onShortcut: handleShortcut,
                shortcuts: shortcuts
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Style.fieldBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: Style.fieldCornerRadius, style: .continuous)
                .stroke(Style.borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Style.fieldCornerRadius, style: .continuous))
    }

    private var tabList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(tabs) { tab in
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            onSelectTab(tab.id)
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                FaviconView(pageURL: tab.currentPageURL, typedText: tab.currentURLString)

                                Text(tab.title)
                                    .font(.custom(Style.fontName, size: Style.titleFontSize))
                                    .foregroundStyle(Style.titleColor)
                                    .lineLimit(1)

                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            onCloseTab(tab.id)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Style.secondaryColor)
                                .frame(width: 18, height: 18)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(backgroundColor(for: tab.id))
                    .clipShape(RoundedRectangle(cornerRadius: Style.rowCornerRadius, style: .continuous))
                }
            }
        }
    }

    private var workspaceIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Array(0..<workspaceCount), id: \.self) { index in
                Circle()
                    .fill(index == selectedWorkspaceIndex ? Color.white : Color.white.opacity(0.24))
                    .frame(width: Style.workspaceDotSize, height: Style.workspaceDotSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 4)
    }

    private func backgroundColor(for id: UUID) -> Color {
        selectedTabID == id ? Style.activeRowBackgroundColor : Style.rowBackgroundColor
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
        case .settings:
            onSettingsShortcut?()
        case .nextOption:
            break
        case .previousOption:
            break
        case .completeOption:
            break
        case .dismiss:
            onDismiss?()
        }
    }
}

#Preview {
    SidebarView(
        urlText: .constant("https://www.reddit.com/r/swift"),
        currentPageURL: URL(string: "https://www.reddit.com/r/swift")!,
        tabs: [
            SidebarTabItem(
                id: UUID(),
                title: "Tab 1",
                currentURLString: "browser://home",
                currentPageURL: BrowserHomePage.url
            )
        ],
        selectedTabID: nil,
        workspaceCount: 3,
        selectedWorkspaceIndex: 1,
        urlFieldFocusRequestID: nil,
        onSelectTab: { _ in },
        onCloseTab: { _ in },
        onSidebarShortcut: nil,
        onSpotlightShortcut: nil,
        onCommandPaletteShortcut: nil,
        onFindShortcut: nil,
        onSettingsShortcut: nil,
        onDismiss: nil,
        onSubmit: {},
        shortcuts: BrowserShortcutStore.defaults
    )
}
