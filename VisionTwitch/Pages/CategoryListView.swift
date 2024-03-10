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

    var body: some View {
        StandardScrollableDataView(loader: self.$loader) { api, user in
            try await api.getTopGames(limit: 100)
        } content: { categories, _ in
            if categories.isEmpty {
                EmptyDataView(title: "No Categories", systemImage: Icon.category, message: "categories") {
                    Task {
                        try await self.loader.refresh()
                    }
                }
                .containerRelativeFrame(.vertical)
            } else {
                CategoryGridView(categories: categories, onPaginationThresholdMet: self.onPaginationThresholdMet)
            }
        }
    }

    func onPaginationThresholdMet() async {
        await self.loader.requestMore { data, apiAndUser in
            guard let originalCursor = data.1 else {
                return data
            }

            let newData = try await apiAndUser.0.getTopGames(limit: 100, after: originalCursor)
            return (data.0 + newData.0, newData.1)
        }
    }
}

#Preview {
    CategoryListView()
}
