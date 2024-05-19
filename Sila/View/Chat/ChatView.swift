//
//  ChatView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import Combine
import AsyncAnimatedImageUI
import Twitch
import TwitchIRC

struct ChatView: View {
    @State private var chatModel = ChatModel()

    @State private var toggle = true
    @State private var timer: Timer?

    let channel: String
    let userId: String

    var body: some View {
        VStack {
            ChatListView(messages: self.chatModel.messages, cachedColors: self.chatModel.cachedColors, resetScrollPublisher: self.chatModel.resetScrollSubject.eraseToAnyPublisher())
                .task(id: self.toggle) {
                    guard self.toggle else {
                        return
                    }

                    print("Connecting to chat")

                    await self.chatModel.connect(to: self.channel, for: self.userId)
                }
//                .task {
//                    // MoonMoon
//                    await EmoteController.shared.fetchUserEmotes(for: "121059319")
//
//                    DebugChat.shared.loadAndParseMessages(url: URL(fileURLWithPath: "/Users/adam/code/Swift/VisionTwitch/util/vod-comment-grabber/comments.json"))
//
////                    for i in 0..<100 {
////                        let message = DebugChat.shared.messages[i]
////                        self.chatModel.appendChatMessage(message)
////                    }
//
//                    fireDebugTimer(index: 0)
//                }
        }
    }

    func fireDebugTimer(index: Int) {
        let messages = DebugChat.shared.messages
        var newIndex = index

        if newIndex >= messages.count {
            newIndex = 0
        }

        let message = messages[newIndex]

        Task {
            await self.chatModel.appendChatMessage(message, userId: "121059319")
        }

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            self.fireDebugTimer(index: newIndex + 1)
        }
    }
}

struct ChatListView: View {
    private let scrollViewCoordinateSpace = "scrollViewCoordinateSpace"

    static let rowInset = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    static let bottomInset = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    @State private var scrollAtBottom = true

    let messages: [ChatMessageModel]
    let cachedColors: CachedColors
    let resetScrollPublisher: AnyPublisher<(), Never>

    init(messages: [ChatMessageModel], cachedColors: CachedColors, resetScrollPublisher: AnyPublisher<(), Never> = Empty().eraseToAnyPublisher()) {
        self.messages = messages
        self.cachedColors = cachedColors
        self.resetScrollPublisher = resetScrollPublisher
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(self.messages, id: \.message.id) { message in
                    ChatMessage(message: message, cachedColors: self.cachedColors)
                        // Explicit ID for ScrollViewReader.scrollTo
                        .id(message.message)
                        .listRowInsets(ChatListView.rowInset)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 2)
                }

                Color.clear
                    .frame(width: 0, height: 0, alignment: .bottom)
                    .listRowInsets(ChatListView.bottomInset)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        self.scrollAtBottom = true
                        print("At bottom")
                    }
            }
            .environment(\.defaultMinListRowHeight, 0)
            .listRowSpacing(0)
            .listStyle(.plain)
            .overlay(alignment: .bottomTrailing) {
                if !self.scrollAtBottom {
                    Button("Scroll to Bottom", systemImage: "arrow.down") {
                        withAnimation {
                            if let last = self.messages.last {
                                proxy.scrollTo(last.message, anchor: .init(x: 0, y: 0))
                            }
                        }
                    }
                    .buttonBorderShape(.circle)
                    .labelStyle(.iconOnly)
                    .padding(20)
                }
            }
            .gesture(DragGesture().onChanged({ event in
                if event.translation.height > 10 {
                    withAnimation {
                        self.scrollAtBottom = false
                    }
                }
            }))
            .onDisappear {
                // Clear all active emotes
                AnimatedImageCache.shared.flush()
            }
            .onChange(of: self.messages.last, { _, newValue in
                guard self.scrollAtBottom else {
                    return
                }

                proxy.scrollTo(newValue?.message, anchor: .init(x: 0, y: 0))
            })
            .onReceive(self.resetScrollPublisher) { _ in
                if let last = self.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.message, anchor: .init(x: 0, y: 0))
                    }
                }
            }
        }
    }
}

#Preview {
    // MoonMoon
    ChatListView(messages: PRIVATEMESSAGE_LIST_MOCK().map({ ChatMessageModel(message: $0, userId: "121059319") }), cachedColors: CachedColors())
        .frame(width: 400)
        .glassBackgroundEffect()
}

