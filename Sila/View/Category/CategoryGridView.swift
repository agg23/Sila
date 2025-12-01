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
    let refreshToken: RefreshToken

    let onPaginationThresholdMet: (() async -> Void)?

    internal init(categories: [Game], refreshToken: RefreshToken, onPaginationThresholdMet: (() async -> Void)? = nil) {
        self.categories = categories
        self.refreshToken = refreshToken
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
                CategoryButtonView(category: category, refreshToken: self.refreshToken)
            }

            Color.clear.task {
                await self.onPaginationThresholdMet?()
            }
        }
    }
}

#Preview {
    PreviewNavStack {
        CategoryGridView(categories: CATEGORY_LIST_MOCK(), refreshToken: UUID())
    }
}
