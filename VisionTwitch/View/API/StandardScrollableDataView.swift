//
//  StandardScrollableDataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/22/24.
//

import SwiftUI
import Twitch

struct StandardScrollableDataView<T, Content: View>: View {
    let loader: Binding<DataLoader<T, AuthStatus>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    let content: (_: T) -> Content

    var body: some View {
        DataView(loader: self.loader, task: self.task, content: { data in
            ScrollGridView {
                self.content(data)
            }
            .refreshable(action: { await self.loader.wrappedValue.refresh(minDurationSecs: 1) })
        }) { _ in
            ProgressView()
        } error: { (_: HelixError?) in
            Text("An error occured")
        }
    }
}

struct AuthorizedStandardScrollableDataView<T, Content: View>: View {
    @Environment(\.authController) private var authController

    let loader: Binding<DataLoader<T, AuthStatus>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    let content: (_: T) -> Content

    var body: some View {
        if self.authController.isAuthorized() {
            StandardScrollableDataView(loader: self.loader, task: self.task, content: self.content)
        } else {
            Text("Not logged in")
        }
    }
}
