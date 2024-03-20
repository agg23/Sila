//
//  AlwaysOpenStreamIntent.swift
//  Sila
//
//  Created by Adam Gastineau on 3/19/24.
//

import AppIntents
import Twitch

// Implemented to allow the OpenStreamIntent to optionally open the app
struct OpenApp: AppIntent {
    @Dependency private var router: Router

    static var title: LocalizedStringResource = "Open App"

    static var openAppWhenRun: Bool = true
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
