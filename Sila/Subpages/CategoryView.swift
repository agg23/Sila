//
//  GameView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct CategoryView: View {
    @AppStorage(Setting.hideMature) var hideMature: Bool = false

    @State private var loader = StandardDataLoader<([Twitch.Stream], Game, String?)>()
    @State private var existingIds = Set<String>()

    var category: GameWrapper

    var body: some View {
        LanguageFilterView(onFilterChange: { language in
            await self.loader.requestMore { data, apiAndUser in
                try await self.fetchData(on: apiAndUser.0, overwriting: true, language: language)
            }
        }) { selectedLanguage in
            StandardDataView(loader: self.$loader) { api, _ in
                try await self.fetchData(on: api, overwriting: true, language: selectedLanguage.wrappedValue)
            } content: { (data, refreshToken) in
                let (streams, game, cursor) = data
                CategoryViewContent(game: game, streams: streams, refreshToken: refreshToken, selectedLanguage: selectedLanguage, loader: self.loader) {
                    await self.onPaginationThresholdMet(language: selectedLanguage.wrappedValue)
                }
            }
        }
        // TODO: Readd when .navigationTitle is fixed
//        .navigationTitlePlaceholder()
    }

    func fetchData(on api: TwitchClient, overwriting: Bool, language: String, using cursor: String? = nil) async throws -> ([Twitch.Stream], Game, String?) {
        let filterLanguages = language == "all" ? [] : [language]

        switch self.category {
        case .game(let game):
            let (streams, cursor) = try await api.helix(endpoint: .getStreams(gameIDs: [game.id], languages: filterLanguages, after: cursor))

            if overwriting {
                self.existingIds = Set(streams.map({ $0.id }))

                return (streams, game, cursor)
            } else {
                let newStreams = streams.filter({ !self.existingIds.contains($0.id) })
                self.existingIds.formUnion(newStreams.map({ $0.id }))

                return (newStreams, game, cursor)
            }
        case .id(let id):
            async let (streamsAsync, cursorAsync) = try await api.helix(endpoint: .getStreams(gameIDs: [id], languages: filterLanguages, after: cursor))
            async let gameAsync = try await api.helix(endpoint: .getGames(gameIDs: [id]))
            let (streams, games, cursor) = try await (streamsAsync, gameAsync, cursorAsync)

            guard games.count > 0 else {
                throw HelixError.twitchError(name: "Could not find game", status: 200, message: "")
            }

            if overwriting {
                self.existingIds = Set(streams.map({ $0.id }))

                return (streams, games[0], cursor)
            } else {
                let newStreams = streams.filter({ !self.existingIds.contains($0.id) })
                self.existingIds.formUnion(newStreams.map({ $0.id }))

                return (newStreams, games[0], cursor)
            }
        }
    }

    func onPaginationThresholdMet(language: String) async {
        await self.loader.requestMore { data, apiAndUser in
            guard let originalCursor = data.2 else {
                return data
            }

            let newData = try await self.fetchData(on: apiAndUser.0, overwriting: false, language: language, using: originalCursor)

            return (data.0 + newData.0, data.1, newData.2)
        }
    }
}

private struct CategoryViewContent: View {
    let game: Twitch.Game
    let streams: [Twitch.Stream]
    let refreshToken: RefreshToken

    @Binding var selectedLanguage: String

    let loader: StandardDataLoader<([Twitch.Stream], Game, String?)>
    let onPaginationThresholdMet: () async -> Void

    var body: some View {
        MatureStreamFilterView(streams: streams) { streams in
            if streams.isEmpty {
                EmptyDataView(title: "No Livestreams", systemImage: Icon.category, message: "livestreams") {
                    Task {
                        try await self.loader.refresh()
                    }
                }
            } else {
                RefreshableScrollGridView(loader: self.loader) {
                    StreamGridView(streams: streams, refreshToken: refreshToken, onPaginationThresholdMet: self.onPaginationThresholdMet)
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
        .largeNavigationTitle(self.game.name)
    }
}

#Preview {
    TabPage(title: "Category", systemImage: "foo", tab: .categories) {
        CategoryViewContent(game: CATEGORY_MOCK(), streams: STREAMS_LIST_MOCK(), refreshToken: UUID(), selectedLanguage: .constant("en"), loader: StandardDataLoader()) {}
    }
    .environment(Router())
}
