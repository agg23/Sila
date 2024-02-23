//
//  DataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct DataView<T, E: Error, Content: View, Loading: View, ErrorView: View>: View {
    @Environment(\.authController) private var authController

    let loader: Binding<DataLoader<T, AuthStatus>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    let content: (_: T) -> Content
    let loading: (_: T?) -> Loading
    let error: (_: E?) -> ErrorView

    var body: some View {
        if let apiAndUser = self.authController.status.apiAndUser() {
            Group {
                switch self.loader.wrappedValue.get(task: {
                    // We have some auth info, run the task
                    try await self.task(apiAndUser.0, apiAndUser.1)
                }, onChange: self.authController.status) {
                case .loading(let data):
                    self.loading(data)
                case .idle:
                    Text("No data")
                case .finished(let data):
                    self.content(data)
                case .error(let error):
                    self.error(error as? E)
                }
            }
            .onAppear {
                Task {
                    await self.loader.wrappedValue.onAppear()
                }
            }
        } else {
            // Not authorized
            self.error(nil)
        }
    }
}
