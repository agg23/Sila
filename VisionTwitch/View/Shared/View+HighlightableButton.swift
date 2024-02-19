//
//  View+HighlightableButton.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

extension View {
    @ViewBuilder
    func highlightableButton(_ isActive: Bool) -> some View {
        if isActive {
            self
        } else {
            self.buttonStyle(.borderless)
        }
    }
}
