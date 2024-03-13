//
//  ChatView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import Combine
import Twitch
import TwitchIRC

struct ChatView: View {
    @State private var chatModel = ChatModel()

    let channel: String

    var body: some View {
        ChatListView(messages: self.chatModel.messages, resetScrollPublisher: self.chatModel.resetScrollSubject.eraseToAnyPublisher())
            .task {
                await self.chatModel.connect(to: self.channel)
            }
    }
}

struct ChatListView: View {
    private let scrollViewCoordinateSpace = "scrollViewCoordinateSpace"

    static let rowInset = EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
    static let bottomInset = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

    @State private var scrollAtBottom = true

    let messages: [PrivateMessage]
    let resetScrollPublisher: AnyPublisher<(), Never>

    init(messages: [PrivateMessage], resetScrollPublisher: AnyPublisher<(), Never> = Empty().eraseToAnyPublisher()) {
        self.messages = messages
        self.resetScrollPublisher = resetScrollPublisher
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(self.messages) { message in
                    ChatMessage(message: message)
                        .id(message)
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
                                proxy.scrollTo(last, anchor: .init(x: 0, y: 0))
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
            .onChange(of: self.messages.last ?? PrivateMessage(), { _, newValue in
                guard self.scrollAtBottom else {
                    return
                }

                proxy.scrollTo(newValue, anchor: .init(x: 0, y: 0))
            })
            .onReceive(self.resetScrollPublisher) { _ in
                if let last = self.messages.last {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .init(x: 0, y: 0))
                    }
                }
            }
        }
    }
}

#Preview {
    ChatListView(messages: PRIVATEMESSAGE_LIST_MOCK())
        .frame(width: 400)
}

