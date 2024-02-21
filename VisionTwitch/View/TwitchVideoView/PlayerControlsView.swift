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
            Button {
                if self.player.isPlaying {
                    self.player.pause()
                } else {
                    self.player.play()
                }

                self.onButtonPress?()
            } label: {
                if self.player.isPlaying {
                    Image(systemName: "pause.fill")
                } else {
                    Image(systemName: "play.fill")
                }
            }
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
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
    Rectangle()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            PlayerControlsView(player: WebViewPlayer())
                .glassBackgroundEffect()
        }
}
