//
//  CategoryStreams.swift
//  Sila
//
//  Created by Adam Gastineau on 3/19/24.
//

import AppIntents

struct CategoryStreamsIntent: AppIntent {
    @Dependency private var authController: AuthController

    static var title: LocalizedStringResource = "Streams in Category"

    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @Parameter(
        title: "Category",
        description: "The category/game to view",
        requestValueDialog: IntentDialog("What category do you wish to view?")
    )
    var category: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let api = try AuthShortcut.getAPI(self.authController)

        let (categories, _) = try await api.helix(endpoint: .searchCategories(for: self.category))

        guard categories.count > 0 else {
            throw IntentError.message("Could not find category \"\(self.category)\"")
        }

        let category = categories[0]

        let (streams, _) = try await api.helix(endpoint: .getStreams(gameIDs: [category.id], limit: 100))

        return .result(value: streams.map({ $0.userLogin }))
    }
}
