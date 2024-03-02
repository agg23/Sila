//
//  ChatView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import Twitch
import TwitchIRC

struct ChatView: View {
    @State private var chatClient = ChatClient(.anonymous)
    @State private var messages: [PrivateMessage] = []

    let channel: String
    let limit: Int

    init(channel: String, limit: Int = 100) {
        self.channel = channel
        self.limit = limit
    }

    var body: some View {
        VStack {
            ChatMessageListView(messages: self.messages)
                .task {
                    do {
                        let stream = try await self.chatClient.connect()

                        try await self.chatClient.join(to: self.channel)

                        for try await message in stream {
                            // Close connection
                            if Task.isCancelled {
                                self.chatClient.disconnect()
                                return
                            }

                            switch message {
                            case .privateMessage(let message):
                                self.appendChatMessage(message)
                            default:
                                break
                            }
                        }
                    } catch {
                        print("Chat error")
                        print(error)
                    }
                }
        }
    }

    func appendChatMessage(_ message: PrivateMessage) {
        if self.messages.count == self.limit {
            self.messages.removeFirst()
        }

        self.messages.append(message)
    }
}
