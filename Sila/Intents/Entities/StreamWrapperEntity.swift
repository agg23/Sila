//
//  StreamWrapperEntity.swift
//  Sila
//
//  Created by Adam Gastineau on 3/19/24.
//

import AppIntents
import Twitch

// Should never be exposed to users
struct StreamWrapperEntity: AppEntity {
    static var defaultQuery = StreamWrapperQuery()

    let stream: Twitch.Stream

    var id: String {
        get {
            self.stream.id
        }
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Stream")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: self.stream.userName))
    }
}

extension Twitch.Stream: @unchecked Sendable {}
