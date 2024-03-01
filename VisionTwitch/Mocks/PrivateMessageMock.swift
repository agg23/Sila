//
//  PrivateMessageMock.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/29/24.
//

import TwitchIRC

func PRIVATEMESSAGE_LIST_MOCK() -> [PrivateMessage] {
    return [
        PrivateMessage(channel: "barbarousking", chatColor: "blue", userDisplayName: "joesmoe", message: "Hello world"),
        PrivateMessage(channel: "barbarousking", chatColor: "blue", userDisplayName: "joesmoe", message: "This is another message"),
        PrivateMessage(channel: "barbarousking", chatColor: "green", userDisplayName: "jerry", message: "Hi @joesmoe. You're dumb")
    ]
}
