//
//  PlayerOverlayButtonView.swift
//  Sila
//
//  Created by Adam Gastineau on 12/15/25.
//

import SwiftUI

struct PlayerOverlayButtonView: View {
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button {
            self.action()
        } label: {
            Label {
                Text(self.label)
            } icon: {
                Image(systemName: self.icon)
            }
        }
        // .help() must be cached in some scenarios. Invalidate this view via .id() to rerender tooltip
        .id(self.label)
        .help(self.label)
        #if os(tvOS)
        .font(.headline)
        .labelStyle(.titleAndIcon)
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .controlSize(.large)
        #else
        .labelStyle(.iconOnly)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        #endif
    }
}
