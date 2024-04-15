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
    let message: ChatMessageModel

    var body: some View {
        self.message.view
        .drawingGroup()
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
        .onAppear {
            AnimatedImageCache.shared.onAppear(for: self.message.emoteURLs)
        }
        .onDisappear {
            AnimatedImageCache.shared.onDisappear(for: self.message.emoteURLs)
        }
    }

    @Observable class CachedColors {
        @ObservationIgnored private var colors: [String: UIColor] = [:]

        func get(hexColor string: String) -> UIColor {
            if let color = self.colors[string] {
                return color
            }

            let newColor = UIColor.hexStringToUIColor(hex: string)
            self.colors[string] = newColor

            return newColor
        }
    }

    enum AnimatedMessageChunk {
        case text(String)
        case image(URL)
    }
}

#Preview {
    VStack(alignment: .leading) {
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), cachedColors: CachedColors()))
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), cachedColors: CachedColors()))
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), cachedColors: CachedColors()))
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even more text what is going on", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), cachedColors: CachedColors()))
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER catKISS", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19"), cachedColors: CachedColors()))
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER catKISS peepoHappy", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19"), cachedColors: CachedColors()))
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER peepoHappy catKISS", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19"), cachedColors: CachedColors()))
        // TODO: This scenario is very broken because of a Twitch bug
        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "🇧🇷🇧🇷🇧🇷🇧🇷<3 <3 <3 <3 <3 <3 <3", emotes: "555555584:11-12,14-15,17-18,20-21,23-24,26-27"), cachedColors: CachedColors()))
        Text("With additional text")
    }
    .frame(width: 300)
    .glassBackgroundEffect(in: .rect(cornerRadius: 50), tint: .black.opacity(0.5))
}
