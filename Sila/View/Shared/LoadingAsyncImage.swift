//
//  LoadingAsyncImage.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/23/24.
//

import SwiftUI
import NukeUI

struct LoadingAsyncImage: View {
    let imageUrl: URL?
    let aspectRatio: CGFloat

    var body: some View {
        LazyImage(url: self.imageUrl) { state in
            if let image = state.image {
                image
                    .resizable()
            } else {
                Color.clear
                    .background(.background)
            }
        }
        .aspectRatio(self.aspectRatio, contentMode: .fit)
    }
}
