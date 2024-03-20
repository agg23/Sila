//
//  FollowerEntity.swift
//  Sila
//
//  Created by Adam Gastineau on 3/18/24.
//

import AppIntents

// TODO: Unused
struct ChannelEntity: AppEntity {
    static var defaultQuery = ChannelQuery()

    let id: String
    let loginName: String

    @Property(title: "Channel Display Name")
    var displayName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Channel")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: self.displayName))
    }

    // You have to have a memberwise initializer to correctly assign to @Property
    init(id: String, loginName: String, displayName: String) {
        self.id = id
        self.loginName = loginName
        self.displayName = displayName
    }
}
