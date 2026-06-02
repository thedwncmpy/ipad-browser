//
//  ContentView.swift
//  browser
//
//  Created by Edwin Olivares on 5/29/26.
//
import SwiftUI

struct ContentView: View {
    @State private var isSidebarVisible = false

    var body: some View {
        ZStack(alignment: .leading) {
            ZStack {
                KeyboardCaptureView {
                    isSidebarVisible.toggle()
                }
                .frame(width: 0, height: 0)

                Text("Press Cmd + \\")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isSidebarVisible {
                SidebarView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: isSidebarVisible)
    }
}

#Preview {
    ContentView()
}
