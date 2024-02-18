//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI

struct MainWindowView: View {
    var body: some View {
        ZStack {
            TabView {
                FollowedStreamsView()
                    .tabItem {
                        // TODO: Change
                        Label("Following", systemImage: "person.crop.square.badge.video.fill")
                    }

                BrowseView()
                    .tabItem {
                        Label("Browse", systemImage: "play.rectangle")
                    }

                VStack {

                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass.circle")
                }
            }

            AuthBadgeView()
                // Force filling window and position in top right corner
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.all, 32)
        }
    }
}

#Preview {
    MainWindowView()
}
