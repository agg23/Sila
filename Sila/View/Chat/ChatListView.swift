//
//  ChatListView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import Combine
import AsyncAnimatedImageUI
import Twitch
import TwitchIRC

struct ChatListView: View {
    @State private var chatModel: ChatModel?

    @State private var toggle = true
    @State private var timer: Timer?

    let channelName: String
    let userId: String
    let isWindow: Bool

    var contentId: String {
        ChatPresentableController.contentId(for: self.userId)
    }

    // Forsen
    let DEBUG_USER_ID = "22484632"

    var body: some View {
        VStack {
            if let chatModel = self.chatModel {
                ChatListContentView(chatModel: chatModel)
            }
        }
        .presentableTracking(contentId: self.contentId, role: self.isWindow ? .standalone : .embedded, factory: {
            ChatPresentableController(contentId: self.contentId, chatModel: ChatRegistry.shared.model(for: channelName, with: userId))
        }) { (controller: ChatPresentableController) in
            self.chatModel = controller.chatModel
        }
        .onActivePhase {
            guard let chatModel = self.chatModel, chatModel.isVisible else {
                return
            }

            Task {
                print("Chat restored active")
                await chatModel.connect()
            }
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

private struct ChatListContentView: View {
    private let scrollViewCoordinateSpace = "scrollViewCoordinateSpace"
    private let bottomRowId = "bottomRow"

    static let rowInset = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    static let dividerInset = EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0)
    static let bottomInset = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    @State private var isTapped = false

    @State private var queuePruneWhenAtBottom = false
    @State private var pendingScrollRequest: UUID? = nil

    @State private var scrollPosition = ScrollPosition(edge: .bottom)
    @State private var isAtBottom = true

    let chatModel: ChatModel

    init(chatModel: ChatModel) {
        self.chatModel = chatModel
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(self.chatModel.entries) { entry in
                    Group {
                        switch entry {
                        case .message(let message):
                            ChatMessageView(message: message, cachedColors: self.chatModel.cachedColors)
                                // TODO: Apply this
                                .listRowInsets(ChatListContentView.rowInset)
                                .padding(.vertical, 2)
                        case .divider(let date):
                            Text("Reconnected at \(TimeFormatter.shared.string(from: date))")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                // TODO: Apply this
                                .listRowInsets(ChatListContentView.dividerInset)
                                // TODO: Implement this
                                .listRowSeparator(.visible)
                        }
                    }
                    // This can't be applied with padding, contentMargins, or safeAreaPadding to the ScrollView/VStack without causing
                    // a horizontal scroll shift when scrolling to bottom
                    .padding(.horizontal, 46)
                }

                Color.clear
                    // As of visionOS 26, a non-zero height is required for onAppear to fire
                    // Use an even count to improve the alignment of the text
                    .frame(height: 2, alignment: .bottom)
                    .onAppear {
                        self.isAtBottom = true
                    }
                    .onDisappear {
                        self.isAtBottom = false
                    }
            }
            .scrollTargetLayout()
        }
        // Even though we shouldn't need an anchor (and it shouldn't do anything when not scrolling to a view), the ScrollView
        // content will end up being vertically centered when it doesn't fill a full view height. Adding an anchor seems to fix that
        .scrollPosition(self.$scrollPosition, anchor: .bottom)
        .overlay(alignment: .bottomTrailing) {
            if self.scrollPosition.edge != .bottom && !self.isAtBottom {
                Button("Scroll to Bottom", systemImage: "arrow.down") {
                    self.scrollToBottom()
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
        .onReceive(self.chatModel.didPrune) { _ in
            self.scrollToBottom()
        }
        .onChange(of: self.chatModel.entries) {
            if self.isAtBottom && self.scrollPosition.edge != .bottom {
                // We can see the bottom detector, but are set to positionedByUser, so let's reset to the bottom scroll lock
                self.scrollToBottom()
            }
        }
    }

    private func scrollToBottom() {
        self.scrollPosition = ScrollPosition(edge: .bottom)
    }
}

#Preview {
    // MoonMoon
    let chatModel = ChatModel(channelName: "foo", userId: "bar")
    chatModel.entries = PRIVATEMESSAGE_LIST_MOCK().map({ .message(ChatMessageModel(message: $0, userId: "121059319")) })
    return NavigationStack {
        ChatListContentView(chatModel: chatModel)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Foo")
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                    } label: {
                        Label("Dismiss", systemImage: Icon.close)
                    }
                    .help("Dismiss")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Label("Pop Out", systemImage: Icon.popOut)
                    }
                    .help("Pop Out")
                }
            }
    }
    .frame(width: 400)
    .glassBackgroundEffect()
}
