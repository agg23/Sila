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
            } else if state.error != nil {
                // TODO: Show error
            } else {
                ZStack {
                    Color.clear
                    ProgressView()
                }
            }
        }
        .aspectRatio(self.aspectRatio, contentMode: .fit)
    }
}
