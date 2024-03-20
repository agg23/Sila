//
//  PopularStreamsIntent.swift
//  Sila
//
//  Created by Adam Gastineau on 3/19/24.
//

import AppIntents

struct PopularStreamsIntent: AppIntent {
    @Dependency private var authController: AuthController

    static var title: LocalizedStringResource = "Most Popular Streams"

    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let api = try AuthShortcut.getAPI(self.authController)

        let (streams, _) = try await api.getStreams(limit: 100)

        return .result(value: streams.map({ $0.userLogin }))
    }
}
