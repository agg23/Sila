//
//  SearchView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/23/24.
//

import SwiftUI
import Twitch

struct SearchView: View {
    @State private var loader = StandardDataLoader<([Twitch.Category], [Channel])>()
    @State private var requestTask: Task<(), Error>?
    @State private var query = ""
    @StateObject private var historyStore = HistoryStore.shared

    @State private var channelsExpanded = true
    @State private var categoriesExpanded = true

    var body: some View {
        StandardDataView(loader: self.$loader) { api, _ in
            // Dummy response. All data comes from onChange via the search text
            ([], [])
        } content: { categories, channels in
            SearchListView(channels: channels, categories: categories, query: self.query, historyStore: self.historyStore, onSelectHistoryItem: { selectedQuery in
                self.query = selectedQuery
            })
        }
        // TODO: Maybe follow how Christian made a search bar https://christianselig.com/2024/03/recreating-visionos-search-bar/
        .searchable(text: self.$query, placement: .navigationBarDrawer)
        .onSubmit(of: .search) {
            // Save the search query when user submits
            if !self.query.isEmpty {
                self.historyStore.addSearchQuery(self.query)
            }
        }
        .onChange(of: self.query) { _, newValue in
            self.requestTask?.cancel()

            self.requestTask = Task {
                await self.loader.requestMore { data, apiAndUser in
                    guard !newValue.isEmpty else {
                        return ([], [])
                    }

                    async let (categories, _) = try await apiAndUser.0.searchCategories(for: self.query, limit: 18)
                    async let (channels, _) = try await apiAndUser.0.searchChannels(for: self.query, liveOnly: true, limit: 18)
                    return try await (categories, channels)
                }
            }
        }
    }
}

struct SearchListView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(Router.self) private var router
    @Environment(AuthController.self) private var authController

    let channels: [Channel]
    let categories: [Twitch.Category]
    let query: String
    let historyStore: HistoryStore
    let onSelectHistoryItem: (String) -> Void

    var body: some View {
        if self.query.isEmpty {
            // Show history when no active search
            HistoryView(historyStore: self.historyStore, onSelectHistoryItem: self.onSelectHistoryItem)
        } else {
            // Show search results
            let noMatchingChannelsView = EmptyContentView(title: "No matching channels", systemImage: Icon.channel, description: "Adjust your search query for matching channels.", buttonTitle: "", buttonSystemImage: "", ignoreSafeArea: false, action: nil)
            let noMatchingCategoriesView = EmptyContentView(title: "No matching categories", systemImage: Icon.category, description: "Adjust your search query for matching categories.", buttonTitle: "", buttonSystemImage: "", ignoreSafeArea: false, action: nil)
            
            OrnamentPickerTabView(leftTitle: "Live Channels", leftView: {
                if self.channels.isEmpty {
                    noMatchingChannelsView
                } else {
                    SearchGrid(items: self.channels) { channel in
                        SearchButton(title: channel.name, subtitle: channel.gameName, squareImage: {
                            LoadingAsyncImage(imageUrl: URL(string: channel.profilePictureURL), aspectRatio: 1.0)
                                .clipShape(.rect(cornerRadius: 8))
                        }) {
                            Task {
                                // TODO: This can obviously fail. Ideally we can launch the stream window with just a channel login
                                // similar to how category/channel routes work
                                guard let api = self.authController.status.api() else {
                                    return
                                }

                                let (streams, _) = try await api.getStreams(userLogins: [channel.login])

                                guard let stream = streams.first else {
                                    return
                                }

                                // Track the opened stream in history
                                self.historyStore.addRecentStream(stream)
                                
                                openWindow(id: "stream", value: stream)
                            }
                        }
                    }
                    // Padding applied inside TabView so panning gesture between pages doesn't show items butting up next to each other
                    .padding(16)
                }
            }, rightTitle: "Categories") {
                if self.categories.isEmpty {
                    noMatchingCategoriesView
                } else {
                    SearchGrid(items: self.categories) { category in
                        SearchButton(title: category.name, subtitle: nil, squareImage: {
                                ZStack {
                                    LoadingAsyncImage(imageUrl: URL(string: category.boxArtUrl), aspectRatio: 0.75)
                                        .clipShape(.rect(cornerRadius: 8))

                                    // Background rectangle to horizontally center the image in the same footprint as the square channel avatars
                                    Color.clear
                                        .aspectRatio(1.0, contentMode: .fit)
                                }
                        }) {
                            self.router.pushToActiveTab(route: .category(game: .id(category.id)))
                        }
                    }
                    // Padding applied inside TabView so panning gesture between pages doesn't show items butting up next to each other
                    .padding(16)
                }
            }
        }
    }
}

