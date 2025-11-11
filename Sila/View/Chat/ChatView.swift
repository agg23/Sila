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
    @State private var chatModel: ChatModel?

    @State private var toggle = true
    @State private var timer: Timer?

    let channelName: String
    let userId: String

    var contentId: String {
        "chat-\(self.userId)"
    }

    // Forsen
    let DEBUG_USER_ID = "22484632"

    var body: some View {
        VStack {
            if let chatModel = self.chatModel {
                ChatListView(chatModel: chatModel)
            }
        }
        .presentableTracking(contentId: self.contentId, factory: {
            return ChatPresentableController(contentId: self.contentId, chatModel: ChatRegistry.shared.model(for: channelName, with: userId))
        }) { (controller: ChatPresentableController) in
            self.chatModel = controller.chatModel
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

    func fireDebugTimer(index: Int) {
        let messages = DebugChat.shared.messages
        var newIndex = index

        if newIndex >= messages.count {
            newIndex = 0
        }

        let message = messages[newIndex]

        self.chatModel?.appendChatMessage(message, userId: DEBUG_USER_ID)

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
            self.fireDebugTimer(index: newIndex + 1)
        }
    }
}

struct ChatListView: View {
    private let scrollViewCoordinateSpace = "scrollViewCoordinateSpace"
    private let bottomRowId = "bottomRow"

    static let rowInset = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    static let dividerInset = EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0)
    static let bottomInset = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    @State private var isTapped = false

    @State private var scrollAtBottom = true
    @State private var queuePruneWhenAtBottom = false
    @State private var pendingScrollRequest: UUID? = nil

    let chatModel: ChatModel

    init(chatModel: ChatModel) {
        self.chatModel = chatModel
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(self.chatModel.entries) { entry in
                    switch entry {
                    case .message(let message):
                        ChatMessage(message: message, cachedColors: self.chatModel.cachedColors)
                            .listRowInsets(ChatListView.rowInset)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 2)
                    case .divider(let date):
                        Text("Reconnected at \(TimeFormatter.shared.string(from: date))")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .listRowInsets(ChatListView.dividerInset)
                            // Use list separator at the bottom of the row as a psuedo-Divider
                            .listRowSeparator(.visible)
                    }
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
                        if !self.scrollAtBottom {
                            self.scrollAtBottom = true
                            #if DEBUG
                            print("At bottom")
                            #endif
                        }

                        self.chatModel.pruneChatMessagesOverLimit()
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
            .onReceive(self.chatModel.queuePruneWhenAtBottom) { _ in
                // Automatically scroll to bottom with the message list update
                self.queueScrollToBottom(proxy)
            }
            .onChange(of: self.chatModel.entries, { _, newValue in
                // If we are currently at the bottom and we have any change to the messages array (new message, clearing of old data), scroll to the new bottom
                guard self.scrollAtBottom else {
                    return
                }

                self.queueScrollToBottom(proxy)
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
    let chatModel = ChatModel(channelName: "foo", userId: "bar")
    chatModel.entries = PRIVATEMESSAGE_LIST_MOCK().map({ .message(ChatMessageModel(message: $0, userId: "121059319")) })
    return ChatListView(chatModel: chatModel)
        .frame(width: 400)
        .glassBackgroundEffect()
}
