//
//  PlayerOverlayControlsView.swift
//  Sila
//
//  Created by Adam Gastineau on 6/1/24.
//

import SwiftUI

struct PlayerOverlayControlsView: View {
    @AppStorage(Setting.dimSurroundings) var dimSurroundings: Bool = false

    @State private var volumePreventClose = false

    @Binding var player: WebViewPlayer
    @Binding var volume: CGFloat

    let onInteraction: () -> Void
    let activeChanged: (Bool) -> Void

    var body: some View {
        HStack {
            Button {
                self.player.reload()
                self.onInteraction()
            } label: {
                Label {
                    Text("Reload")
                } icon: {
                    Image(systemName: Icon.refresh)
                }
            }
            .help("Reload")
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .controlSize(.large)

            let dimLabel = "\(self.dimSurroundings ? "Undim" : "Dim") Surroundings"

            Button {
                self.dimSurroundings.toggle()
                self.onInteraction()
            } label: {
                Label {
                    Text(dimLabel)
                } icon: {
                    Image(systemName: Icon.dimming)
                }
            }
            // .help() must be cached in some scenarios. Invalidate this view via .id() to rerender tooltip
            .id(dimLabel)
            .help(dimLabel)
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .padding(.leading)

            Spacer()

            VolumeSlider(volume: self.$volume, isActive: self.$volumePreventClose)
                .onChange(of: self.volume) { _, newValue in
                    // Local volume has changed, either via UI slider, or by new client volume value
                    self.player.setVolume(newValue)
                }
                .onChange(of: self.player.volume) { _, newValue in
                    // We've received a new set volume value from the client
                    // Only update local volume if we do not have the volume slider up (as they may be out of sync)
                    guard !self.volumePreventClose else {
                        return
                    }

                    self.volume = newValue
                }
                .onChange(of: self.player.muted) { _, newValue in
                    if (newValue) {
                        self.volume = 0
                    }
                }
                .onChange(of: self.volumePreventClose) { _, newValue in
                    self.activeChanged(newValue)
                }
        }
    }
}
