//
//  PopupVolumeSlider.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import JunoUI

struct PopupVolumeSlider: View {
    @State private var isPresented = false

    let volume: Binding<CGFloat>

    var body: some View {
        CircleBackgroundLessButton(systemName: "speaker.wave.3.fill", variableValue: self.volume.wrappedValue, tooltip: "Volume") {
//                self.player.toggleMute()
//                self.onButtonPress?()
            self.isPresented = true
        }
        .popover(isPresented: self.$isPresented, attachmentAnchor: .point(.leading), arrowEdge: .leading, content: {
            JunoSlider(sliderValue: self.volume, maxSliderValue: 1.0, label: "Volume")
        })
    }
}

#Preview {
    @State var volume: CGFloat = 0.0

    return PopupVolumeSlider(volume: $volume)
}
