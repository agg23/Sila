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

    @ObservationIgnored let channelName: String
    // Used to track the third party emotes relevant to this model
    @ObservationIgnored let userId: String

    @ObservationIgnored private var chatClient: ChatClient? = nil
    @ObservationIgnored let resetScrollSubject = PassthroughSubject<(), Never>()
    @ObservationIgnored let cachedColors = CachedColors()
    var entries: [ChatLogEntryModel]

    init(channelName: String, userId: String) {
        self.channelName = channelName
        self.userId = userId
        self.entries = []
    }

    func connect() async {
        let client = ChatClient(.anonymous)
        self.chatClient = client

        await withTaskCancellationHandler {
            do {
                let stream = try await client.connect()

                try await client.join(to: self.channelName)

                for try await message in stream {
                    // Close connection
                    if Task.isCancelled {
                        print("Chat disconnect")
                        client.disconnect()
                        return
                    }

                    switch message {
                    case .privateMessage(let message):
                        await self.appendChatMessage(message, userId: self.userId)
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
            self.disconnect()
        }
    }

    func disconnect() {
        self.chatClient?.disconnect()

        var insertDivider = true

        if let last = self.entries.last {
            if case .divider(_) = last {
                // We already have a divider
                insertDivider = false
            }
        } else {
            // We have no messages
            insertDivider = false
        }

        if insertDivider {
            self.entries.append(ChatLogEntryModel.divider(Date.now))
        }
    }

    @MainActor
    func appendChatMessage(_ message: PrivateMessage, userId: String) {
        var deleted = false

        if self.entries.count >= ChatModel.MESSAGE_LIMIT {
            print("Removing chat messages")
            self.entries.removeFirst(ChatModel.REMOVE_COUNT)
            deleted = true
        }

        self.entries.append(.message(ChatMessageModel(message: message, userId: userId)))

        if deleted {
            self.resetScrollSubject.send(())
        }
    }
}
