//
//  PrivateMessage.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import TwitchIRC

extension PrivateMessage {
    init(channel: String, chatColor: String, userDisplayName: String, message: String, emotes: String? = nil) {
        self.init()

        self.channel = channel
        self.displayName = userDisplayName
        self.message = message
        self.color = chatColor
        self.emotes = emotes ?? ""
    }
}

extension PrivateMessage: Identifiable {}

extension PrivateMessage: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    public static func == (lhs: PrivateMessage, rhs: PrivateMessage) -> Bool {
        lhs.id == rhs.id
    }
}
