//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI

struct MainWindowView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scene

    @Environment(Router.self) private var router

    @State private var streamTimer = StreamTimer()

    var body: some View {
        TabView {
            // TODO: Change icon
            TabPage(title: "Following", systemImage: Icon.following) {
                FollowedStreamsView()
            }

            TabPage(title: "Popular", systemImage: Icon.popular) {
                PopularView()
            }

            TabPage(title: "Categories", systemImage: Icon.category) {
                CategoryListView()
            }

            #if VOD_ENABLED
            TabPage(title: "Search", systemImage: Icon.search) {
                SearchView()
            }
            #endif

            TabPage(title: "Settings", systemImage: Icon.settings, content: {
                SettingsView()
            }, disableToolbar: true)
        }
        .environment(self.streamTimer)
        // Located at root of main window, as each of the tabs can be rendered at the same time
        .onChange(of: self.router.bufferedWindowOpen, initial: true, { _, newValue in
            guard let window = newValue else {
                return
            }

            self.router.bufferedWindowOpen = nil

            switch window {
            case .stream(let stream):
                openWindow(id: "stream", value: stream)
            case .vod(let video):
                openWindow(id: "vod", value: video)
            }
        })
    }
}

#Preview {
    MainWindowView()
}
