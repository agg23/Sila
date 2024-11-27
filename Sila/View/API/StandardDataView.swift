//
//  StandardDataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/22/24.
//

import SwiftUI
import Twitch

struct StandardDataView<T, Content: View>: View {
    let loader: Binding<StandardDataLoader<T>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    @ViewBuilder let content: (_: T) -> Content

    var body: some View {
        DataView(loader: self.loader, task: self.task, content: { data in
            self.content(data)
        }) { _ in
            // Vertically center loading spinner with NavigationStack safe area
            ZStack {
                Color.clear
                ProgressView()
            }
            .ignoresSafeArea()
        } error: { (_: HelixError?) in
            APIErrorView(loader: self.loader)
        }
    }
}

struct AuthroizedStandardDataView<T, Content: View>: View {
    @Environment(AuthController.self) private var authController

    let loader: Binding<StandardDataLoader<T>>
    let task: (_: Helix, _: AuthUser?) async throws -> T

    let noAuthMessage: String
    let noAuthSystemImage: String

    @ViewBuilder let content: (_: T) -> Content

    var body: some View {
        if self.authController.isAuthorized() {
            StandardDataView(loader: self.loader, task: self.task, content: self.content)
        } else {
            NeedsLoginView(noAuthMessage: self.noAuthMessage, systemImage: self.noAuthSystemImage)
        }
    }
}
