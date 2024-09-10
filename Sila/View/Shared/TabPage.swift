//
//  TabPage.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct TabPage<Content: View>: View {
    let title: String
    let systemImage: String
    let tab: SelectedTab
    let content: () -> Content

    var body: some View {
        NavStack(tab: self.tab) {
            self.content()
//                .navigationTitle(self.title)
                // navigationTitle is very small on visionOS 2.0. Insert our own title instead
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text(self.title)
                            .font(.largeTitle)
                    }
                }
                .navigationDestination(for: Route.self, destination: { route in
                    switch route {
                    case .category(game: let gameWrapper):
                        CategoryView(category: gameWrapper)
                    case .channel(user: let userWrapper):
                        ChannelView(channel: userWrapper)
                            .toolbar {
                                defaultToolbar()
                            }
                    }
                })
        }
        .tabItem {
            Label(self.title, systemImage: self.systemImage)
        }
        .tag(self.tab)
    }
}

#Preview {
    TabView {
        TabPage(title: "Test page", systemImage: "person", tab: .following) {
            Text("Hello world")
        }
    }
}
