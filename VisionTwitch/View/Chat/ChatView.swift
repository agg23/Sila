//
//  ChatView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import SwiftUI
import Twitch
import TwitchIRC

struct ChatView: View {
    @State private var chatClient = ChatClient(.anonymous)
    @State private var messages: [PrivateMessage] = []

    @State private var disconnect = false

    let channel: String
    let limit: Int

    init(channel: String, limit: Int = 100) {
        self.channel = channel
        self.limit = limit
    }

    var body: some View {
        VStack {
            ChatMessageListView(messages: self.messages)
                .task {
                    do {
                        let stream = try await self.chatClient.connect()

                        try await self.chatClient.join(to: self.channel)

                        for try await message in stream {
                            if disconnect {
                                self.chatClient.disconnect()

                                return
                            }
                            switch message {
                            case .privateMessage(let message):
                                self.appendChatMessage(message)
                            default:
                                break
                            }
                        }
                    } catch {
                        print("Chat error")
                        print(error)
                    }
                }
            HStack {
                Button {
                    self.disconnect = true

                    // PrivateMessage(channel: "mistermv", message: "Achète dit elle avec le t-shirt dans une mains et une batte dans l\'autre adfaceGASM adfaceGASM adfaceGASM adfaceGASM adfaceGASM", badgeInfo: [], badges: [], bits: "", color: "#1E90FF", displayName: "schr0dingertv", userLogin: "schr0dingertv", emotes: "emotesv2_bb87ae7570774ec4b78d4f296239b832:73-82,84-93,95-104,106-115,117-126", emoteOnly: false, flags: [], firstMessage: false, returningChatter: false, messageId: "", id: "d8867f73-730c-4dca-8a12-9cb56c6eca85", crowdChantParentMessageId: "", customRewardId: "", roomId: "28575692", tmiSentTs: 1709393098759, clientNonce: "dc6a25b8bd9e626482ba975910cc72e8", userId: "80581157", replyParent: TwitchIRC.PrivateMessage.ReplyParent(displayName: "", userLogin: "", message: "", id: "", userId: ""), replyThreadParent: TwitchIRC.PrivateMessage.ReplyThreadParent(userLogin: "", messageId: "", displayName: "", userId: ""), pinnedChat: TwitchIRC.PrivateMessage.PinnedChat(amount: 0, canonicalAmount: 0, currency: "", exponent: 0, isSystemMessage: false, level: ""), parsingLeftOvers: TwitchIRC.ParsingLeftOvers(unusedPairs: [], unavailableKeys: [], unparsedKeys: []))


                    self.messages.append(.init(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "schr0dingertv", message: "Achète dit elle avec le t-shirt dans une mains et une batte dans l\'autre adfaceGASM adfaceGASM adfaceGASM adfaceGASM adfaceGASM", emotes: "emotesv2_bb87ae7570774ec4b78d4f296239b832:73-82,84-93,95-104,106-115,117-126"))
                } label: {
                    Text("Add animated")
                }
                Button {
                    self.disconnect = true

                    self.messages.append(.init(channel: "mistermv", chatColor: "#1E90FF", userDisplayName: "schr0dingertv", message: "Hello world"))
                } label: {
                    Text("Add static")
                }
            }
        }
    }

    func appendChatMessage(_ message: PrivateMessage) {
        if self.messages.count == self.limit {
            self.messages.removeFirst()
        }

        self.messages.append(message)
    }
}
