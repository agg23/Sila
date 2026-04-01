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

    init() {

    }

    init(from router: Router) {
        self.tab = router.tab
        self.path = router.path

        self.bufferedWindowOpen = router.bufferedWindowOpen
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.tab = try values.decode(SelectedTab.self, forKey: .tab)
        // We only need the current tab when serializing
        let tabPath = try values.decode([Route].self, forKey: .path)
        self.path = [self.tab: tabPath]

        self.bufferedWindowOpen = try values.decode(Optional<StreamableVideo>.self, forKey: .bufferedWindowOpen)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.tab, forKey: .tab)
        try container.encode(self.pathForActiveTab(), forKey: .path)
        try container.encode(self.bufferedWindowOpen, forKey: .bufferedWindowOpen)
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
        self.push(route: route, in: self.tab)
    }

    func push(route: Route, in tab: SelectedTab) {
        // Make sure path exists
        let _ = self.path(for: tab)

        self.path[tab]?.append(route)
    }

    func activePlaybackVideo(in tab: SelectedTab) -> StreamableVideo? {
        self.path(for: tab).last?.playbackVideo
    }

    func pushPlayback(_ video: StreamableVideo, in tab: SelectedTab? = nil) {
        let targetTab = tab ?? self.tab
        self.dismissPlayback(in: targetTab)
        self.push(route: .playback(video: video), in: targetTab)
    }

    func dismissPlayback(in tab: SelectedTab? = nil) {
        let targetTab = tab ?? self.tab
        guard let index = self.path(for: targetTab).lastIndex(where: { $0.isPlayback }) else {
            return
        }

        self.path[targetTab]?.removeSubrange(index...)
    }

    func hasPlayback(in tab: SelectedTab? = nil) -> Bool {
        self.activePlaybackVideo(in: tab ?? self.tab) != nil
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

        return true
    }

    enum CodingKeys: String, CodingKey {
        case tab
        case path
        case bufferedWindowOpen
    }
}
