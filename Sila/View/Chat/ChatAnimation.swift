//
//  ChatAnimation.swift
//  Sila
//
//  Created by Adam Gastineau on 11/17/25.
//

import SwiftUI

extension AnyTransition {
    static func chatTranstion(contentWidth: Double) -> AnyTransition {
        return .modifier(
            active: ChatTransitionViewModifier(contentWidth: contentWidth, progress: 0.0),
            identity: ChatTransitionViewModifier(contentWidth: contentWidth, progress: 1.0)
        )
    }
}

func withChatAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
    try withAnimation(.easeInOut(duration: 0.3), body)
}


private struct ChatTransitionViewModifier: ViewModifier, Animatable {
    let contentWidth: Double

    var progress: Double

    var animatableData: Double {
        get {
            self.progress
        }
        set {
            self.progress = newValue
        }
    }

    static let MIN_SCALE = 0.8
    static let MAX_SCALE = 1.0

    static let SCALE_DURATION = 0.3

    // TODO: This will cause a window behind it to flash due to Z proximity
    static let MIN_Z = -64.0
    static let MAX_Z = 0.0

    static let Z_DURATION = 0.3

    func body(content: Content) -> some View {
        let interpolate: (Double, Double) -> Double = { start, end in
            (1.0 - self.progress) * start + self.progress * end
        }

        let delayedInterpolation: (Double, Double, Double) -> Double = { duration, start, end in
            let overallProgress = max(0, self.progress - (1.0 - duration))
            return max(start, start + overallProgress / duration * (end - start))
        }

        content
            .scaleEffect(delayedInterpolation(Self.SCALE_DURATION, Self.MIN_SCALE, Self.MAX_SCALE))
            .opacity(interpolate(0.0, 1.0))
            .offset(x: interpolate(-self.contentWidth, 0))
            .offset(z: delayedInterpolation(Self.Z_DURATION, Self.MIN_Z, Self.MAX_Z))
    }
}
