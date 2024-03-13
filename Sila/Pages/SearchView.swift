//
//  SearchView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/23/24.
//

import SwiftUI
import Twitch

struct SearchView: View {
    @Environment(\.authController) private var authController

//    @State private var loader = DataLoader<([Twitch.Category], [Channel]), String>()
    @State private var text = ""

    @State private var channelsExpanded = true
    @State private var categoriesExpanded = true

    var body: some View {
//        Group {
//            switch self.$loader.wrappedValue.get(task: {
//                guard let api = self.authController.status.api(), !self.text.isEmpty else {
//                    return ([], [])
//                }
//
//                async let (categories, _) = try await api.searchCategories(for: self.text)
//                async let (channels, _) = try await api.searchChannels(for: self.text)
//                return try await (categories, channels)
//            }, onChange: self.text) {
//            case .idle:
//                self.emptyState
//            case .loading:
//                ProgressView()
//            case .finished(let (categories, channels)):
//                if categories.isEmpty && channels.isEmpty {
//                    self.emptyState
//                } else {
//                    SearchListView(channels: channels, categories: categories)
//                }
//            case .error:
//                APIErrorView(loader: self.$loader)
//            }
//        }
//        .searchable(text: self.$text, placement: .navigationBarDrawer)
        Text("Broken")
    }

    @ViewBuilder
    var emptyState: some View {
        Text("Search for channels and categories")
    }
}

struct SearchListView: View {
    let channels: [Channel]
    let categories: [Twitch.Category]

    var body: some View {
        List {
            Section("Channels") {
                ForEach(self.channels) { channel in
                    SearchChannelButton(channel: channel)
                }
            }
            Section("Categories") {
                ForEach(self.categories) { category in
                    SearchCategoryButton(category: category)
                }
            }
        }
        .listStyle(.plain)
    }
}

struct SearchChannelButton: View {
    @Environment(Router.self) private var router

    let channel: Channel

    var body: some View {
        Button {
            self.router.path.append(.channel(user: .id(self.channel.id)))
        } label: {
            GeometryReader { geometry in
                HStack {
                    LoadingAsyncImage(imageUrl: URL(string: self.channel.profilePictureURL), aspectRatio: 1.0)
                        .frame(width: geometry.size.height)
                        .padding(.trailing, 8)
                    Text(self.channel.name)
                    Spacer()
                }
            }
        }
    }
}

struct SearchCategoryButton: View {
    @Environment(Router.self) private var router

    let category: Twitch.Category

    var body: some View {
        Button {
            self.router.path.append(.category(game: .id(self.category.id)))
        } label: {
            GeometryReader { geometry in
                HStack {
                    LoadingAsyncImage(imageUrl: URL(string: self.category.boxArtUrl), aspectRatio: 0.75)
                        .frame(width: geometry.size.height)
                        .padding(.trailing, 8)
                    Text(self.category.name)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    NavStack {
        SearchListView(channels: CHANNEL_LIST_MOCK(), categories: CATEGORY_LIST_MOCK().prefix(20).map({ game in
            Category(game: game)
        }))
    }
}
