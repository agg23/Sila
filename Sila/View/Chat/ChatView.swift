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

    // Forsen
    let DEBUG_USER_ID = "22484632"

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
//                    await EmoteController.shared.fetchUserEmotes(for: DEBUG_USER_ID)
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

        self.chatModel.appendChatMessage(message, userId: DEBUG_USER_ID)

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            self.fireDebugTimer(index: newIndex + 1)
        }
    }
}

struct ChatListView: View {
    private let scrollViewCoordinateSpace = "scrollViewCoordinateSpace"
    private let bottomRowId = "bottomRow"

    static let rowInset = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    static let bottomInset = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    @State private var isTapped = false

    @State private var scrollAtBottom = true
    @State private var pendingScrollRequest: UUID? = nil

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
                        .listRowInsets(ChatListView.rowInset)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 2)
                }

                Color.clear
                    // As of visionOS 26, a non-zero height is required for onAppear to fire
                    // Use an even count to improve the alignment of the text
                    .frame(height: 2, alignment: .bottom)
                    .listRowInsets(ChatListView.bottomInset)
                    .listRowSeparator(.hidden)
                    // Explicit ID for scrollToBottom()
                    .id(bottomRowId)
                    .onAppear {
                        if (!self.scrollAtBottom) {
                            self.scrollAtBottom = true
                            print("At bottom")
                        }
                    }
            }
            .environment(\.defaultMinListRowHeight, 0)
            .listRowSpacing(0)
            .listStyle(.plain)
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { event in
                    // If we manually scroll, mark us as no longer auto-scrolling to the bottom
                    if event.translation.height > 10 {
                        self.scrollAtBottom = false
                    }

                    // Set the entire ListView as tapped. This will prevent auto scrolling period while the user is holding
                    self.isTapped = true
                }
                .onEnded { _ in
                    self.isTapped = false
                })
            // Must be on top of gesture listener
            .overlay(alignment: .bottomTrailing) {
                if !self.scrollAtBottom {
                    Button("Scroll to Bottom", systemImage: "arrow.down") {
                        queueScrollToBottom(proxy)
                    }
                    .buttonBorderShape(.circle)
                    .labelStyle(.iconOnly)
                    .padding(20)
                }
            }
            .onDisappear {
                // Clear all active emotes
                AnimatedImageCache.shared.flush()
            }
            .onReceive(self.resetScrollPublisher) { _ in
                // Automatically scroll to bottom with the message list update
                print("Received reset")
                self.scrollAtBottom = true
            }
            .onChange(of: self.messages, { _, newValue in
                // If we are currently at the bottom and we have any change to the messages array (new message, clearing of old data), scroll to the new bottom
                guard self.scrollAtBottom else {
                    return
                }

                queueScrollToBottom(proxy)
            })
        }
    }

    private func queueScrollToBottom(_ proxy: ScrollViewProxy) {
        if (self.isTapped) {
            return
        }

        // Force this execution to occur after the main actor processes finish the render tick
        // TODO: This whole thing may be overcomplicated
        Task { @MainActor in
            if (self.isTapped) {
                return
            }

            let taskToken = UUID()
            self.pendingScrollRequest = taskToken
            // Process any deferred tasks (unsure if this is necessary)
            await Task.yield()

            if (self.isTapped) {
                return
            }

            // If we're not the active task, halt
            guard self.pendingScrollRequest == taskToken else { return }
            self.pendingScrollRequest = nil
            // Force scrollAtBottom now so any future changes will auto scroll regardless of SwiftUI's visibility state
            self.scrollAtBottom = true
            proxy.scrollTo(bottomRowId, anchor: .bottom)
        }
    }
}

#Preview {
    // MoonMoon
    ChatListView(messages: PRIVATEMESSAGE_LIST_MOCK().map({ ChatMessageModel(message: $0, userId: "121059319") }), cachedColors: CachedColors())
        .frame(width: 400)
        .glassBackgroundEffect()
}
