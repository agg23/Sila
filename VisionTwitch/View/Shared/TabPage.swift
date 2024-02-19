//
//  TabPage.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct TabPage<Content: View>: View {
    var title: String
    var systemImage: String
    var content: () -> Content

    var body: some View {
        NavStack {
            self.content()
                .toolbar {
                    defaultToolbar()
                }
                .navigationTitle(self.title)
        }
            .tabItem {
                Label(self.title, systemImage: self.systemImage)
            }
    }
}

#Preview {
    TabView {
        TabPage(title: "Test page", systemImage: "person") {
            Text("Hello world")
        }
    }
}
