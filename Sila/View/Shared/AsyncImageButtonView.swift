//
//  AsyncImageButton.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct AsyncImageButtonView<Content: View, ImageOverlay: View, ContextMenu: View>: View {
    private var cornerRadius: Double {
        #if os(macOS)
        10.0
        #elseif os(tvOS)
        40.0
        #else
        20.0
        #endif
    }

    let imageUrl: URL?
    let aspectRatio: CGFloat

    let action: () -> Void
    @ViewBuilder let content: (_ isFocused: Bool) -> Content
    @ViewBuilder let imageOverlay: (() -> ImageOverlay)?
    @ViewBuilder let contextMenu: (() -> ContextMenu)?
    let overlayAlignment: Alignment?
    let refreshToken: RefreshToken?

    init(imageUrl: URL? = nil, aspectRatio: CGFloat, overlayAlignment: Alignment? = nil, refreshToken: RefreshToken? = nil, action: @escaping () -> Void, content: @escaping (_ isFocused: Bool) -> Content, imageOverlay: @escaping () -> ImageOverlay, contextMenu: @escaping () -> ContextMenu) {
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
                    #if os(tvOS)
                    .hoverEffect(.highlight)
                    #endif

                FocusProvider { isFocused in
                    let horizontalPadding = 16.0

                    self.content(isFocused)
                        #if os(tvOS)
                        .padding(.top, 8)
                        #endif
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, 8)
                        #if os(tvOS)
                        // Expanded image takes ~8px on each side. Decrease corner radius based on that
                        .background(.quinary.opacity(isFocused ? 1.0 : 0.0), in: .rect(cornerRadius: self.cornerRadius / 2))
                        .padding(.top, isFocused ? 12 : 0)
                        .scaleEffect(isFocused ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isFocused)
                        #endif
                }
            }
            #if !os(tvOS)
            .background(.tertiary)
            #endif
            #if !os(macOS)
            // Without this (matching the corner radius), the context menu corners will not match
            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: self.cornerRadius))
            #endif
        }
        #if os(tvOS)
        .buttonStyle(.borderless)
        #else
        .buttonBorderShape(.roundedRectangle(radius: self.cornerRadius))
        .buttonStyle(StreamButtonStyle(radius: self.cornerRadius))
        #endif
        .contextMenu {
            self.contextMenu?()
        }
    }
}

extension AsyncImageButtonView where ImageOverlay == EmptyView {
    init(imageUrl: URL? = nil, aspectRatio: CGFloat, refreshToken: RefreshToken? = nil, action: @escaping () -> Void, content: @escaping (_ isFocused: Bool) -> Content, contextMenu: @escaping () -> ContextMenu) {
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
    init(imageUrl: URL? = nil, aspectRatio: CGFloat, refreshToken: RefreshToken? = nil, action: @escaping () -> Void, content: @escaping (_ isFocused: Bool) -> Content) {
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

 private struct FocusProvider<Content: View>: View {
     @Environment(\.isFocused) private var isFocused

     @ViewBuilder let content: (_ isFocused: Bool) -> Content

     var body: some View {
         content(isFocused)
     }
 }
