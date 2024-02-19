//
//  CategoryButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryButtonView: View {
    @Environment(\.router) private var router

    let category: Twitch.Game

    var body: some View {
        AsyncImageButton(imageUrl: buildImageUrl(using: self.category), aspectRatio: 0.75) {
            router.path.append(GameWrapper(game: self.category))
        } content: {
            VStack(alignment: .leading) {
                Text(self.category.name)
                    .font(.title3)
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }

    func buildImageUrl(using category: Twitch.Game) -> URL? {
        let url = category.boxArtUrl.replacingOccurrences(of: "{width}", with: "750").replacingOccurrences(of: "{height}", with: "1000")

        return URL(string: url)
    }
}

#Preview {
    CategoryButtonView(category: CATEGORY_MOCK())
}
