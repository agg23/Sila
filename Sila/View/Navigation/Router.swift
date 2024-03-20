//
//  Router.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

@Observable final class Router: Sendable {
    var path: [Route] = []
    var pathBinding: Binding<[Route]> {
        Binding(get: { self.path }, set: { self.path = $0 })
    }

    var bufferedWindowOpen: ExternalWindow?

    func push(route: Route) {
        self.path.append(route)
    }

    func push(window: ExternalWindow) {
        self.bufferedWindowOpen = window
    }
}
