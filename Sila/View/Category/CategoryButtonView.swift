//
//  CategoryButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct CategoryButtonView: View {
    @Environment(Router.self) private var router

    let category: Twitch.Game
    let refreshToken: RefreshToken

    var body: some View {
        AsyncImageButtonView(imageUrl: buildImageUrl(using: self.category), aspectRatio: 0.75, refreshToken: self.refreshToken) {
            self.router.pushToActiveTab(route: .category(game: GameWrapper.game(self.category)))
        } content: {
            VStack(alignment: .leading) {
                Text(self.category.name)
                    .font(.title3)
                    .lineLimit(1, reservesSpace: true)
            }
        }
        .help(category.name)
    }

    func buildImageUrl(using category: Twitch.Game) -> URL? {
        // URL of the form https://static-cdn.jtvnw.net/ttv-boxart/[IMDB GAME ID?]-{width}x{height}.jpg
        // Twitch web client uses 285x380 on the Browse/Directory screen, which we replicate to hit the same CDN caches
        let url = category.boxArtUrl.replacingOccurrences(of: "{width}", with: "285").replacingOccurrences(of: "{height}", with: "380")

        return URL(string: url)
    }
}

#Preview {
    CategoryButtonView(category: CATEGORY_MOCK(), refreshToken: UUID())
}
