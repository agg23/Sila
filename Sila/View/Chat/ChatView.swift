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

    let channel: String

    var body: some View {
        VStack {
            ChatListView(messages: self.chatModel.messages, resetScrollPublisher: self.chatModel.resetScrollSubject.eraseToAnyPublisher())
                .task(id: self.toggle) {
                    guard self.toggle else {
                        return
                    }

                    print("Connecting to chat")

                    await self.chatModel.connect(to: self.channel)
                }
        }
    }
}

struct ChatListView: View {
    private let scrollViewCoordinateSpace = "scrollViewCoordinateSpace"

    static let rowInset = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    static let bottomInset = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    @State private var scrollAtBottom = true

    let messages: [ChatMessageModel]
    let resetScrollPublisher: AnyPublisher<(), Never>

    init(messages: [ChatMessageModel], resetScrollPublisher: AnyPublisher<(), Never> = Empty().eraseToAnyPublisher()) {
        self.messages = messages
        self.resetScrollPublisher = resetScrollPublisher
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(self.messages, id: \.message.id) { message in
                    ChatMessage(message: message)
                        // Explicit ID for ScrollViewReader.scrollTo
                        .id(message.message)
                        .listRowInsets(ChatListView.rowInset)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 2)
                        .padding(.horizontal)
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
    ChatListView(messages: PRIVATEMESSAGE_LIST_MOCK().map({ ChatMessageModel(message: $0, cachedColors: CachedColors()) }))
        .frame(width: 400)
}

