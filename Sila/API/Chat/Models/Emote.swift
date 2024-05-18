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
    case sevenTV = 1
    case betterTTV = 0
}
