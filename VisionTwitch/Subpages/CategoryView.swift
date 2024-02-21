//
//  GameView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct CategoryView: View {
    @State private var state: DataProvider<[Twitch.Stream], Error>? = nil

    var category: GameWrapper

    var body: some View {
        DataView(provider: $state, content: { streams in
            ScrollGridView {
                StreamGridView(streams: streams)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: false)
            .navigationTitle(self.category.game.name)
            .onAppear(perform: {
                self.state = DataProvider(taskClosure: { api in
                    return Task {
                        let (streams, _) = try await api.getStreams(gameIDs: [self.category.game.id])
                        return streams
                    }
                }, requiresAuth: false)
            })
    }
}

//#Preview {
//    CategoryView()
//}
