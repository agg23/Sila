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

struct SharedStreamButtonView<ImageOverlay: View>: View {
    @Environment(Router.self) private var router
    @Environment(\.openWindow) private var openWindow

    let source: StreamOrVideo

    let displayUrl: String

    let preTitleLeft: String
    let preTitleRight: String

    let title: String
    let subtitle: String

    @ViewBuilder let imageOverlay: (() -> ImageOverlay)?

    init(source: StreamOrVideo, displayUrl: String, preTitleLeft: String, preTitleRight: String, title: String, subtitle: String, imageOverlay: @escaping () -> ImageOverlay) {
        self.source = source
        self.displayUrl = displayUrl
        self.preTitleLeft = preTitleLeft
        self.preTitleRight = preTitleRight
        self.title = title
        self.subtitle = subtitle
        self.imageOverlay = imageOverlay
    }

    var body: some View {
        AsyncImageButtonView(imageUrl: buildImageUrl(using: self.displayUrl), aspectRatio: 16.0/9.0, overlayAlignment: .bottomTrailing) {
            switch self.source {
            case .stream(let stream):
                openWindow(id: "channelVideo", value: stream)
            case .video(let video):
                openWindow(id: "channelVideo", value: video)
            }
        } content: {
            VStack(alignment: .leading) {
                HStack {
                    Text(self.preTitleLeft)
                    Spacer()
                    Text(self.preTitleRight)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

                Text(self.title)
                    .font(.title3)
                    .lineLimit(1)
                Text(self.subtitle)
                    .truncationMode(.tail)
                    .lineLimit(1)
            }
        } imageOverlay: {
            self.imageOverlay?()
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

extension SharedStreamButtonView where ImageOverlay == EmptyView {
    init(source: StreamOrVideo, displayUrl: String, preTitleLeft: String, preTitleRight: String, title: String, subtitle: String) {
        self.source = source
        self.displayUrl = displayUrl
        self.preTitleLeft = preTitleLeft
        self.preTitleRight = preTitleRight
        self.title = title
        self.subtitle = subtitle
        self.imageOverlay = {
            EmptyView()
        }
    }
}


#Preview {
    NavStack {
        SharedStreamButtonView(source: .stream(STREAM_MOCK()), displayUrl: STREAM_MOCK().thumbnailURL, preTitleLeft: "Pretitle left", preTitleRight: "Pretitle right", title: "Title", subtitle: "Subtitle", imageOverlay: {
            Text("This is on the image overlay")
        })
            .frame(width: 400, height: 300)
    }
}
