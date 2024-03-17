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

    let loader: Binding<StandardDataLoader<T>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    @ViewBuilder let content: (_: T) -> Content
    @ViewBuilder let loading: (_: T?) -> Loading
    @ViewBuilder let error: (_: E?) -> ErrorView

    var body: some View {
        if let apiAndUser = self.authController.status.apiAndUser() {
            Group {
                switch self.loader.wrappedValue.status {
                case .loading(let data):
                    self.loading(data)
                case .idle:
                    self.loading(nil)
                case .finished(let data), .loadingMore(let data):
                    self.content(data)
                case .error(let error):
                    self.error(error as? E)
                }
            }
            .task(id: self.authController.status, {
                do {
                    try await self.loader.wrappedValue.loadIfNecessary(task: { (api, user) in
                        // We have some auth info, run the task
                        do {
                            return try await self.task(api, user)
                        } catch let error as HelixError {
                            // This is ugly
                            switch error {
                            case .invalidErrorResponse(status: let status, rawResponse: _):
                                if status == 401 || status == 403 {
                                    self.authController.requestReauth()
                                }
                            case .requestFailed(error: _, status: let status, message: _):
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
        } else {
            // Not authorized at all (login or public)
            self.error(nil)
        }
    }
}
