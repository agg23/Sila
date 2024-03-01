//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import MarkdownUI

struct MainWindowView: View {
    var body: some View {
//        TabView {
//            // TODO: Change icon
//            TabPage(title: "Following", systemImage: Icon.following) {
//                FollowedStreamsView()
//            }
//
//            TabPage(title: "Popular", systemImage: Icon.popular) {
//                PopularView()
//            }
//
//            TabPage(title: "Categories", systemImage: Icon.category) {
//                CategoryListView()
//            }
//
//            TabPage(title: "Search", systemImage: Icon.search) {
//                SearchView()
//            }
//        }
//        ChatView(channel: "esl_dota2")
        SubviewTestList()
    }
}

#Preview {
    MainWindowView()
}
