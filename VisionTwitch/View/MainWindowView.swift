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
                // TODO: Change icon
                TabPage(title: "Following", systemImage: "person.crop.square.badge.video.fill") {
                    FollowedStreamsView()
                }

                TabPage(title: "Popular", systemImage: "star") {
                    PopularView()
                }

                TabPage(title: "Categories", systemImage: "gamecontroller") {
                    CategoryListView()
                }

                TabPage(title: "Search", systemImage: "magnifyingglass") {
                    VStack {

                    }
                }
            }
        }
    }
}

#Preview {
    MainWindowView()
}
