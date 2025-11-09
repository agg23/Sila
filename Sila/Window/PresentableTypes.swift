//
//  PresentableTypes.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Foundation
import SwiftUI

/// Role for a presenter
enum PresentationRole: Hashable {
    case embedded
    case standalone
    case custom(String)
}

/// Token representing a presenter registration
struct PresenterToken: Hashable {
    let id: UUID
    let role: PresentationRole

    init(id: UUID = UUID(), role: PresentationRole) {
        self.id = id
        self.role = role
    }
}
