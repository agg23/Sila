//
//  ChatModel.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/10/24.
//

import SwiftUI
import Combine
import Twitch
import TwitchIRC

@Observable class ChatModel {
    // These values are arbitrary. We want this to not get too big, and to truncate rarely
    private static let MESSAGE_LIMIT = 5000
    private static let REMOVE_COUNT = 3000

    @ObservationIgnored private let chatClient = ChatClient(.anonymous)
    @ObservationIgnored let resetScrollSubject = PassthroughSubject<(), Never>()
    var messages: [PrivateMessage] = []

    func connect(to channel: String) async {
        do {
            let stream = try await self.chatClient.connect()

            try await self.chatClient.join(to: channel)

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

    private func appendChatMessage(_ message: PrivateMessage) {
        var deleted = false

        if self.messages.count >= ChatModel.MESSAGE_LIMIT {
            self.messages.removeFirst(ChatModel.REMOVE_COUNT)
            print("Removing chat messages")
            deleted = true
        }

        self.messages.append(message)

        if deleted {
            DispatchQueue.main.async {
                self.resetScrollSubject.send(())
            }
        }
    }
}
