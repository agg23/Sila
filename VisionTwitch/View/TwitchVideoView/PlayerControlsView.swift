//
//  PlayerControlsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/7/24.
//

import SwiftUI

struct PlayerControlsView: View {
    var player: WebViewPlayer

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

            Button {
                self.player.toggleMute()
                self.onButtonPress?()
            } label: {
                if self.player.muted {
                    Image(systemName: "speaker.slash.fill")
                } else {
                    Image(systemName: "speaker.wave.3.fill")
                }
            }
            Button {
                self.player.reload()
                self.onButtonPress?()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
        }
        .padding()
    }
}

#Preview {
    PlayerControlsView(player: WebViewPlayer())
}

#Preview {
    Rectangle()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            PlayerControlsView(player: WebViewPlayer())
                .glassBackgroundEffect()
        }
}
