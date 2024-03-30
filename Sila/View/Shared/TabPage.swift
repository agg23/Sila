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

    let disableToolbar: Bool

    init(title: String, systemImage: String, tab: SelectedTab, @ViewBuilder content: @escaping () -> Content, disableToolbar: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.tab = tab
        self.content = content

        self.disableToolbar = disableToolbar
    }

    var body: some View {
        NavStack(tab: self.tab) {
            self.content()
                .toolbar {
                    if !self.disableToolbar {
                        defaultToolbar()
                    }
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
