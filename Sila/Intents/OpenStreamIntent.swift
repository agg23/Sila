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

    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @Parameter(
        title: "Channel",
        description: "The channel to open",
        requestValueDialog: IntentDialog("What channel do you wish to view?")
    )
    var channel: String

    @MainActor
    func perform() async throws -> some IntentResult & OpensIntent {
        let api = try AuthShortcut.getAPI(self.authController)

        let (streams, _) = try await api.helix(endpoint: .getStreams(userLogins: [self.channel]))

        guard streams.count > 0 else {
            throw IntentError.message("Channel \"\(self.channel)\" is not live.")
        }

        let stream = streams[0]
        self.router.bufferOpenWindow(.stream(stream))

        return .result(opensIntent: OpenApp())
    }
}
