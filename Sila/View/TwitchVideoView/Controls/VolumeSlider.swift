//
//  VolumeSlider.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/25/24.
//

import SwiftUI
import JunoUI

struct VolumeSlider: View {
    /// The volume level at the last mute button press
    @State private var lastMuteVolume: CGFloat = 0.5

    @State private var interactionTimer: Timer?

    @Binding var volume: CGFloat
    @Binding var isActive: Bool

    private let muteThreshold = 0.01

    var body: some View {
        HStack {
            JunoSlider(sliderValue: self.$volume, maxSliderValue: 1.0, baseHeight: 10.0, expandedHeight: 22.0, label: "Volume") { editingChanged in
                self.isActive = true

                if editingChanged {
                    self.interactionTimer?.invalidate()
                    self.interactionTimer = nil
                } else {
                    self.resetTimer()
                }
            }
            .frame(width: 150)

            CircleBackgroundLessButton(systemName: Icon.volume, variableValue: self.volume, tooltip: self.volume > self.muteThreshold ? "Mute" : "Unmute") {
                self.isActive = true

                if self.volume > self.muteThreshold {
                    // We are not muted, mute
                    self.lastMuteVolume = self.volume
                    self.volume = 0
                } else {
                    // We are muted, restore to the previous value
                    self.volume = self.lastMuteVolume
                }

                self.resetTimer()
            }
        }
        .padding(.leading, 16)
        .glassBackgroundEffect()
        .alignmentGuide(.trailing, computeValue: { $0[.trailing] })
        .onChange(of: self.volume) { _, _ in
            self.resetTimer()
        }
    }

    func resetTimer() {
        self.interactionTimer?.invalidate()
        self.interactionTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
            self.isActive = false
        })
    }
}

#Preview {
    @State var volume: CGFloat = 0.0

    return VolumeSlider(volume: $volume, isActive: .constant(true))
}
