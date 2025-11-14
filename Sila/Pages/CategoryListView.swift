//
//  GamesView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryListView: View {
    @State private var loader = StandardDataLoader<([Game], String?)>()
    @State private var existingIds = Set<String>()

    var body: some View {
        StandardDataView(loader: self.$loader) { api, user in
            let (streams, cursor) = try await api.helix(endpoint: .getTopGames(limit: 100))

            self.existingIds = Set(streams.map({ $0.id }))

            return (streams, cursor)
        } content: { categories, _ in
            if categories.isEmpty {
                EmptyDataView(title: "No Categories", systemImage: Icon.category, message: "categories") {
                    Task {
                        try await self.loader.refresh()
                    }
                }
            } else {
                RefreshableScrollGridView(loader: self.loader) {
                    CategoryGridView(categories: categories, onPaginationThresholdMet: self.onPaginationThresholdMet)
                }
            }
        }
//        .toolbar {
//            // Toolbar is disabled for Category pages
//            defaultToolbar()
//        }
    }

    func onPaginationThresholdMet() async {
        await self.loader.requestMore { data, apiAndUser in
            guard let originalCursor = data.1 else {
                return data
            }

            let newData = try await apiAndUser.0.helix(endpoint: .getTopGames(limit: 100, after: originalCursor))

            // Prevent duplicates from appearing, due to the list resorting while being fetched
            let newStreams = newData.0.filter({ !self.existingIds.contains($0.id) })
            self.existingIds.formUnion(newStreams.map({ $0.id }))

            return (data.0 + newStreams, newData.1)
        }
    }
}

#Preview {
    CategoryListView()
}
