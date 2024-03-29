//
//  SharedStreamButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/27/24.
//

import SwiftUI
import Twitch

enum StreamOrVideo {
    case stream(_: Twitch.Stream)
    case video(_: Video)
}

struct SharedStreamButtonView<PreTitleRight: View, ImageOverlay: View, ContextMenu: View>: View {
    @Environment(Router.self) private var router
    @Environment(\.openWindow) private var openWindow

    let source: StreamOrVideo

    let displayUrl: String

    let preTitleLeft: String
    @ViewBuilder let preTitleRight: () -> PreTitleRight

    let title: String
    let subtitle: String

    @ViewBuilder let imageOverlay: () -> ImageOverlay
    @ViewBuilder let contextMenu: () -> ContextMenu

    init(source: StreamOrVideo, displayUrl: String, preTitleLeft: String, title: String, subtitle: String, @ViewBuilder preTitleRight: @escaping () -> PreTitleRight, @ViewBuilder imageOverlay: @escaping () -> ImageOverlay, @ViewBuilder contextMenu: @escaping () -> ContextMenu) {
        self.source = source
        self.displayUrl = displayUrl
        self.preTitleLeft = preTitleLeft
        self.preTitleRight = preTitleRight
        self.title = title
        self.subtitle = subtitle
        self.imageOverlay = imageOverlay
        self.contextMenu = contextMenu
    }

    var body: some View {
        AsyncImageButtonView(imageUrl: buildImageUrl(using: self.displayUrl), aspectRatio: 16.0/9.0, overlayAlignment: .bottomTrailing) {
            switch self.source {
            case .stream(let stream):
                openWindow(id: "stream", value: stream)
            case .video(let video):
                openWindow(id: "vod", value: video)
            }
        } content: {
            VStack(alignment: .leading) {
                HStack {
                    Text(self.preTitleLeft)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer()

                    self.preTitleRight()
                }

                Text(self.title)
                    .font(.title3)
                    .lineLimit(1)
                Text(self.subtitle)
                    .truncationMode(.tail)
                    .lineLimit(1)
            }
            .frame(minWidth: 0, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
        } imageOverlay: {
            self.imageOverlay()
        } contextMenu: {
            self.contextMenu()
        }
    }

    func buildImageUrl(using urlString: String) -> URL? {
        // For VoDs Twitch API limits us to 320x180 for these for some reason
        let url = urlString.replacingOccurrences(of: "%{width}", with: "320").replacingOccurrences(of: "%{height}", with: "180")
            // For streams
            .replacingOccurrences(of: "{width}", with: "960").replacingOccurrences(of: "{height}", with: "540")

        return URL(string: url)
    }

}

extension SharedStreamButtonView where PreTitleRight == EmptyView, ImageOverlay == EmptyView, ContextMenu == EmptyView {
    init(source: StreamOrVideo, displayUrl: String, preTitleLeft: String, title: String, subtitle: String) {
        self.source = source
        self.displayUrl = displayUrl
        self.preTitleLeft = preTitleLeft
        self.title = title
        self.subtitle = subtitle
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
        SharedStreamButtonView(source: .stream(STREAM_MOCK()), displayUrl: STREAM_MOCK().thumbnailURL, preTitleLeft: "Pretitle left", title: "Title", subtitle: "Subtitle") {
            Text("Pretitle right")
        } imageOverlay: {
            Text("This is on the image overlay")
        } contextMenu: {
            
        }
            .frame(width: 400, height: 340)
    }
}
