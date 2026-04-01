//
//  TabPage.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct TabPage<Content: View>: View {
    @Environment(Router.self) private var router
    @Environment(\.disablePrimaryOrnaments) private var disablePrimaryOrnaments

    let title: String
    let systemImage: String
    let tab: SelectedTab
    let content: () -> Content

    var body: some View {
        NavStack(tab: self.tab) {
            self.content()
                .largeNavigationTitle(self.title)
                .navigationDestination(for: Route.self, destination: { route in
                    switch route {
                    case .category(game: let gameWrapper):
                        CategoryView(category: gameWrapper)
                    case .channel(user: let userWrapper):
                        ChannelView(channel: userWrapper)
                            .toolbar {
                                defaultToolbar()
                            }
                    case .playback(video: let video):
                        TwitchEmbeddedContentView(streamableVideo: video)
                            #if !os(macOS)
                            .toolbar(.hidden, for: .tabBar)
                            #endif
                    }
                })
                #if !os(macOS)
                .toolbar(self.disablePrimaryOrnaments ? .hidden : .automatic, for: .tabBar)
                #endif
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
