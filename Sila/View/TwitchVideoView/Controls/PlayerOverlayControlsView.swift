//
//  PlayerOverlayControlsView.swift
//  Sila
//
//  Created by Adam Gastineau on 6/1/24.
//

import SwiftUI

struct PlayerOverlayControlsView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow

    @AppStorage(Setting.dimSurroundings) var dimSurroundings: Bool = false

    @State private var volumePreventClose = false

    @Bindable var player: WebViewPlayer
    @Binding var volume: CGFloat

    let streamableVideo: StreamableVideo

    let onInteraction: () -> Void
    let activeChanged: (Bool) -> Void

    var body: some View {
        HStack(spacing: 20) {
            PlayerOverlayButtonView(label: "Reload", icon: Icon.refresh) {
                self.player.reload()
                self.onInteraction()
            }

            let dimLabel = "\(self.dimSurroundings ? "Undim" : "Dim") Surroundings"

            PlayerOverlayButtonView(label: dimLabel, icon: Icon.dimming) {
                self.dimSurroundings.toggle()
                self.onInteraction()
            }

            Spacer()

            PlayerOverlayButtonView(label: "Lock to Head", icon: "arrow.up.right.bottomleft.rectangle") {
                Task {
                    await self.openImmersiveSpace(id: Window.followerStream, value: self.streamableVideo)
                    self.dismissWindow()
                }
            }

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
