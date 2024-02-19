//
//  GameWrapper.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import Foundation
import Twitch

struct GameWrapper: Hashable {
    let game: Twitch.Game

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.game.id)
    }

    static func == (lhs: GameWrapper, rhs: GameWrapper) -> Bool {
        lhs.game.id == rhs.game.id
    }
}
