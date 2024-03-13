//
//  AsyncImageButton.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct AsyncImageButtonView<Content: View, ImageOverlay: View>: View {
    let imageUrl: URL?
    let aspectRatio: CGFloat

    let action: () -> Void
    @ViewBuilder let content: () -> Content
    @ViewBuilder let imageOverlay: (() -> ImageOverlay)?
    let overlayAlignment: Alignment?

    init(imageUrl: URL? = nil, aspectRatio: CGFloat, overlayAlignment: Alignment? = nil, action: @escaping () -> Void, content: @escaping () -> Content, imageOverlay: @escaping () -> ImageOverlay) {
        self.imageUrl = imageUrl
        self.aspectRatio = aspectRatio
        self.action = action
        self.content = content
        self.imageOverlay = imageOverlay
        self.overlayAlignment = overlayAlignment
    }

    var body: some View {
        Button {
            self.action()
        } label: {
            VStack {
                LoadingAsyncImage(imageUrl: self.imageUrl, aspectRatio: self.aspectRatio)
                    .overlay(alignment: self.overlayAlignment ?? .center) {
                        self.imageOverlay?()
                    }

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

extension AsyncImageButtonView where ImageOverlay == EmptyView {
    init(imageUrl: URL? = nil, aspectRatio: CGFloat, action: @escaping () -> Void, content: @escaping () -> Content) {
        self.imageUrl = imageUrl
        self.aspectRatio = aspectRatio
        self.action = action
        self.content = content
        self.imageOverlay = {
            EmptyView()
        }
        self.overlayAlignment = nil
    }
}
