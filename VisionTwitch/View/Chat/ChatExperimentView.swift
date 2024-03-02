//
//  ChatExperimentView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import Twitch
import TwitchIRC

struct ChatExperimentView: View {
    @State var chatClient = ChatClient(.anonymous)
    @State var sliderValue: Double = 400.0
    @State var messages: [String] = []
    @State var scrollAtBottom = false

    let channel: String

    var body: some View {
//        Markdown {
//            Paragraph {
//                "Text"
//                InlineImage(source: URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/86/static/light/1.0")!)
//                "This is more text"
//                "This is text continuing on for a long time, accompanied by"
//                InlineImage(source: URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/86/static/light/1.0")!)
//                "another inline image. This text keeps going and going and going and going and going"
//                InlineImage(source: URL(string: "https://static-cdn.jtvnw.net/emoticons/v2/86/static/light/1.0")!)
//                "until another image occurs."
//            }
//        }
//        .frame(width: self.sliderValue)
//        .markdownImageProvider(.normalWebImage)
//        .markdownInlineImageProvider(.webImage)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack {
                    ForEach(self.messages, id: \.self) { message in
                        Text(message)
                    }

                    Color.clear
                        .frame(width: 0, height: 0, alignment: .bottom)
                        .onAppear {
                            self.scrollAtBottom = true
                        }
                        .onDisappear {
                            self.scrollAtBottom = false
                        }
                }
            }
            .onChange(of: self.messages.last ?? "", { _, newValue in
                guard self.scrollAtBottom else {
                    return
                }

                proxy.scrollTo(newValue)
            })
            .onAppear {
                proxy.scrollTo(self.messages.last)
            }
        }

        Slider(value: self.$sliderValue, in: 0.0...400.0)
            .task {
//                do {
//                    let stream = try await self.chatClient.connect()
//
//                    try await self.chatClient.join(to: self.channel)
//
//                    for try await message in stream {
//                        switch message {
//                        case .privateMessage(let message):
//                            self.appendChatMessage(message.message)
//                        default:
//                            break
//                        }
//                    }
//                } catch {
//                    print("Chat error")
//                    print(error)
//                }
                var count = 0;
                while (true) {
                    do {
                        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
                    } catch {

                    }
                    self.appendChatMessage("Message \(count)")
                    count += 1
                }
            }
    }

    func appendChatMessage(_ message: String) {
        if messages.count == 100 {
            messages.removeFirst()
        }

        messages.append(message)
    }
}

#Preview {
    ChatExperimentView(channel: "barbarousking")
}
