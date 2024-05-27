//
//  FrankerFaceZModels.swift
//  Sila
//
//  Created by Adam Gastineau on 5/18/24.
//

import Foundation

struct FrankerFaceZGlobalEmotes: Codable {
    let defaultSets: [Int]
    let sets: [String: FrankerFaceZEmoteSet]
//    let users: [FrankerFaceZUser]

    enum CodingKeys: String, CodingKey {
        case defaultSets = "default_sets"
        case sets
    }
}

struct FrankerFaceZRooms: Codable {
    let room: FrankerFaceZRoom
    let sets: [String: FrankerFaceZEmoteSet]
}

struct FrankerFaceZRoom: Codable {
    // Many other properties
    let set: Int
}

struct FrankerFaceZEmoteSet: Codable {
//    let id: Int
//    let _type: Int
//    let icon: String
//    let title: String
//    let description: String
//    let css: String
    let emoticons: [FrankerFaceZEmote]
}

struct FrankerFaceZEmote: Codable {
//    let id: String
    let name: String
//    let height: Int
//    let width: Int
//    let public: Bool
//    let hidden: Bool
//    let modifier: Bool
//    let modifierFlags: Int
//    ... many other properties
    let urls: [String: String]
    let animated: [String: String]?
}
