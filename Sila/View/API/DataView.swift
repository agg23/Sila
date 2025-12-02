//
//  DataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct DataView<T, Content: View, Loading: View, ErrorView: View>: View {
    @Environment(AuthController.self) private var authController

    let loader: Binding<StandardDataLoader<T>>
    let task: (_: TwitchClient, _: AuthUser?) async throws -> T

    @ViewBuilder let content: (_: T, _: RefreshToken) -> Content
    @ViewBuilder let loading: (_: T?) -> Loading
    @ViewBuilder let error: (_: Error?) -> ErrorView

    var body: some View {
        if let apiAndUser = self.authController.status.apiAndUser() {
            let loader = self.loader.wrappedValue

            Group {
                switch loader.status {
                case .loading(let data):
                    self.loading(data)
                case .idle:
                    self.loading(nil)
                case .finished(let data), .loadingMore(let data):
                    self.content(data, loader.refreshToken)
                case .error(let error):
                    self.error(error)
                }
            }
            .task(id: self.authController.status, {
                do {
                    try await loader.loadIfNecessary(task: { (api, user) in
                        do {
                            return try await self.task(api, user)
                        } catch let error as HelixError {
                            // This is ugly
                            switch error {
                            case .twitchError(name: _, status: let status, message: _):
                                if status == 401 || status == 403 {
                                    self.authController.requestReauth()
                                }
                            case .parsingErrorFailed(status: let status, responseData: _):
                                if status == 401 || status == 403 {
                                    self.authController.requestReauth()
                                }
                            default:
                                break
                            }

                            throw error
                        } catch {
                            throw error
                        }
                    }, dataAugment: apiAndUser, onChange: self.authController.status)
                } catch is CancellationError {
                    print("Cancellation error")
                    self.loader.wrappedValue.completeCancel()
                } catch {
                    print("Unknown task error occurred \(error)")
                }
            })
            .onActivePhase {
                guard let lastUpdated = loader.lastUpdated else {
                    return
                }

                // If data is over 5 minutes old when we regain active status, reload
                // This is mainly to prevent showing days old data when someone puts on the headset
                if lastUpdated.timeIntervalSinceNow < 5 * -60 {
                    Task {
                        print("Refreshing data after restore to active state")
                        try? await loader.refresh()
                    }
                }
            }
        } else {
            // Not authorized at all (login or public)
            self.error(nil)
        }
    }
}
