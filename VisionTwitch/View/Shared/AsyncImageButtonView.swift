//
//  AsyncImageButton.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct AsyncImageButtonView<Content: View>: View {
    let imageUrl: URL?
    let aspectRatio: CGFloat

    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button {
            self.action()
        } label: {
            VStack {
                LoadingAsyncImage(imageUrl: self.imageUrl, aspectRatio: self.aspectRatio)

                self.content()
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(.tertiary)
            .hoverEffect()
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
