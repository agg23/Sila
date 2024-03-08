//
//  View+BackgroundTint.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/7/24.
//

import SwiftUI

extension View {
    func glassBackgroundEffect(displayMode: GlassBackgroundDisplayMode = .always, tint: Color) -> some View {
        self
            .background {
                Rectangle()
                    .fill(tint)
                    .glassBackgroundEffect(displayMode: displayMode)
                    .frame(depth: 1)
            }
    }

    func glassBackgroundEffect<S>(in shape: S, displayMode: GlassBackgroundDisplayMode = .always, tint: Color) -> some View where S : InsettableShape {
        self
            .background {
                Rectangle()
                    .fill(tint)
                    .glassBackgroundEffect(in: shape, displayMode: displayMode)
                    .frame(depth: 1)
            }
    }
}
