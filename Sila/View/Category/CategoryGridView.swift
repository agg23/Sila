//
//  CategoryGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryGridView: View {
    #if os(tvOS)
    private static let columnSpacing: CGFloat = 24
    private static let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: CategoryGridView.columnSpacing, alignment: .top), count: 6)
    #elseif os(macOS)
    private static let columnSpacing: CGFloat = 16
    private static let columns: [GridItem] = [GridItem(.adaptive(minimum: 150), spacing: CategoryGridView.columnSpacing, alignment: .top)]
    #else
    private static let columnSpacing: CGFloat = 16
    private static let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: CategoryGridView.columnSpacing, alignment: .top), count: 6)
    #endif

    let categories: [Twitch.Game]
    let refreshToken: RefreshToken

    let onPaginationThresholdMet: (() async -> Void)?

    internal init(categories: [Game], refreshToken: RefreshToken, onPaginationThresholdMet: (() async -> Void)? = nil) {
        self.categories = categories
        self.refreshToken = refreshToken
        self.onPaginationThresholdMet = onPaginationThresholdMet
    }

    var body: some View {
        LazyVGrid(columns: CategoryGridView.columns, spacing: CategoryGridView.columnSpacing) {
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
