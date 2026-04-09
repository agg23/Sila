//
//  SharedStreamButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/27/24.
//

import SwiftUI
import Twitch

struct SharedStreamButtonView<PreTitleRight: View, ImageOverlay: View, ContextMenu: View>: View {
    @Environment(Router.self) private var router

    let source: StreamableVideo

    let displayUrl: String
    let profileImageUrl: String?

    let preTitleLeft: String
    @ViewBuilder let preTitleRight: () -> PreTitleRight

    let title: String
    let subtitle: String

    let refreshToken: RefreshToken?

    @ViewBuilder let imageOverlay: () -> ImageOverlay
    @ViewBuilder let contextMenu: () -> ContextMenu

    init(source: StreamableVideo, displayUrl: String, profileImageUrl: String?, preTitleLeft: String, title: String, subtitle: String, refreshToken: RefreshToken? = nil, @ViewBuilder preTitleRight: @escaping () -> PreTitleRight, @ViewBuilder imageOverlay: @escaping () -> ImageOverlay, @ViewBuilder contextMenu: @escaping () -> ContextMenu) {
        self.source = source
        self.displayUrl = displayUrl
        self.profileImageUrl = profileImageUrl
        self.preTitleLeft = preTitleLeft
        self.preTitleRight = preTitleRight
        self.title = title
        self.subtitle = subtitle
        self.refreshToken = refreshToken
        self.imageOverlay = imageOverlay
        self.contextMenu = contextMenu
    }

    var body: some View {
        AsyncImageButtonView(imageUrl: buildImageUrl(using: self.displayUrl), aspectRatio: 16.0/9.0, overlayAlignment: .bottomTrailing, refreshToken: self.refreshToken) {
            self.router.pushPlayback(self.source)
        } content: { isFocused in
            VStack(alignment: .leading) {
                #if os(tvOS)
                let titleFont: Font = .system(size: 24)
                let subtitleFont: Font = .system(size: 20)
                #else
                let titleFont: Font = .title3
                let subtitleFont: Font = .subheadline
                #endif

                HStack {
                    Text(self.preTitleLeft)
                        .font(subtitleFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    self.preTitleRight()
                }

                Text(self.title)
                    .font(titleFont)
                    .lineLimit(1)
                Text(self.subtitle)
                    .font(subtitleFont)
                    #if os(tvOS)
                    .foregroundStyle(.secondary)
                    #endif
                    .truncationMode(.tail)
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
//            .padding(16)
//            .background(.quinary.opacity(isFocused ? 1.0 : 0.0), in: .rect(cornerRadius: 20))
//            .padding(.top, isFocused ? 8 : 0)
//            .scaleEffect(isFocused ? 1.02 : 1.0)
//            .animation(.easeInOut(duration: 0.2), value: isFocused)
        } imageOverlay: {
            self.imageOverlay()
        } contextMenu: {
            self.contextMenu()
        }
    }

    func buildImageUrl(using urlString: String) -> URL? {
        // URLs are of the form https://static-cdn.jtvnw.net/previews-ttv/live_user_[USERNAME]-{width}x{height}.jpg
        // Twitch web client uses 440x248, which we replicate to hit the same CDN caches
        // For VoDs Twitch API limits us to 320x180 for these for some reason (this is also what the web UI uses)
        let url = urlString.replacingOccurrences(of: "%{width}", with: "320").replacingOccurrences(of: "%{height}", with: "180")
            // For streams
            .replacingOccurrences(of: "{width}", with: "440").replacingOccurrences(of: "{height}", with: "248")

        return URL(string: url)
    }
}

extension SharedStreamButtonView where PreTitleRight == EmptyView, ImageOverlay == EmptyView, ContextMenu == EmptyView {
    init(source: StreamableVideo, displayUrl: String, profileImageUrl: String?, preTitleLeft: String, title: String, subtitle: String, refreshToken: RefreshToken? = nil) {
        self.source = source
        self.displayUrl = displayUrl
        self.profileImageUrl = profileImageUrl
        self.preTitleLeft = preTitleLeft
        self.title = title
        self.subtitle = subtitle
        self.refreshToken = refreshToken
        self.preTitleRight = {
            EmptyView()
        }
        self.imageOverlay = {
            EmptyView()
        }
        self.contextMenu = {
            EmptyView()
        }
    }
}

#Preview {
    PreviewNavStack {
        SharedStreamButtonView(source: .stream(STREAM_MOCK()), displayUrl: STREAM_MOCK().thumbnailURL, profileImageUrl: CHANNEL_LIST_MOCK()[0].profileImageURL, preTitleLeft: "Pretitle left", title: "Title", subtitle: "Subtitle", refreshToken: nil) {
            Text("Pretitle right")
        } imageOverlay: {
            Text("This is on the image overlay")
        } contextMenu: {
            
        }
        .frame(width: 400, height: 340)
    }
}
