//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI

struct MainWindowView: View {
    @Environment(\.scenePhase) private var scene

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
        .onAppear {
            WindowController.shared.mainWindowSpawned = true
        }
        .onChange(of: self.scene) { oldValue, newValue in
            if newValue == .background {
                WindowController.shared.mainWindowSpawned = false
            }
        }
    }
}

#Preview {
    MainWindowView()
}