private struct SearchGrid<T: Identifiable, Content: View>: View {
    let items: [T]
    @ViewBuilder let content: (_: T) -> Content

    var body: some View {
        VStack {
            LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                ForEach(self.items) { self.content($0) }
            }

            Spacer()
        }
    }
}

private struct SearchButton<ContentImage: View>: View {
    let title: String
    let subtitle: String?

    @ViewBuilder let squareImage: () -> ContentImage

    let action: () -> Void

    var body: some View {
        Button {
            self.action()
        } label: {
            HStack {
                self.squareImage()
                    .padding(.trailing, 8)
                VStack(alignment: .leading) {
                    Text(self.title)
                    
                    if let subtitle = self.subtitle {
                        Text(subtitle)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(6)
            .background(.tertiary)
            .cornerRadius(14)
        }
        .frame(height: 80)
        .buttonStyle(.plain)
        // 8 inner radius + 6 padding
        .buttonBorderShape(.roundedRectangle(radius: 14))
    }
}

private struct HistoryView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(Router.self) private var router
    @Environment(AuthController.self) private var authController
    
    @ObservedObject var historyStore: HistoryStore
    let onSelectHistoryItem: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Search History Section
                if !historyStore.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Search History")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button("Clear") {
                                historyStore.clearSearchHistory()
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 16)
                        
                        LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 12) {
                            ForEach(historyStore.searchHistory, id: \.self) { query in
                                Button {
                                    onSelectHistoryItem(query)
                                } label: {
                                    HStack {
                                        Image(systemName: Icon.search)
                                            .foregroundColor(.secondary)
                                        Text(query)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .background(.tertiary)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                                .buttonBorderShape(.roundedRectangle(radius: 10))
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Recent Streams Section
                if !historyStore.recentStreams.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recently Opened Streams")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button("Clear") {
                                historyStore.clearRecentStreams()
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 16)
                        
                        LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 12) {
                            ForEach(historyStore.recentStreams) { recentStream in
                                SearchButton(title: recentStream.userName, subtitle: recentStream.gameName, squareImage: {
                                    // Use a placeholder for recent streams since we don't store profile pictures
                                    ZStack {
                                        Color.gray.opacity(0.3)
                                        Image(systemName: Icon.channel)
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                    }
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .clipShape(.rect(cornerRadius: 8))
                                }) {
                                    Task {
                                        guard let api = self.authController.status.api() else {
                                            return
                                        }
                                        
                                        // Re-fetch the stream to ensure it's still live
                                        let (streams, _) = try await api.getStreams(userLogins: [recentStream.userLogin])
                                        
                                        guard let stream = streams.first else {
                                            return
                                        }
                                        
                                        // Update the recent stream entry with the latest data
                                        historyStore.addRecentStream(stream)
                                        
                                        openWindow(id: "stream", value: stream)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Empty state when no history
                if historyStore.searchHistory.isEmpty && historyStore.recentStreams.isEmpty {
                    EmptyContentView(
                        title: "No Search History",
                        systemImage: Icon.search,
                        description: "Search for live channels or categories to see your history here.",
                        buttonTitle: "",
                        buttonSystemImage: "",
                        ignoreSafeArea: false,
                        action: nil
                    )
                }
            }
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    PreviewNavStack {
        SearchListView(channels: CHANNEL_LIST_MOCK().prefix(20).map({ $0 }), categories: CATEGORY_LIST_MOCK().prefix(20).map({ game in
            Category(game: game)
        }), query: "test", historyStore: HistoryStore.shared, onSelectHistoryItem: { _ in })
    }
}

#Preview {
    PreviewNavStack {
        SearchListView(channels: CHANNEL_LIST_MOCK().prefix(10).map({ $0 }), categories: CATEGORY_LIST_MOCK().prefix(10).map({ game in
            Category(game: game)
        }), query: "test", historyStore: HistoryStore.shared, onSelectHistoryItem: { _ in })
    }
}

#Preview {
    PreviewNavStack {
        SearchListView(channels: CHANNEL_LIST_MOCK().prefix(1).map({ $0 }), categories: CATEGORY_LIST_MOCK().prefix(1).map({ game in
            Category(game: game)
        }), query: "test", historyStore: HistoryStore.shared, onSelectHistoryItem: { _ in })
    }
}

#Preview {
    let channel = CHANNEL_LIST_MOCK()[1]

    return SearchButton(title: channel.name, subtitle: channel.gameName, squareImage: {
        LoadingAsyncImage(imageUrl: URL(string: channel.profilePictureURL), aspectRatio: 1.0)
            .clipShape(.rect(cornerRadius: 8))
    }) {

    }
}
