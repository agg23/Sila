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
        PrivateMessage(channel: "barbarousking", chatColor: "green", userDisplayName: "jerry", message: "Hi @joesmoe. You're dumb"),
        PrivateMessage(channel: "barbarousking", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO claraqDISCO claraqDISCO This is some text preceeded by a dancing dog", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,36-46,48-58"),
        PrivateMessage(channel: "barbarousking", chatColor: "#1E90FF", userDisplayName: "damasenpai", message: "claraqDISCO claraqDISCO claraqDISCO placeholder Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam quis urna ac diam molestie lacinia vel eu augue. claraqDISCO Fusce sit amet ex eget turpis scelerisque ultrices quis id felis. Etiam ultricies urna eget turpis eleifend venenatis.", emotes: "emotesv2_b01874d1da9f479aa49df41c48164233:0-10,12-22,24-34,160-170"),
        PrivateMessage(channel: "MoonMoon", chatColor: "#8A2BE2", userDisplayName: "NitemareLuna69", message: "vinePipe", emotes: "emotesv2_ca7f76bd4dc14654b82be09954608660:0-7")
    ]
}
