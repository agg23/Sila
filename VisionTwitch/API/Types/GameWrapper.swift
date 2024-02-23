//
//  GameWrapper.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import Foundation
import Twitch

enum GameWrapper {
    case game(_ game: Game)
    case id(_ id: String)
}

extension GameWrapper: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .game(let game):
            hasher.combine("game")
            hasher.combine(game.id)
        case .id(let id):
            hasher.combine("id")
            hasher.combine(id)
        }
    }

    static func == (lhs: GameWrapper, rhs: GameWrapper) -> Bool {
        switch (lhs, rhs) {
        case (.game(let leftGame), .game(let rightGame)):
            return leftGame.id == rightGame.id
        case (.id(let leftId), .id(let rightId)):
            return leftId == rightId
        default:
            return false
        }
    }
}

