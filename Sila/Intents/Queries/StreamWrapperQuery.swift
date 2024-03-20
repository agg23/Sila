//
//  StreamWrapperQuery.swift
//  Sila
//
//  Created by Adam Gastineau on 3/19/24.
//

import AppIntents
import Twitch

struct StreamWrapperQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [StreamWrapperEntity] {
        return []
    }
}
