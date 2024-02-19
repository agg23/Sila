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

    var body: some View {
        LazyVGrid(columns: [
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem(),
            GridItem()
        ], content: {
            ForEach(self.categories, id: \.id) { category in
                CategoryButtonView(category: category)
            }
        })
    }
}

#Preview {
    CategoryGridView(categories: CATEGORY_LIST_MOCK())
}
