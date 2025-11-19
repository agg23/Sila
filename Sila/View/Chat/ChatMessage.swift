//
//  AsyncAnimatedImageTextView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/7/24.
//

import SwiftUI
import AsyncAnimatedImageUI
import TwitchIRC

let transparentEmoteImage = makeTransparentImage(size: CGSize(width: 28, height: 28))

func makeTransparentImage(size: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let image = renderer.image { _ in
        // Transparent
    }
    return image
}

struct ChatMessage: View {
    let message: ChatMessageModel
    let cachedColors: CachedColors

    var body: some View {
        let displayName = Text(self.message.message.displayName)
            .foregroundStyle(Color(self.cachedColors.get(hexColor: self.message.message.color)))

        let chunks = self.message.chunks.reduce(Text("")) { existingText, chunk in
            switch chunk {
            case .text(attributed: let attributed, string: let string):
                return Text("\(existingText)\(renderAttributedText(attributed, string: string))")
            case .image(let url):
                let imageText = Text("\(AsyncAnimatedImage(url: url) ?? Image(uiImage: transparentEmoteImage))").baselineOffset(-8.5)
                return Text("\(existingText)\(imageText)")
            }
        }

        Text("\(displayName): \(chunks)")
            // TODO: This drawingGroup probably isn't necessary
            .drawingGroup()
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                AnimatedImageCache.shared.onAppear(for: self.message.emoteURLs)
            }
            .onDisappear {
                AnimatedImageCache.shared.onDisappear(for: self.message.emoteURLs)
            }
    }
}

private func renderAttributedText(_ attributed: AttributedString?, string: String) -> Text {
    guard let attributed = attributed else {
        return Text(string)
    }

    return Text(attributed)
}

#Preview {
    struct PreviewWrapper: View {
        @State var render = false

        // MoonMoon
        let userId = "121059319"

        var body: some View {
            Group {
                if render {
                    VStack(alignment: .leading) {
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO With additional text foo bar test even more text what is going on", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER catKISS", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER catKISS peepoHappy", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "mistermv", chatColor: "#00FF7F", userDisplayName: "missilechion", message: "@Woodster_97 quietER peepoHappy catKISS", emotes: "emotesv2_275e090f79b943c1b081c436e490cdae:13-19"), userId: self.userId), cachedColors: CachedColors())
                        // TODO: This scenario is very broken because of a Twitch bug
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "🇧🇷🇧🇷🇧🇷🇧🇷<3 <3 <3 <3 <3 <3 <3", emotes: "555555584:11-12,14-15,17-18,20-21,23-24,26-27"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "This message has 7TV emotes clap Clap Yoda YODA"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "This message has BTTV emotes gaben GabeN"), userId: self.userId), cachedColors: CachedColors())
                        ChatMessage(message: ChatMessageModel(message: PrivateMessage(channel: "michou", chatColor: "#00FF7F", userDisplayName: "Eretrya0", message: "This message has FFZ emotes zrehplar ZrehplaR"), userId: self.userId), cachedColors: CachedColors())
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
