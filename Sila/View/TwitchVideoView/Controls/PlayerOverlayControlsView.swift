//
//  PlayerOverlayControlsView.swift
//  Sila
//
//  Created by Adam Gastineau on 6/1/24.
//

import SwiftUI

private struct OverlayButton: Identifiable {
    var id: String {
        self.label
    }

    let label: String
    let icon: String
    let action: () -> Void
}

struct PlayerOverlayControlsView: View {
    @Environment(Router.self) private var router

    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    #endif
    @Environment(\.dismissWindow) private var dismissWindow

    @AppStorage(Setting.dimSurroundings) var dimSurroundings: Bool = false

    @State private var volumePreventClose = false

    @Bindable var player: WebViewPlayer
    @Binding var volume: CGFloat

    let streamableVideo: StreamableVideo

    let onInteraction: () -> Void
    let activeChanged: (Bool) -> Void

    var body: some View {
        let overlayButtons = [
            OverlayButton(label: "Back", icon: Icon.back, action: {
                self.router.activeVideo = nil
            }),
            OverlayButton(label: "Reload", icon: Icon.refresh, action: {
                self.player.reload()
                self.onInteraction()
            }),
            OverlayButton(label: "\(self.dimSurroundings ? "Undim" : "Dim") Surroundings", icon: Icon.dimming, action: {
                self.dimSurroundings.toggle()
                self.onInteraction()
            })
        ]

//        #if os(macOS)
////        Color.clear.toolbar {
////            ToolbarItemGroup(placement: .primaryAction) {
////                ForEach(overlayButtons) { button in
////                    PlayerOverlayButtonView(label: button.label, icon: button.icon, action: button.action)
////                }
////            }
////        }
//        #else
        HStack(spacing: 20) {
            ForEach(overlayButtons) { button in
                PlayerOverlayButtonView(label: button.label, icon: button.icon, action: button.action)
            }

            Spacer()

            #if os(visionOS)
            PlayerOverlayButtonView(label: "Lock to Head", icon: "arrow.up.right.bottomleft.rectangle") {
                Task {
                    await self.openImmersiveSpace(id: Window.followerStream, value: self.streamableVideo)
                    self.dismissWindow()
                }
            }
            #endif

            #if !os(macOS)
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
            #endif
        }
//        #endif
        #if os(macOS)
        .padding(.top, 24)
        #endif
    }
}
