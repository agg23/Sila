//
//  StreamButtonStyle.swift
//  Sila
//
//  Created by Adam Gastineau on 11/4/25.
//

import SwiftUI

struct StreamButtonStyle: ButtonStyle {
    let radius: Double

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            #if os(visionOS)
            .hoverEffect()
            #endif
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: self.radius, height: self.radius)))
    }
}
