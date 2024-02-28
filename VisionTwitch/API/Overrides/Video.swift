//
//  Video.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/27/24.
//

import Foundation
import Twitch

extension Twitch.Video: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine("video\(self.id)")
    }

    public static func == (lhs: Twitch.Video, rhs: Twitch.Video) -> Bool {
        lhs.id == rhs.id
    }
}
