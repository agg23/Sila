//
//  OpenStreamIntent.swift
//  Sila
//
//  Created by Adam Gastineau on 3/18/24.
//

import AppIntents

struct OpenStreamIntent: AppIntent {
    @Dependency private var authController: AuthController
    @Dependency private var router: Router

    static var title: LocalizedStringResource = "Open Stream"

    @Parameter(
        title: "Channel",
        description: "The channel to open",
        requestValueDialog: IntentDialog("What channel do you wish to view?")
    )
    var channel: ChannelEntity

    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let api = try AuthShortcut.getAPI(self.authController)

        let (streams, _) = try await api.getStreams(userLogins: [self.channel.loginName])

        guard streams.count > 0 else {
            throw IntentError.message("Channel \(self.channel.displayName) is not live.")
        }

        let stream = streams[0]
        self.router.push(window: .stream(stream))

        return .result()
    }

}
