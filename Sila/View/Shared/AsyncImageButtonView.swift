//
//  AsyncImageButton.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct AsyncImageButtonView<Content: View, ImageOverlay: View, ContextMenu: View>: View {
    private let cornerRadius = 20.0

    let imageUrl: URL?
    let aspectRatio: CGFloat

    let action: () -> Void
    @ViewBuilder let content: () -> Content
    @ViewBuilder let imageOverlay: (() -> ImageOverlay)?
    @ViewBuilder let contextMenu: (() -> ContextMenu)?
    let overlayAlignment: Alignment?
    let refreshToken: RefreshToken?

    init(imageUrl: URL? = nil, aspectRatio: CGFloat, overlayAlignment: Alignment? = nil, refreshToken: RefreshToken? = nil, action: @escaping () -> Void, content: @escaping () -> Content, imageOverlay: @escaping () -> ImageOverlay, contextMenu: @escaping () -> ContextMenu) {
        self.imageUrl = imageUrl
        self.aspectRatio = aspectRatio
        self.action = action
        self.content = content
        self.imageOverlay = imageOverlay
        self.contextMenu = contextMenu
        self.overlayAlignment = overlayAlignment
        self.refreshToken = refreshToken
    }

    var body: some View {
        Button {
            self.action()
        } label: {
            VStack {
                LoadingAsyncImage(imageUrl: self.imageUrl, aspectRatio: self.aspectRatio, refreshToken: self.refreshToken)
                    .overlay(alignment: self.overlayAlignment ?? .center) {
                        self.imageOverlay?()
                    }

                self.content()
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(.tertiary)
            // Without this (matching the corner radius), the context menu corners will not match
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: self.cornerRadius))
        }
        .buttonBorderShape(.roundedRectangle(radius: self.cornerRadius))
        .buttonStyle(StreamButtonStyle(radius: self.cornerRadius))
        .contextMenu {
            self.contextMenu?()
        }
    }
}

extension AsyncImageButtonView where ImageOverlay == EmptyView {
    init(imageUrl: URL? = nil, aspectRatio: CGFloat, refreshToken: RefreshToken? = nil, action: @escaping () -> Void, content: @escaping () -> Content, contextMenu: @escaping () -> ContextMenu) {
        self.imageUrl = imageUrl
        self.aspectRatio = aspectRatio
        self.action = action
        self.content = content
        self.imageOverlay = {
            EmptyView()
        }
        self.contextMenu = contextMenu
        self.overlayAlignment = nil
        self.refreshToken = refreshToken
    }
}

extension AsyncImageButtonView where ImageOverlay == EmptyView, ContextMenu == EmptyView {
    init(imageUrl: URL? = nil, aspectRatio: CGFloat, refreshToken: RefreshToken? = nil, action: @escaping () -> Void, content: @escaping () -> Content) {
        self.imageUrl = imageUrl
        self.aspectRatio = aspectRatio
        self.action = action
        self.content = content
        self.imageOverlay = {
            EmptyView()
        }
        self.contextMenu = {
            EmptyView()
        }
        self.overlayAlignment = nil
        self.refreshToken = refreshToken
    }
}
