//
//  ChatMessageView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import TwitchIRC
import MarkdownUI

struct ChatMessageView: View {
    let message: PrivateMessage

    let content: MarkdownContent

    init(message: PrivateMessage) {
        self.message = message
        var emotes = message.parseEmotes()

        var segments: [InlineNode] = []

        let messageString = message.message

        var previousMinIndex = String.Index(utf16Offset: 0, in: messageString)
        
        // Sometimes emotes can be out of order
        emotes.sort { a, b in
            a.startIndex < b.startIndex
        }

        for emote in emotes {
            let endIndex = String.Index(utf16Offset: emote.startIndex, in: messageString)

            segments.append(.text(String(messageString[previousMinIndex..<endIndex])))
            segments.append(.image(source: emoteUrl(from: emote.id), children: []))

            if emote.isAnimated {
                print(emoteUrl(from: emote.id))
            }

            previousMinIndex = String.Index(utf16Offset: emote.endIndex, in: messageString)
        }

        // Add final segment
        segments.append(.text(String(messageString[previousMinIndex..<messageString.endIndex])))

        self.content = MarkdownContent(block: .paragraph(content: segments))
    }

    var body: some View {
        Text(attachViews(using: self.message))
//        Markdown(self.content)
//            .markdownImageProvider(.normalWebImage)
//            .markdownInlineImageProvider(.webImage)
    }
}

func emoteUrl(from id: String) -> String {
    "https://static-cdn.jtvnw.net/emoticons/v2/\(id)/default/light/1.0"
}

#Preview {
    ChatMessageView(message: PrivateMessage(channel: "foo", chatColor: "blue", userDisplayName: "agg23", message: "This is a test", emotes: "28087:0-6"))
}
