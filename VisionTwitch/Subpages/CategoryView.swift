//
//  GameView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct CategoryView: View {
    @State private var loader = StandardDataLoader<([Twitch.Stream], Game, String?)>()

    var category: GameWrapper

    var body: some View {
        StandardScrollableDataView(loader: self.$loader) { api, _ in
            return try await self.fetchData(on: api)
        } content: { streams, game, cursor in
            StreamGridView(streams: streams, onPaginationThresholdMet: self.onPaginationThresholdMet)
                .navigationTitle(game.name)
        }
    }

    func fetchData(on api: Helix, using cursor: String? = nil) async throws -> ([Twitch.Stream], Game, String?) {
        switch self.category {
        case .game(let game):
            async let (streamsAsync, cursor) = try await api.getStreams(gameIDs: [game.id], after: cursor)
            return (try await streamsAsync, game, try await cursor)
        case .id(let id):
            async let (streamsAsync, cursorAsync) = try await api.getStreams(gameIDs: [id], after: cursor)
            async let gameAsync = try await api.getGames(gameIDs: [id])
            let (streams, games, cursor) = try await (streamsAsync, gameAsync, cursorAsync)

            guard games.count > 0 else {
                throw HelixError.requestFailed(error: "Could not find game", status: 200, message: "")
            }

            return (streams, games[0], cursor)
        }
    }

    func onPaginationThresholdMet() async {
        await self.loader.requestMore { data, apiAndUser in
            guard let originalCursor = data.2 else {
                return data
            }

            let newData = try await self.fetchData(on: apiAndUser.0, using: originalCursor)

            return (data.0 + newData.0, data.1, newData.2)
        }
    }
}

//#Preview {
//    CategoryView()
//}
