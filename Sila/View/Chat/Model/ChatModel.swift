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
    // With larger values, the List slows down significantly, so lets keep this small
    private static let MESSAGE_LIMIT = 400
    private static let REMOVE_COUNT = 300

    @ObservationIgnored private let chatClient = ChatClient(.anonymous)
    @ObservationIgnored let resetScrollSubject = PassthroughSubject<(), Never>()
    @ObservationIgnored let cachedColors = CachedColors()
    var messages: [ChatMessageModel] = []

    func connect(to channel: String, for userId: String) async {
        await withTaskCancellationHandler {
            do {
                let stream = try await self.chatClient.connect()

                try await self.chatClient.join(to: channel)

                for try await message in stream {
                    // Close connection
                    if Task.isCancelled {
                        print("Chat disconnect")
                        self.chatClient.disconnect()
                        return
                    }

                    switch message {
                    case .privateMessage(let message):
                        await self.appendChatMessage(message, userId: userId)
                    default:
                        break
                    }
                }
            } catch {
                print("Chat error")
                print(error)
            }
        } onCancel: {
            print("Chat disconnect")
            self.chatClient.disconnect()
        }
    }

    func disconnect() {
        self.chatClient.disconnect()
    }

    @MainActor
    func appendChatMessage(_ message: PrivateMessage, userId: String) {
        var deleted = false

        if self.messages.count >= ChatModel.MESSAGE_LIMIT {
            print("Removing chat messages")
            self.messages.removeFirst(ChatModel.REMOVE_COUNT)
            deleted = true
        }

        self.messages.append(ChatMessageModel(message: message, userId: userId))

        if deleted {
            self.resetScrollSubject.send(())
        }
    }
}
