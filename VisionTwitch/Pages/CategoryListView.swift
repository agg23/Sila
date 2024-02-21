//
//  GamesView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryListView: View {
    @State private var state: DataProvider<[Game], Error>? = DataProvider(taskClosure: { api in
        return Task {
            let (categories, _) = try await api.getTopGames(limit: 100)
            return categories
        }
    }, requiresAuth: false)

    var body: some View {
        DataView(provider: $state, content: { categories in
            ScrollGridView {
                CategoryGridView(categories: categories)
            }
            .refreshable {
                await self.state?.reload()
            }
        }, error: { _ in
            Text("Error")
        }, requiresAuth: false)
    }
}

#Preview {
    CategoryListView()
}
