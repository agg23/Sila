//
//  GameView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct CategoryView: View {
    @State private var loader = DataLoader<[Twitch.Stream], AuthStatus>()

    var category: GameWrapper

    var body: some View {
        StandardScrollableDataView(loader: self.$loader) { api, _ in
            let (streams, _) = try await api.getStreams(gameIDs: [self.category.game.id])
            return streams
        } content: { streams in
            StreamGridView(streams: streams)
        }
        .navigationTitle(self.category.game.name)
    }
}

//#Preview {
//    CategoryView()
//}
