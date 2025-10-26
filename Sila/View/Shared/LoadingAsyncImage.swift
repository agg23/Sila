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
    let defaultColor: Color

    init(imageUrl: URL?, aspectRatio: CGFloat, defaultColor: Color = Color.clear) {
        self.imageUrl = imageUrl
        self.aspectRatio = aspectRatio
        self.defaultColor = defaultColor
    }

    var body: some View {
        LazyImage(url: self.imageUrl) { state in
            if let image = state.image {
                image
                    .resizable()
            } else if state.error != nil {
                self.defaultColor
            } else {
                Color.clear
                    .overlay {
                        ProgressView()
                    }
            }
        }
        .aspectRatio(self.aspectRatio, contentMode: .fit)
    }
}
