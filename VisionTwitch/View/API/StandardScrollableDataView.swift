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

    @ViewBuilder let content: (_: T) -> Content

    var body: some View {
        DataView(loader: self.loader, task: self.task, content: { data in
            ScrollGridView {
                self.content(data)
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
    let noAuthSystemImage: String

    @ViewBuilder let content: (_: T) -> Content

    var body: some View {
        if self.authController.isAuthorized() {
            StandardScrollableDataView(loader: self.loader, task: self.task, content: self.content)
        } else {
            NeedsLoginView(noAuthMessage: self.noAuthMessage, systemImage: self.noAuthSystemImage)
        }
    }
}
