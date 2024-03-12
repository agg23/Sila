//
//  CategoryGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryGridView: View {
    let categories: [Twitch.Game]

    let onPaginationThresholdMet: (() async -> Void)?

    internal init(categories: [Game], onPaginationThresholdMet: (() async -> Void)? = nil) {
        self.categories = categories
        self.onPaginationThresholdMet = onPaginationThresholdMet
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(spacing: 16),
            GridItem(spacing: 16),
            GridItem(spacing: 16),
            GridItem(spacing: 16),
            GridItem(spacing: 16),
            GridItem(spacing: 16)
        ], spacing: 16){
            ForEach(self.categories, id: \.id) { category in
                CategoryButtonView(category: category)
            }

            Color.clear.task {
                await self.onPaginationThresholdMet?()
            }
        }
    }
}

#Preview {
    NavStack {
        CategoryGridView(categories: CATEGORY_LIST_MOCK())
    }
}
