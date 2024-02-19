//
//  GamesView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryView: View {
    var body: some View {
        DataView(taskClosure: { api in
            return Task {
                let (categories, _) = try await api.getTopGames(limit: 100)
                return categories
            }
        }, content: { categories in
            CategoryGridPageView(categories: categories)
        }, error: { _ in
            Text("Error")
        }, requiresAuth: true, runOnAppear: true)
    }
}

#Preview {
    CategoryView()
}
