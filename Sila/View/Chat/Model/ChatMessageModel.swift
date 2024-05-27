//
//  ChatMessageModel.swift
//  Sila
//
//  Created by Adam Gastineau on 3/16/24.
//

import SwiftUI
import AsyncAnimatedImageUI
import TwitchIRC

class ChatMessageModel {
    let message: PrivateMessage
    let emoteURLs: [URL]
    let chunks: [AnimatedMessageChunk]

    init(message: PrivateMessage, userId: String) {
        self.message = message

        let (chunks, emoteURLs) = buildChunks(from: self.message, userId: userId)

        self.chunks = chunks
        self.emoteURLs = emoteURLs
    }
}

extension ChatMessageModel: Equatable {
    static func == (lhs: ChatMessageModel, rhs: ChatMessageModel) -> Bool {
        lhs.message == rhs.message
    }
}

enum AnimatedMessageChunk {
    case text(String)
    case image(URL)
}

private func buildChunks(from message: PrivateMessage, userId: String) -> ([AnimatedMessageChunk], [URL]) {
    let string = message.message

    var chunks: [AnimatedMessageChunk] = []
    var emoteUrls: [URL] = []

    var startIndex = String.Index(utf16Offset: 0, in: string)

    var emotes = message.parseEmotes()

    // Sometimes emotes can be out of order
    emotes.sort { a, b in
        a.startIndex < b.startIndex
    }

    for emote in emotes {
        // We enforce that we can't go out of range on the string, in case Twitch gives us invalid ranges
        // See https://github.com/twitchdev/issues/issues/104
        let emoteStartIndex = string.index(string.startIndex, offsetBy: emote.startIndex, limitedBy: string.endIndex) ?? startIndex

        let url = twitchEmoteUrl(from: emote.id)

        extractEmoteSection(string: string, startIndex: startIndex, emoteStartIndex: emoteStartIndex, emoteUrl: url, chunks: &chunks, emoteUrls: &emoteUrls)
        startIndex = string.index(string.startIndex, offsetBy: emote.endIndex + 1, limitedBy: string.endIndex) ?? string.endIndex

        print("Logging Twitch \(emote.name)")
    }

    // Final segment
    if (startIndex.utf16Offset(in: string) != string.count) {
        let prefixString = string[startIndex..<string.endIndex]
        chunks.append(.text(String(prefixString)))
    }

    chunks = chunks.flatMap { chunk in
        if case .text(let string) = chunk {
            // String chunk
            let splitString = string.split(separator: /\s+/)

            var innerChunks: [AnimatedMessageChunk] = []
            var startIndex = String.Index(utf16Offset: 0, in: string)

            for substring in splitString {
                if let emote = EmoteController.shared.getEmote(named: String(substring), for: userId) {
                    // Get previous chunk
                    extractEmoteSection(string: string, startIndex: startIndex, emoteStartIndex: substring.startIndex, emoteUrl: emote.imageUrl, chunks: &innerChunks, emoteUrls: &emoteUrls)

                    startIndex = substring.endIndex
                }
            }

            if !innerChunks.isEmpty {
                // Replace this chunk with innerChunks
                // Final segment
                if (startIndex.utf16Offset(in: string) != string.count) {
                    let prefixString = string[startIndex..<string.endIndex]
                    innerChunks.append(.text(String(prefixString)))
                }

                return innerChunks
            }
        }

        return [chunk]
    }

    return (chunks, emoteUrls)
}

private func extractEmoteSection(string: String, startIndex: String.Index, emoteStartIndex: String.Index, emoteUrl: URL, chunks: inout [AnimatedMessageChunk], emoteUrls: inout [URL]) {
    let prefixString = string[startIndex..<emoteStartIndex]

    if prefixString.count > 0 {
        chunks.append(.text(String(prefixString)))
    }

    chunks.append(.image(emoteUrl))
    emoteUrls.append(emoteUrl)
}

private func twitchEmoteUrl(from id: String) -> URL {
    URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/dark/1.0")!
}
