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
                TabPage(title: "Following", systemImage: Icon.following) {
                    FollowedStreamsView()
                }

                TabPage(title: "Popular", systemImage: Icon.popular) {
                    PopularView()
                }

                TabPage(title: "Categories", systemImage: Icon.category) {
                    CategoryListView()
                }

                TabPage(title: "Search", systemImage: Icon.search) {
                    SearchView()
                }
            }
        }
    }
}

#Preview {
    MainWindowView()
}
