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

    let streamableVideo: StreamableVideo

    @Binding var showChat: Bool

    var onToggleChat: () -> Void

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

            StreamableVideoStatusControlView(streamableVideo: self.streamableVideo)
                .padding(.horizontal)

            CircleBackgroundLessButton(systemName: "arrow.clockwise", tooltip: "Debug reload") {
                self.player.reload()
                self.onInteraction?()
            }

            PopupVolumeSlider(volume: self.$volume, isActive: self.$volumePreventClose)
                .onChange(of: self.volume) { _, newValue in
                    self.player.setVolume(newValue)
                }

            CircleBackgroundLessButton(systemName: "message", tooltip: self.showChat ? "Hide Chat" : "Show Chat") {
                self.showChat.toggle()
                self.onInteraction?()
            }

            // Force CircleBackgroundLessButton styles
            ShareLink(item: URL(string: "https://twitch.tv/\(self.userName())")!)
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .buttonStyle(.borderless)
        }
        .padding()
        .onChange(of: self.volumePreventClose) { _, newValue in
            self.activeChanged?(newValue)
        }
    }

    func userName() -> String {
        switch self.streamableVideo {
        case .stream(let stream):
            return stream.userName
        case .video(let video):
            return video.userName
        }
    }
}

#Preview {
    PlayerControlsView(player: WebViewPlayer(), streamableVideo: .stream(STREAM_MOCK()), showChat: .constant(false)) {

    }
}

#Preview {
    Rectangle()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            PlayerControlsView(player: WebViewPlayer(), streamableVideo: .stream(STREAM_MOCK()), showChat: .constant(true)) {

            }
            .glassBackgroundEffect()
        }
}
