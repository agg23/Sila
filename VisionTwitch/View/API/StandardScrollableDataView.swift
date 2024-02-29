//
//  StandardScrollableDataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/22/24.
//

import SwiftUI
import Twitch

struct StandardScrollableDataView<T, Content: View>: View {
    let loader: Binding<StandardDataLoader<T>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    let onPaginationThresholdMet: (() async -> Void)?

    @ViewBuilder let content: (_: T) -> Content

    init(loader: Binding<StandardDataLoader<T>>, task: @escaping (Helix, AuthUser?) async throws -> T, onPaginationThresholdMet: (() async -> Void)? = nil, @ViewBuilder content: @escaping (T) -> Content) {
        self.loader = loader
        self.task = task
        self.onPaginationThresholdMet = onPaginationThresholdMet
        self.content = content
    }

    var body: some View {
        DataView(loader: self.loader, task: self.task, content: { data in
            ScrollGridView {
                self.content(data)
                Color.clear.task {
                    await self.onPaginationThresholdMet?()
                }
                if self.loader.wrappedValue.isLoadingMore() {
                    ProgressView()
                }
            }
            .refreshable(action: { try? await self.loader.wrappedValue.refresh(minDurationSecs: 1) })
        }) { _ in
            ProgressView()
        } error: { (_: HelixError?) in
            APIErrorView(loader: self.loader)
        }
    }
}

struct AuthorizedStandardScrollableDataView<T, Content: View>: View {
    @Environment(\.authController) private var authController

    let loader: Binding<StandardDataLoader<T>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    let noAuthMessage: String

    let onPaginationThresholdMet: (() async -> Void)?

    @ViewBuilder let content: (_: T) -> Content

    init(loader: Binding<StandardDataLoader<T>>, task: @escaping (Helix, AuthUser?) async throws -> T, noAuthMessage: String, onPaginationThresholdMet: (() async -> Void)? = nil, @ViewBuilder content: @escaping (T) -> Content) {
        self.loader = loader
        self.task = task
        self.noAuthMessage = noAuthMessage
        self.onPaginationThresholdMet = onPaginationThresholdMet
        self.content = content
    }

    var body: some View {
        if self.authController.isAuthorized() {
            StandardScrollableDataView(loader: self.loader, task: self.task, onPaginationThresholdMet: self.onPaginationThresholdMet, content: self.content)
        } else {
            NeedsLoginView(noAuthMessage: self.noAuthMessage)
        }
    }
}
