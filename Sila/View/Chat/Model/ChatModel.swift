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

struct Connection {
    let chatClient: TwitchIRCClient
    let task: Task<(), Never>
}

@Observable class ChatModel {
    // These values are arbitrary. We want this to not get too big, and to truncate rarely
    // With larger values, the List slows down significantly, so lets keep this small
    private static let MESSAGE_LIMIT = 400
    private static let REMOVE_COUNT = 300

    @ObservationIgnored let channelName: String
    // Used to track the third party emotes relevant to this model
    @ObservationIgnored let userId: String

    @ObservationIgnored let didPrune = PassthroughSubject<(), Never>()
    @ObservationIgnored let cachedColors = CachedColors()

    @ObservationIgnored private var connection: Connection? = nil

    var entries: [ChatLogEntryModel] = []

    init(channelName: String, userId: String) {
        self.channelName = channelName
        self.userId = userId
    }

    func connect() async {
        if let connection = self.connection {
            if !connection.task.isCancelled {
                print("Attempted connection when IRC already opened")
                return
            }
        }

        print("Opening IRC connection")
        guard let client = try? await TwitchIRCClient(.anonymous, urlSession: URLSession.shared) else {
            print("Could not create IRC client")
            return
        }

        let task = Task {
            do {
                let stream = await client.stream()
                try await client.join(to: self.channelName)

                for try await message in stream {
                    // Close connection
                    if Task.isCancelled {
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
        }

        self.connection = Connection(chatClient: client, task: task)

        await withTaskCancellationHandler {
            await self.connection?.task.value
        } onCancel: {
            self.disconnect()
        }
    }

    func disconnect() {
        guard let connection = self.connection else {
            return
        }

        print("Chat disconnect")
        connection.task.cancel()
        Task {
            try? await connection.chatClient.part(from: self.channelName)
        }
        self.connection = nil

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
        if self.entries.count >= ChatModel.MESSAGE_LIMIT {
            print("Removing chat messages")
            self.entries.removeFirst(ChatModel.REMOVE_COUNT)
            self.didPrune.send(())
        }

        self.entries.append(.message(ChatMessageModel(message: message, userId: userId)))
    }
}
