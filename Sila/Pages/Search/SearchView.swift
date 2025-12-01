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
    @State private var previousQuery = ""

    @State private var channelsExpanded = true
    @State private var categoriesExpanded = true

    var body: some View {
        StandardDataView(loader: self.$loader) { api, _ in
            // Dummy response. All data comes from onChange via the search text
            ([], [])
        } content: { categoriesAndChannels, _ in
            let (categories, channels) = categoriesAndChannels
            SearchListView(channels: channels, categories: categories, query: self.query, onSelectHistoryItem: { selectedQuery in
                self.query = selectedQuery
            })
        }
        // TODO: Maybe follow how Christian made a search bar https://christianselig.com/2024/03/recreating-visionos-search-bar/
        .searchable(text: self.$query, placement: .navigationBarDrawer)
        .onChange(of: self.query) { oldValue, newValue in
            self.requestTask?.cancel()

            self.requestTask = Task {
                await self.loader.requestMore { data, apiAndUser in
                    guard !newValue.isEmpty else {
                        return ([], [])
                    }

                    async let (categories, _) = try await apiAndUser.0.helix(endpoint: .searchCategories(for: self.query, limit: 18))
                    async let (channels, _) = try await apiAndUser.0.helix(endpoint: .searchChannels(for: self.query, liveOnly: true, limit: 18))
                    return try await (categories, channels)
                }
            }
            
            // Save search query when clearing the search box
            if newValue.isEmpty && !self.previousQuery.isEmpty {
                RecentsStore.shared.addSearchQuery(self.previousQuery)
            }
            self.previousQuery = newValue
        }
        .onDisappear {
            if !self.query.isEmpty {
                RecentsStore.shared.addSearchQuery(self.query)
            }
        }
    }
}

private func saveSearchQuery(_ query: String) {
    if !query.isEmpty {
        RecentsStore.shared.addSearchQuery(query)
    }
}

struct SearchListView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(Router.self) private var router
    @Environment(AuthController.self) private var authController

    let channels: [Channel]
    let categories: [Twitch.Category]
    let query: String
    let onSelectHistoryItem: (String) -> Void

    var body: some View {
        if self.query.isEmpty {
            RecentsHistoryView(onSelectSearchQuery: self.onSelectHistoryItem)
        } else {
            let noMatchingChannelsView = EmptyContentView(title: "No matching channels", systemImage: Icon.channel, description: "Adjust your search query for matching channels.", buttonTitle: "", buttonSystemImage: "", ignoreSafeArea: false, action: nil)
            let noMatchingCategoriesView = EmptyContentView(title: "No matching categories", systemImage: Icon.category, description: "Adjust your search query for matching categories.", buttonTitle: "", buttonSystemImage: "", ignoreSafeArea: false, action: nil)
            
            // TODO: Maybe follow how Christian made a search bar https://christianselig.com/2024/03/recreating-visionos-search-bar/
            OrnamentPickerTabView(leftTitle: "Live Channels", leftView: {
                if self.channels.isEmpty {
                    noMatchingChannelsView
                } else {
                    SearchGrid(items: self.channels) { channel in
                        SearchButton(title: channel.name, subtitle: channel.gameName, squareImage: {
                            LoadingAsyncImage(imageUrl: URL(string: channel.profilePictureURL), aspectRatio: 1.0)
                                .clipShape(.rect(cornerRadius: 8))
                        }) {
                            saveSearchQuery(self.query)
                            
                            Task {
                                // TODO: This can obviously fail. Ideally we can launch the stream window with just a channel login
                                // similar to how category/channel routes work
                                guard let api = self.authController.status.api() else {
                                    return
                                }

                                let (streams, _) = try await api.helix(endpoint: .getStreams(userLogins: [channel.login]))

                                guard let stream = streams.first else {
                                    return
                                }

                                StreamOpener.openStream(stream: stream, openWindow: self.openWindow, profileImageUrl: channel.profilePictureURL)
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

                                    Color.clear
                                        .aspectRatio(1.0, contentMode: .fit)
                                }
                        }) {
                            saveSearchQuery(self.query)
                            self.router.pushToActiveTab(route: .category(game: .id(category.id)))
                        }
                    }
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

#Preview {
    PreviewNavStack {
        SearchListView(channels: CHANNEL_LIST_MOCK().prefix(10).map({ $0 }), categories: CATEGORY_LIST_MOCK().prefix(10).map({ game in
            Category(game: game)
        }), query: "test", onSelectHistoryItem: { _ in })
    }
}

#Preview {
    PreviewNavStack {
        SearchListView(channels: CHANNEL_LIST_MOCK().prefix(1).map({ $0 }), categories: CATEGORY_LIST_MOCK().prefix(1).map({ game in
            Category(game: game)
        }), query: "test", onSelectHistoryItem: { _ in })
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
