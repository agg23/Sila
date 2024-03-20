//
//  StreamButtonView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI
import Twitch

struct StreamButtonView: View {
    @AppStorage(Setting.disableIncrementingStreamDuration) var disableIncrementingStreamDuration: Bool = false

    @Environment(Router.self) private var router
    @Environment(StreamTimer.self) private var streamTimer

    @State private var currentDate = Date.now

    let stream: Twitch.Stream

    var body: some View {
        SharedStreamButtonView(source: .stream(self.stream), displayUrl: self.stream.thumbnailURL, preTitleLeft: self.stream.gameName, title: self.stream.title, subtitle: self.stream.userName) {
            if self.stream.isMature {
                Text("Mature")
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 2)
                    .background(.red)
                    .clipShape(.rect(cornerRadius: 4))
            }
        } imageOverlay: {
            HStack {
                self.overlayPill {
                    Text(self.buildRuntime())
                }

                Spacer()

                self.overlayPill {
                    Image(systemName: Icon.viewerCount)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, .white)
                    Text(self.stream.viewerCount.formatted(.number))
                }
            }
        } contextMenu: {
            let channelButton = Button {
                self.router.path.append(Route.channel(user: .id(stream.userId)))
            } label: {
                Label("View Channel", systemImage: Icon.channel)
            }

            let categoryButton = Button {
                self.router.path.append(Route.category(game: .id(stream.gameID)))
            } label: {
                Label("More in this Category", systemImage: Icon.category)
            }

            #if VOD_ENABLED
            if let last = self.router.path.last {
                switch last {
                case .channel:
                    // We're in a channel view, we're already looking at this channel
                    EmptyView()
                default:
                    channelButton
                }
            } else {
                channelButton
            }
            #endif

            if let last = self.router.path.last {
                switch last {
                case .category:
                    // We're in a category view, we're already looking at this category
                    EmptyView()
                default:
                    categoryButton
                }
            } else {
                categoryButton
            }
        }
        .onReceive(self.streamTimer.secondTimer, perform: { date in
            guard !self.disableIncrementingStreamDuration else {
                return
            }

            self.currentDate = date
        })
    }

    @ViewBuilder
    func overlayPill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack {
            content()
        }
        .padding(4)
        .background(.black.opacity(0.5))
        .clipShape(.rect(cornerRadius: 8))
        .padding(16)
        .monospaced()
    }

    func buildRuntime() -> String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self.stream.startedAt, to: self.currentDate)

        // Create a date components formatter
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional

        // Format the time interval as a string
        return formatter.string(from: components) ?? ""
    }

//    @ViewBuilder
//    func tagList(_ list: [String]) -> some View {
//        // TODO: Unused
//        HStack {
//            ForEach(list, id: \.self) { tag in
//                TagView(text: tag)
//            }
//        }
//    }

    func buildImageUrl(using stream: Twitch.Stream) -> URL? {
        let url = stream.thumbnailURL.replacingOccurrences(of: "{width}", with: "960").replacingOccurrences(of: "{height}", with: "540")

        return URL(string: url)
    }
}

#Preview {
    PreviewNavStack {
        StreamButtonView(stream: STREAM_MOCK())
            .frame(width: 400, height: 340)
    }
    .environment(StreamTimer())
}
