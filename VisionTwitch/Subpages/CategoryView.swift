//
//  GameView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct CategoryView: View {
    var category: GameWrapper

    var body: some View {
        DataView(taskClosure: { api in
            return Task {
                let (streams, _) = try await api.getStreams(gameIDs: [self.category.game.id])
                return streams
            }
        }, content: { streams in
            ScrollGridView {
                StreamGridView(streams: streams)
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: false, runOnAppear: true)
            .navigationTitle(self.category.game.name)
    }
}

//#Preview {
//    CategoryView()
//}
