//
//  AsyncAnimatedImageTextView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/7/24.
//

import SwiftUI
import AsyncAnimatedImageUI
import TwitchIRC

struct ChatMessage: View {
    let message: PrivateMessage

    var body: some View {
        Group {
            Text(self.message.displayName)
                .foregroundStyle(Color(UIColor.hexStringToUIColor(hex: self.message.color))) + Text(": ") +
            self.buildChunks(from: self.message).reduce(Text("")) { existingText, chunk in
                switch chunk {
                case .text(let string):
                    return existingText + Text(string)
                case .image(let url):
                    return existingText + Text("\(AsyncAnimatedImage(url: url))")
                        .baselineOffset(-8.5)
                }
            }
        }
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
    }

    enum AnimatedMessageChunk {
        case text(String)
        case image(URL)
    }

    private func buildChunks(from message: PrivateMessage) -> [AnimatedMessageChunk] {
        let string = message.message

        var chunks: [AnimatedMessageChunk] = []

        var startIndex = String.Index(utf16Offset: 0, in: string)

        var emotes = message.parseEmotes()

        // Sometimes emotes can be out of order
        emotes.sort { a, b in
            a.startIndex < b.startIndex
        }

        for emote in emotes {
            let prefixString = string[startIndex..<string.index(string.startIndex, offsetBy: emote.startIndex)]
            chunks.append(.text(String(prefixString)))

            chunks.append(.image(self.emoteUrl(from: emote.id)))

            startIndex = string.index(string.startIndex, offsetBy: emote.endIndex + 1)
        }

        if (startIndex.utf16Offset(in: string) != string.count) {
            let prefixString = string[startIndex..<string.endIndex]
            chunks.append(.text(String(prefixString)))
        }

        return chunks
    }

    private func emoteUrl(from id: String) -> URL {
        URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/dark/1.0")!
    }
}

#Preview {
    VStack(alignment: .leading) {
        ChatMessage(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"))
        ChatMessage(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"))
        ChatMessage(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"))
        ChatMessage(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even more text what is going on", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"))
        ChatMessage(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER catKISS", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19"))
        Text("With additional text")
    }
    .frame(width: 300)
    .glassBackgroundEffect(in: .rect(cornerRadius: 50), tint: .black.opacity(0.5))
}
