//
//  Router.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

enum SelectedTab {
    case following
    case popular
    case categories
    case search
    case settings
}

@Observable final class Router: Sendable {
    var tab: SelectedTab = .following
    var path: [SelectedTab: [Route]] = [:]

    var tabBinding: Binding<SelectedTab> {
        Binding(get: { self.tab }, set: { self.tab = $0 })
    }

    var bufferedWindowOpen: ExternalWindow?

    func pathForActiveTab() -> [Route] {
        self.path(for: self.tab)
    }

    func path(for tab: SelectedTab) -> [Route] {
        if let path = self.path[tab] {
            return path
        } else {
            let array: [Route] = []
            self.path[tab] = array
            return array
        }
    }

    func pathBinding(for tab: SelectedTab) -> Binding<[Route]> {
        return Binding(get: { self.path(for: tab) }, set: { self.path[tab] = $0 })
    }

    func pushToActiveTab(route: Route) {
        // Make sure path exists
        let _ = self.path(for: self.tab)

        self.path[self.tab]?.append(route)
    }

    func push(window: ExternalWindow) {
        self.bufferedWindowOpen = window
    }
}
