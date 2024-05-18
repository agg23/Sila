//
//  Emote.swift
//  Sila
//
//  Created by Adam Gastineau on 4/15/24.
//

import Foundation

struct Emote {
    let name: String

    let imageUrl: URL

    let source: EmoteSource

    func isHigherPriority(than source: EmoteSource) -> Bool {
        self.source.rawValue > source.rawValue
    }
}

enum EmoteSource: Int {
    case sevenTV = 2
    case betterTTV = 1
    case frankerFaceZ = 0
}
