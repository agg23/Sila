//
//  Stream.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import Foundation
import Twitch

extension Twitch.Stream: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine("stream\(self.id)")
    }

    public static func == (lhs: Twitch.Stream, rhs: Twitch.Stream) -> Bool {
        lhs.id == rhs.id
    }
}
