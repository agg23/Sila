//
//  CircleBackgroundLessButton.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/24/24.
//

import SwiftUI

struct CircleBackgroundLessButton: View {
    let systemName: String
    let tooltip: String
    let action: () -> Void

    var body: some View {
        Button {
            self.action()
        } label: {
            Label(self.tooltip, systemImage: self.systemName)
        }
        .help(self.tooltip)
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .buttonStyle(.borderless)
    }
}

#Preview {
    CircleBackgroundLessButton(systemName: "play.fill", tooltip: "Play") {

    }
}
