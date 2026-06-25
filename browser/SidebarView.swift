//
//  SidebarView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct SidebarView: View {
    private let inset: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 360, height: geometry.size.height - (inset * 2))
                .padding(.leading, inset)
                .padding(.top, inset)
        }
        .ignoresSafeArea(edges: .vertical)
    }
}

#Preview {
    SidebarView()
}
