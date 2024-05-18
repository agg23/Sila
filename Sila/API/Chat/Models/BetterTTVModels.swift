//
//  BetterTTVModels.swift
//  Sila
//
//  Created by Adam Gastineau on 5/17/24.
//

import Foundation

struct BetterTTVEmoteSet: Codable {
//    let id: String
//    let bots: [String]
//    let avatar: String
    let channelEmotes: [BetterTTVEmote]
    let sharedEmotes: [BetterTTVEmote]
}

struct BetterTTVEmote: Codable {
    let id: String
    let code: String
    let imageType: String
    let animated: Bool
//    let user: BetterTTVUser
}
