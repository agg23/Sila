//
//  LoadingAsyncImage.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/23/24.
//

import SwiftUI

struct LoadingAsyncImage: View {
    let imageUrl: URL?
    let aspectRatio: CGFloat

    var body: some View {
        AsyncImage(url: self.imageUrl, content: { image in
            image
                .resizable()
        }, placeholder: {
            // Make sure ProgressView is the same size as the final image will be
            ZStack {
                Color.clear
                ProgressView()
            }
        })
        .aspectRatio(self.aspectRatio, contentMode: .fit)
    }
}
