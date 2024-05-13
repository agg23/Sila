//
//  SevenTVModels.swift
//  Sila
//
//  Created by Adam Gastineau on 4/15/24.
//

import Foundation

struct SevenTVUser: Codable {
//    let id: String
//    let platform: String
//
//    let username: String
//    let display_name: String
//    let linked_at: Int
//    let emote_capacity: Int
//    let emote_set_id: ?
    let emoteSet: SevenTVEmoteSet

    enum CodingKeys: String, CodingKey {
        case emoteSet = "emote_set"
    }
}

struct SevenTVGlobalEmotes: Codable {
    let emotes: [SevenTVEmote]
}

struct SevenTVEmoteSet: Codable {
    let id: String
    let name: String

    let emotes: [SevenTVEmote]
}

struct SevenTVEmote: Codable {
    let id: String
    let name: String

    let flags: Int
    let timestamp: Int

//    let actorId: String

    let data: SevenTVEmoteData

    struct SevenTVEmoteData: Codable {
        let id: String
        let name: String

        let flags: Int
        let lifecycle: Int

        let host: SevenTVEmoteHost
    }

    struct SevenTVEmoteHost: Codable {
        let url: String

        let files: [SevenTVFile]
    }

    struct SevenTVFile: Codable {
        let name: String
        let staticName: String

        let width: Int
        let height: Int

        let frameCount: Int
        let size: Int

        let format: String

        enum CodingKeys: String, CodingKey {
            case name
            case staticName = "static_name"

            case width
            case height

            case frameCount = "frame_count"
            case size

            case format
        }
    }
}
