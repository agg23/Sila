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
    @State private var volumePreventClose = false

    var player: WebViewPlayer

    var stream: Twitch.Stream

    var onInteraction: (() -> Void)?
    var activeChanged: ((Bool) -> Void)?

    var body: some View {
        HStack {
            CircleBackgroundLessButton(systemName: self.player.isPlaying ? "pause.fill" : "play.fill", tooltip: self.player.isPlaying ? "Pause" : "Play") {
                if self.player.isPlaying {
                    self.player.pause()
                } else {
                    self.player.play()
                }

                self.onInteraction?()
            }
            .controlSize(.extraLarge)

            StreamStatusControlView(stream: self.stream)
                .padding(.horizontal)

            CircleBackgroundLessButton(systemName: "arrow.clockwise", tooltip: "Debug reload") {
                self.player.reload()
                self.onInteraction?()
            }

            PopupVolumeSlider(volume: self.$volume, isActive: self.$volumePreventClose)
                .onChange(of: self.volume) { _, newValue in
                    self.player.setVolume(newValue)
                }

            // Force CircleBackgroundLessButton styles
            ShareLink(item: URL(string: "https://twitch.tv/\(self.stream.userName)")!)
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .buttonStyle(.borderless)
        }
        .padding()
        .onChange(of: self.volumePreventClose) { _, newValue in
            self.activeChanged?(newValue)
        }
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
