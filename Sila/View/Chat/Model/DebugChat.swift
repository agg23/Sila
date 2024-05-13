//
//  DebugChat.swift
//  Sila
//
//  Created by Adam Gastineau on 5/12/24.
//

import Foundation
import TwitchIRC

struct DebugChat {
    static var shared = DebugChat()

    var messages: [PrivateMessage] = []

    mutating func loadAndParseMessages(url: URL) {
        do {
            let data = try Data(contentsOf: url)

            let messages = try JSONDecoder().decode([DebugChatMessage].self, from: data)

            self.messages = messages.map { message in
                var messageString = ""
                var emoteString = ""

                for fragment in message.messages {
                    messageString += fragment.text

                    if let emote = fragment.emote {
                        let splitEmote = emote.id.split(separator: ";")

                        let id = splitEmote[0]
                        let start = splitEmote[1]
                        let end = splitEmote[2]

                        emoteString += "/\(id):\(start)-\(end)"
                    }
                }

                return PrivateMessage(channel: "foo", chatColor: message.color ?? "#FFFFFF", userDisplayName: message.displayName, message: messageString, emotes: emoteString.count > 0 ? emoteString : nil)
            }
        } catch {
            print(error)
        }
    }
}

struct DebugChatMessage: Codable {
    let displayName: String
    let contentOffsetSeconds: Int
    let messages: [DebugChatMessageSubpart]

    /// For some reason this is optional
    let color: String?
}

struct DebugChatMessageSubpart: Codable {
    let text: String
    let emote: DebugChatEmote?
}

struct DebugChatEmote: Codable {
    let id: String
    let emoteID: String
    let from: Int
}
