//
//  BrowseView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct PopularView: View {
    @State private var loader = StandardDataLoader<([Twitch.Stream], String?)>()
    @State private var existingIds = Set<String>()

    var body: some View {
        LanguageFilterView(onFilterChange: { language in
            Task {
                await self.loader.requestMore { data, apiAndUser in
                    try await self.fetchStreams(api: apiAndUser.0, language: language)
                }
            }
        }) { selectedLanguage in
            StandardDataView(loader: self.$loader) { api, _ in
                try await fetchStreams(api: api, language: selectedLanguage.wrappedValue)
            } content: { data, refreshToken in
                PopularContentView(streams: data.0, selectedLanguage: selectedLanguage, loader: self.loader, refreshToken: refreshToken) {
                    await self.onPaginationThresholdMet(language: selectedLanguage.wrappedValue)
                }
            }
        }
    }

    func fetchStreams(api: TwitchClient, language: String) async throws -> ([Twitch.Stream], String?) {
        let filterLanguages = language == "all" ? [] : [language]

        let streams = try await api.helix(endpoint: .getStreams(languages: filterLanguages, limit: 100))

        self.existingIds = Set(streams.0.map({ $0.id }))

        return (streams.0, streams.1)
    }

    func onPaginationThresholdMet(language: String) async {
        print("Loading more")
        await self.loader.requestMore { data, apiAndUser in
            guard let originalCursor = data.1 else {
                return data
            }

            let filterLanguages = language == "all" ? [] : [language]

            let (newData, cursor) = try await apiAndUser.0.helix(endpoint: .getStreams(languages: filterLanguages, limit: 100, after: originalCursor))

            // Prevent duplicates from appearing, due to the list resorting while being fetched
            let newStreams = newData.filter({ !self.existingIds.contains($0.id) })
            self.existingIds.formUnion(newStreams.map({ $0.id }))

            return (data.0 + newStreams, cursor)
        }
    }
}

private struct PopularContentView: View {
    let streams: [Twitch.Stream]

    @Binding var selectedLanguage: String

    let loader: StandardDataLoader<([Twitch.Stream], String?)>
    let refreshToken: RefreshToken
    let onPaginationThresholdMet: () async -> Void

    var body: some View {
        MatureStreamFilterView(streams: streams) { streams in
            if streams.isEmpty {
                EmptyDataView(title: "No Livestreams", systemImage: Icon.popular, message: "livestreams") {
                    Task {
                        try await self.loader.refresh()
                    }
                }
            } else {
                RefreshableScrollGridView(loader: self.loader) {
                    StreamGridView(streams: streams, refreshToken: self.refreshToken, onPaginationThresholdMet: self.onPaginationThresholdMet)
                }
            }
        }
        // .toolbar is here so it can be in the previews without networking
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                LanguageFilterPickerView(language: self.$selectedLanguage)
            }

            defaultToolbar()
        }
    }
}

#Preview {
    TabPage(title: "Popular", systemImage: "star", tab: .popular, content: {
        PopularContentView(streams: STREAMS_LIST_MOCK(), selectedLanguage: .constant("en"), loader: StandardDataLoader<([Twitch.Stream], String?)>(), refreshToken: UUID()) {

        }
    })
    .environment(Router())
}

#Preview {
    TabPage(title: "Popular", systemImage: "star", tab: .popular, content: {
        PopularContentView(streams: [], selectedLanguage: .constant("en"), loader: StandardDataLoader<([Twitch.Stream], String?)>(), refreshToken: UUID()) {

        }
    })
    .environment(Router())
}
