//
//  UserWrapper.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import Foundation
import Twitch

struct UserWrapper: Hashable {
    let user: Twitch.User

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.user.id)
    }

    static func == (lhs: UserWrapper, rhs: UserWrapper) -> Bool {
        lhs.user.id == rhs.user.id
    }
}
