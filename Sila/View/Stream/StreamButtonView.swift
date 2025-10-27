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

    @State private var initialRenderDate = Date.now

    let stream: Twitch.Stream

    var body: some View {
        if self.disableIncrementingStreamDuration {
            streamButton(current: self.initialRenderDate)
        } else {
            TimelineView(.periodic(from: self.initialRenderDate, by: 1.0)) { context in
                streamButton(current: context.date)
            }
        }
    }

    @ViewBuilder
    func streamButton(current currentDate: Date) -> some View {
        let title = !self.stream.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? self.stream.title : self.stream.userName
        let gameName = !self.stream.gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? self.stream.gameName : "No Category"

        SharedStreamButtonView(source: .stream(self.stream), displayUrl: self.stream.thumbnailURL, preTitleLeft: gameName, title: title, subtitle: self.stream.userName) {
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
                    Text(self.buildRuntimeTimestamp(currentDate))
                        .lineLimit(1)
                }

                Spacer(minLength: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/)

                self.overlayPill {
                    Image(systemName: Icon.viewerCount)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, .white)
                    Text(self.stream.viewerCount.formatted(.number))
                        .lineLimit(1)
                }
            }
        } contextMenu: {
            let channelButton = Button {
                self.router.pushToActiveTab(route: .channel(user: .id(stream.userId)))
            } label: {
                Label("View Channel", systemImage: Icon.channel)
            }

            let categoryButton: Button? = if !stream.gameID.isEmpty {
                // If gameID is the empty string, we have no category
                Button {
                    self.router.pushToActiveTab(route: .category(game: .id(stream.gameID)))
                } label: {
                    Label("More in this Category", systemImage: Icon.category)
                }
            } else {
                nil
            }

            #if VOD_ENABLED
            if let last = self.router.pathForActiveTab().last {
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

            if let last = self.router.pathForActiveTab().last {
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
        .help(title)

    }

    @ViewBuilder
    func overlayPill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack {
            content()
        }
        .padding(5)
        .background(.black.opacity(0.5))
        .clipShape(.rect(cornerRadius: 8))
        .padding(16)
        .monospaced()
    }

    func buildRuntimeTimestamp(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self.stream.startedAt, to: date)

        // Format the time interval as a string
        return RuntimeFormatter.shared.string(from: components) ?? ""
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
}

#Preview {
    PreviewNavStack {
        StreamButtonView(stream: STREAM_MOCK())
            .frame(width: 400, height: 340)
    }
}
