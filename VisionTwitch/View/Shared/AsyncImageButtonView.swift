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
    let content: () -> Content

    var body: some View {
        Button {
            self.action()
        } label: {
            VStack {
                AsyncImage(url: self.imageUrl, content: { image in
                    image
                        .resizable()
                }, placeholder: {
                    // Make sure ProgressView is the same size as the final image will be
                    GeometryReader { geometry in
                        ProgressView()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                })
                .aspectRatio(self.aspectRatio, contentMode: .fit)

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
