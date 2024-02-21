//
//  SuccessDataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI
import Twitch

struct SuccessDataView<T, E: Error, Content: View, Other: View>: View {
    let taskClosure: (_: Helix) -> Task<T, E>

    let content: (_: T) -> Content
    let other: () -> Other

    let requiresAuth: Bool

    init(taskClosure: @escaping (_: Helix) -> Task<T, E>, @ViewBuilder content: @escaping (_: T) -> Content, @ViewBuilder other: @escaping () -> Other, requiresAuth: Bool) {
        self.taskClosure = taskClosure
        self.content = content
        self.other = other
        self.requiresAuth = requiresAuth
    }

    var body: some View {
        DataView(taskClosure: self.taskClosure, content: self.content, loading: { _ in self.other() }, error: { _ in self.other() }, requiresAuth: self.requiresAuth)
    }
}
