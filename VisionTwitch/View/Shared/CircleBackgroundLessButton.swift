//
//  CircleBackgroundLessButton.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/24/24.
//

import SwiftUI

struct CircleBackgroundLessButton: View {
    let systemName: String
    let variableValue: Double?

    let tooltip: String
    let action: () -> Void

    internal init(systemName: String, variableValue: Double? = nil, tooltip: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.variableValue = variableValue
        
        self.tooltip = tooltip
        self.action = action
    }

    var body: some View {
        Button {
            self.action()
        } label: {
            Label {
                Text(self.tooltip)
            } icon: {
                Image(systemName: self.systemName, variableValue: self.variableValue)
            }
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
