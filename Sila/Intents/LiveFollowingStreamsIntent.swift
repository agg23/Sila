//
//  LiveFollowingStreamsIntent.swift
//  Sila
//
//  Created by Adam Gastineau on 3/19/24.
//

import AppIntents

struct LiveFollowingStreamsIntent: AppIntent {
    @Dependency private var authController: AuthController

    static var title: LocalizedStringResource = "Live Followed Channels"

    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let api = try AuthShortcut.getAPI(self.authController)

        guard self.authController.isAuthorized() else {
            throw IntentError.message("Please log in to view live following channels.")
        }

        let (followedChannels, _) = try await api.getFollowedStreams(limit: 100)

        return .result(value: followedChannels.sorted(by: { a, b in
            a.viewerCount > b.viewerCount
        }).map({ $0.userLogin }))
    }
}
