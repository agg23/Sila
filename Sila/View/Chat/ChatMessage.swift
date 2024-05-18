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
    let cachedColors: CachedColors

    var body: some View {
        Group {
            Text(self.message.message.displayName)
                .foregroundStyle(Color(self.cachedColors.get(hexColor: self.message.message.color))) +
            Text(": ") +
            self.message.chunks.reduce(Text("")) { existingText, chunk in
                switch chunk {
                case .text(let string):
                    return existingText + Text(string)
                case .image(let url):
                    return existingText + Text("\(AsyncAnimatedImage(url: url))")
                        .baselineOffset(-8.5)
                }
            }
        }
        .drawingGroup()
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
        .onAppear {
            AnimatedImageCache.shared.onAppear(for: self.message.emoteURLs)
        }
        .onDisappear {
            AnimatedImageCache.shared.onDisappear(for: self.message.emoteURLs)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var render = false

        var body: some View {
            Group {
                if render {
                    VStack(alignment: .leading) {
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even more text what is going on", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER catKISS", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER catKISS peepoHappy", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER peepoHappy catKISS", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19")), cachedColors: CachedColors())
                        // TODO: This scenario is very broken because of a Twitch bug
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "🇧🇷🇧🇷🇧🇷🇧🇷<3 <3 <3 <3 <3 <3 <3", emotes: "555555584:11-12,14-15,17-18,20-21,23-24,26-27")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "This message has 7TV emotes clap Clap Yoda YODA")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "This message has BTTV emotes gaben GabeN")), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "This message has FFZ emotes zrehplar ZrehplaR")), cachedColors: CachedColors())
                        Text("With additional text")
                    }
                    .frame(width: 300)
                    .glassBackgroundEffect(in: .rect(cornerRadius: 50), tint: .black.opacity(0.5))
                } else {
                    ProgressView()
                }
            }
            .task {
                // MoonMoon
                await EmoteController.shared.fetchUserEmotes(for: "121059319")

                print("Finished fetch")

                render = true
            }
        }
    }

    return PreviewWrapper()
}
