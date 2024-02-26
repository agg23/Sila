//
//  PlayerControlsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/7/24.
//

import SwiftUI
import Twitch
import JunoUI

struct PlayerControlsView: View {
    @State private var volume: CGFloat = 0.5

    var player: WebViewPlayer

    var stream: Twitch.Stream

    var onButtonPress: (() -> Void)?

    var body: some View {
        HStack {
            CircleBackgroundLessButton(systemName: self.player.isPlaying ? "pause.fill" : "play.fill", tooltip: self.player.isPlaying ? "Pause" : "Play") {
                if self.player.isPlaying {
                    self.player.pause()
                } else {
                    self.player.play()
                }

                self.onButtonPress?()
            }
            .controlSize(.extraLarge)

            StreamStatusControlView(stream: self.stream)
                .padding(.horizontal)

            CircleBackgroundLessButton(systemName: "arrow.clockwise", tooltip: "Debug reload") {
                self.player.reload()
                self.onButtonPress?()
            }

            PopupVolumeSlider(volume: self.$volume)
                .onChange(of: self.volume) { _, newValue in
                    print(self.volume)
                    self.player.setVolume(newValue / 10)
                }
        }
        .padding()
    }
}

#Preview {
    PlayerControlsView(player: WebViewPlayer(), stream: STREAM_MOCK())
}

#Preview {
    Rectangle()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            PlayerControlsView(player: WebViewPlayer(), stream: STREAM_MOCK())
                .glassBackgroundEffect()
        }
}
