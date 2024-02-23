//
//  GameView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct CategoryView: View {
    @State private var loader = DataLoader<([Twitch.Stream], Game), AuthStatus>()

    var category: GameWrapper

    var body: some View {
        StandardScrollableDataView(loader: self.$loader) { api, _ in
            switch self.category {
            case .game(let game):
                async let (streamsAsync, _) = try await api.getStreams(gameIDs: [game.id])
                return (try await streamsAsync, game)
            case .id(let id):
                async let (streamsAsync, _) = try await api.getStreams(gameIDs: [id])
                async let gameAsync = try await api.getGames(gameIDs: [id])
                let (streams, games) = try await (streamsAsync, gameAsync)

                guard games.count > 0 else {
                    throw HelixError.requestFailed(error: "Could not find game", status: 200, message: "")
                }

                return (streams, games[0])
            }
        } content: { (streams, game) in
            StreamGridView(streams: streams)
                .navigationTitle(game.name)
        }
    }
}

//#Preview {
//    CategoryView()
//}
