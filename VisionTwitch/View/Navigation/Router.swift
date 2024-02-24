//
//  Router.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

@Observable class Router {
    var path: [Route] = []
    var pathBinding: Binding<[Route]> {
        Binding(get: { self.path }, set: { self.path = $0 })
    }
}

private struct RouterEnvironmentKey: EnvironmentKey {
    static let defaultValue = Router()
}

extension EnvironmentValues {
    var router: Router {
        get { self[RouterEnvironmentKey.self] }
        set { self[RouterEnvironmentKey.self] = newValue }
    }
}
