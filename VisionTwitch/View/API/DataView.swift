//
//  DataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct DataView<T, E: Error, Content: View, Loading: View, ErrorView: View>: View {
    private let content: (_: T) -> Content
    private let loading: (_: T?) -> Loading
    private let error: (_: E) -> ErrorView

    private let requiresAuth: Bool

    @Binding private var state: DataProvider<T, E>?
    @State private var hasRendered = false

    init(provider: Binding<DataProvider<T, E>?>, @ViewBuilder content: @escaping (_: T) -> Content, @ViewBuilder loading: @escaping (_: T?) -> Loading, @ViewBuilder error: @escaping (_: E) -> ErrorView, requiresAuth: Bool) {
        self._state = provider

        self.content = content
        self.loading = loading
        self.error = error

        self.requiresAuth = requiresAuth
    }

    var body: some View {
        // TODO: Remove ZStack
        ZStack {
            if let data = self.state?.data {
                switch data {
                case .success(let data):
                    self.content(data)
                case .failure(let error):
                    self.error(error)
                case .loading(let data):
                    self.loading(data)
                case .noData:
                    Text("no data")
                }
            } else {
                // Do nothing
            }
        }
        .onAppear {
            // Subscribe to auth updates
            state?.register()

            if self.hasRendered {
//                if let lastFetchToken = self.state?.lastFetchToken, lastFetchToken != AuthController.shared.currentToken {
//                    // Token has changed since we were last rendered, refetch
//                    let _ = self.state?.reloadTask()
//                } else {
                    // If we we had no data, or error, refetch
                    switch self.state?.data {
                    case .noData, .failure:
                        let _ = self.state?.reloadTask()
                    default:
                        break
                    }
//                }

                return
            }

            self.hasRendered = true

//            self.state = DataProvider(taskClosure: taskClosure, requiresAuth: self.requiresAuth)

//            if !self.requiresAuth || AuthController.shared.isAuthorized {
            if !self.requiresAuth {
                let _ = self.state?.reloadTask()
            }
        }
        .onDisappear {
            self.state?.cancel()
        }
    }
}

extension DataView where Loading == CustomProgressView {
    init(provider: Binding<DataProvider<T, E>?>, @ViewBuilder content: @escaping (_: T) -> Content, @ViewBuilder error: @escaping (_: E) -> ErrorView, requiresAuth: Bool) {
        self.init(provider: provider, content: content, loading: { _ in
            CustomProgressView()
        }, error: error, requiresAuth: requiresAuth)
    }
}

struct CustomProgressView: View {
    var body: some View {
        ProgressView()
    }
}

struct DataView2<T, E: Error, Content: View, Loading: View, ErrorView: View>: View {
    @Environment(\.authController) private var authController

    private var loader: DataLoader<T, AuthStatus>.WrappedValue
    private let task: (_: Helix, _: AuthUser?) async throws -> T

    private let content: (_: T) -> Content
    private let loading: (_: T?) -> Loading
    private let error: (_: E?) -> ErrorView

    init(loader: DataLoader<T, AuthStatus>.WrappedValue, task: @escaping (_: Helix, _: AuthUser?) async throws -> T, @ViewBuilder content: @escaping (_: T) -> Content, @ViewBuilder loading: @escaping (_: T?) -> Loading, @ViewBuilder error: @escaping (_: E?) -> ErrorView) {
        self.loader = loader
        self.task = task

        self.content = content
        self.loading = loading
        self.error = error
    }

    var body: some View {
        if let apiAndUser = self.authController.status.apiAndUser() {
            switch self.loader.get(task: {
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
        } else {
            // Not authorized
            self.error(nil)
        }
    }
}
