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
        HStack(spacing: 0) {
            if isSidebarVisible {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200)
            }

            ZStack {
                KeyboardCaptureView {
                    isSidebarVisible.toggle()
                }
                .frame(width: 0, height: 0)

                Text("Press Cmd + \\")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
