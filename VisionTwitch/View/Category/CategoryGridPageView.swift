//
//  CategoryGridPageView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryGridPageView: View {
    let categories: [Twitch.Game]

    var body: some View {
        ScrollView {
            CategoryGridView(categories: self.categories)
                .padding(.all, 32)
        }
    }
}

#Preview {
    CategoryGridPageView(categories: CATEGORY_LIST_MOCK())
}
