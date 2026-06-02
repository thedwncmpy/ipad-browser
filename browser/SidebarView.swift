//
//  SidebarView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct SidebarView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 360)
            .padding(.leading, 20)
            .padding(.vertical, 6)
    }
}

#Preview {
    SidebarView()
}
