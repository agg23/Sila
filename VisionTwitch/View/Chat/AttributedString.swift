//
//  AttributedString.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/1/24.
//

import UIKit
import TwitchIRC

func attachViews(using message: PrivateMessage) -> AttributedString {
    var string = AttributedString(stringLiteral: message.message)

    let emotes = message.parseEmotes()

    let previousMinIndex = attributedIndex(string, string: message.message, index: 0)
    for emote in emotes {
        let imageString = buildImageString(emote)

        let startIndex = attributedIndex(string, string: message.message, index: emote.startIndex)
        let endIndex = attributedIndex(string, string: message.message, index: emote.endIndex)
        string.replaceSubrange(startIndex..<endIndex, with: imageString)
    }

    return string
}

func attributedIndex(_ attributedString: AttributedString, string: String, index: Int) -> AttributedString.Index {
    AttributedString.Index(String.Index(utf16Offset: index, in: string), within: attributedString)!
}

func buildImageString(_ emote: Emote) -> AttributedString {
    let textAttachment = NSTextAttachment(image: UIImage(systemName: "square.and.arrow.up")!)
    let attachmentString = AttributedString("\(UnicodeScalar(NSTextAttachment.character)!)", attributes: AttributeContainer().attachment(textAttachment))

    return attachmentString
}
