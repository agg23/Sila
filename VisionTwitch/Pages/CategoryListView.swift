//
//  GamesView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryListView: View {
    @State private var loader = StandardDataLoader<[Game]>()

    var body: some View {
        StandardScrollableDataView(loader: self.$loader) { api, user in
            let (categories, _) = try await api.getTopGames(limit: 100)
            return categories
        } content: { categories in
            CategoryGridView(categories: categories)
        }
    }
}

#Preview {
    CategoryListView()
}
