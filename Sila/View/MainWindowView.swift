//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct MainWindowView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scene

    @Environment(Router.self) private var router

    @State private var streamTimer = StreamTimer()

    /// Hack to prevent crash when saved stream windows are opened after reboot with a `nil` id
    /// Present in 1.1.1
    let id: String?

    var body: some View {
        TabView(selection: self.router.tabBinding) {
            TabPage(title: "Following", systemImage: Icon.following, tab: .following) {
                FollowedStreamsView()
            }

            TabPage(title: "Popular", systemImage: Icon.popular, tab: .popular) {
                PopularView()
            }

            TabPage(title: "Categories", systemImage: Icon.category, tab: .categories) {
                CategoryListView()
            }

//            TabPage(title: "Search", systemImage: Icon.search) {
//                SearchView()
//            }

            TabPage(title: "Settings", systemImage: Icon.settings, tab: .settings, content: {
                SettingsView()
            }, disableToolbar: true)
        }
        .environment(self.streamTimer)
        .onAppear {
            if self.id == nil {
                // This window shouldn't exist
                dismissWindow()
            }
        }
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
    MainWindowView(id: "main")
}
