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
    let content: () -> Content

    var body: some View {
        NavStack {
            self.content()
                .toolbar {
                    defaultToolbar()
                }
                .navigationTitle(self.title)
                .navigationDestination(for: Route.self, destination: { route in
                    switch route {
                    case .category(game: let gameWrapper):
                        CategoryView(category: gameWrapper)
                            .toolbar {
                                defaultToolbar()
                            }
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
    }
}

#Preview {
    TabView {
        TabPage(title: "Test page", systemImage: "person") {
            Text("Hello world")
        }
    }
}
