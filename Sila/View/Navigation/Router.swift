//
//  Router.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

enum SelectedTab: Equatable, Codable {
    case following
    case popular
    case categories
    case search
    case settings
}

@Observable final class Router: Equatable, Codable, Sendable {
    var tab: SelectedTab = .following
    var path: [SelectedTab: [Route]] = [:]

    var tabBinding: Binding<SelectedTab> {
        Binding(get: { self.tab }, set: { self.tab = $0 })
    }

    var bufferedWindowOpen: StreamableVideo?
    var activeVideo: StreamableVideo?

    init() {

    }

    init(from router: Router) {
        self.tab = router.tab
        self.path = self.path

        self.bufferedWindowOpen = router.bufferedWindowOpen
        self.activeVideo = router.activeVideo
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.tab = try values.decode(SelectedTab.self, forKey: .tab)
        // We only need the current tab when serializing
        let tabPath = try values.decode([Route].self, forKey: .path)
        self.path = [self.tab: tabPath]

        self.bufferedWindowOpen = try values.decode(Optional<StreamableVideo>.self, forKey: .bufferedWindowOpen)
        self.activeVideo = try values.decode(Optional<StreamableVideo>.self, forKey: .activeVideo)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.tab, forKey: .tab)
        try container.encode(self.pathForActiveTab(), forKey: .path)
        try container.encode(self.bufferedWindowOpen, forKey: .bufferedWindowOpen)
        try container.encode(self.activeVideo, forKey: .activeVideo)
    }

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

    func bufferOpenWindow(_ video: StreamableVideo) {
        self.bufferedWindowOpen = video
    }

    static func == (lhs: Router, rhs: Router) -> Bool {
        if lhs.tab != rhs.tab {
            return false
        }
        if lhs.path != rhs.path {
            return false
        }
        if lhs.bufferedWindowOpen != rhs.bufferedWindowOpen {
            return false
        }
        if lhs.activeVideo != rhs.activeVideo {
            return false
        }

        return true
    }

    enum CodingKeys: String, CodingKey {
        case tab
        case path
        case bufferedWindowOpen
        case activeVideo
    }
}
