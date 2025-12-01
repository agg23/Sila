//
//  PlayerControlsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/7/24.
//

import SwiftUI
import Twitch
import JunoUI

struct PlayerOranamentControlsView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    let player: WebViewPlayer

    let streamableVideo: StreamableVideo

    @Binding var chatVisible: Bool

    @State private var durationSliderPreventClose: Bool = false
    @ObservedObject private var chatHandle: PresentableHandle<ChatPresentableController>

    let onInteraction: (() -> Void)?
    let activeChanged: ((Bool) -> Void)?

    init(player: WebViewPlayer, streamableVideo: StreamableVideo, chatVisible: Binding<Bool>, onInteraction: (() -> Void)? = nil, activeChanged: ((Bool) -> Void)? = nil) {
        self.player = player
        self.streamableVideo = streamableVideo
        self._chatVisible = chatVisible
        self.onInteraction = onInteraction
        self.activeChanged = activeChanged
        let contentId = ChatPresentableController.contentId(for: streamableVideo.userId)
        self._chatHandle = ObservedObject(wrappedValue: PresentableControllerRegistry.shared(for: ChatPresentableController.self).handle(for: contentId))
    }

    var body: some View {
        Group {
            if case .video(_) = self.streamableVideo {
                let currentTimeBinding = Binding(get: { CGFloat(self.player.currentTime) }, set: { self.player.seek($0) })

                let durationBinding = Binding(get: {CGFloat(self.player.duration)}, set: { _ in })

                VStack {
                    self.mainBody

                    PlayerDurationSliderView(currentTime: currentTimeBinding, duration: durationBinding, isActive: self.$durationSliderPreventClose)
                        .padding(.horizontal)
                }
            } else {
                self.mainBody
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .onChange(of: self.durationSliderPreventClose, { _, newValue in
            self.activeChanged?(newValue)
        })
    }

    @ViewBuilder
    var mainBody: some View {
        let qualityBinding = Binding(get: { self.player.quality }, set: { self.player.setQuality($0) })

        HStack {
            CircleBackgroundLessButton(systemName: self.player.isPlaying ? Icon.pause : Icon.play, tooltip: self.player.isPlaying ? "Pause" : "Play") {
                if self.player.isPlaying {
                    self.player.pause()
                } else {
                    self.player.playAndMuteOthers(except: self.streamableVideo)
                }

                self.onInteraction?()
            }
            .controlSize(.extraLarge)

            PlayerStreamInfoView(player: self.player, streamableVideo: self.streamableVideo)
                .padding(.horizontal, 4)

            if !self.player.isVideo {
                // Quality setting is disabled on VoDs due to Safari bug that prevents playback on non-source qualities
                // For some reason embedding a picker in a menu displays a picker with the menu style, with the menu's launch button
                Menu {
                    Picker("Quality", selection: qualityBinding) {
                        // Qualties are saved in reverse order
                        ForEach(self.player.availableQualities.reversed(), id: \.quality) { quality in
                            Button(quality.name) {
                                self.player.setQuality(quality.quality)
                            }
                        }
                    }
                    Text("Quality")
                } label: {
                    Image(systemName: Icon.quality)
                        .symbolRenderingMode(.monochrome)
                }
                // Fixing #41: Controls disappearing when menu and/or Share Sheet is open
                // Cannot create a custom ButtonStyle with isPressed as .borderless is a PrimitiveButtonStyle, but isPressed is ButtonStyle
                // Menu doesn't respond to gesture recognizer and onTapGesture
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                .help("Quality")
            }

            // Only use standalone (window) chatHandle property, otherwise use local chatVisibility setting to allow rapid toggling
            let isChatOpen = self.chatVisible || self.chatHandle.hasStandalone

            CircleBackgroundLessButton(systemName: isChatOpen ? Icon.chatOpen : Icon.chat, tooltip: isChatOpen ? "Hide Chat" : "Show Chat") {
                withChatAnimation {
                    if isChatOpen {
                        self.chatVisible = false
                        if let chatWindowModel = self.chatHandle.controller?.chatWindowModel {
                            self.dismissWindow(id: Window.chat, value: chatWindowModel)
                        }
                    } else {
                        self.chatVisible = true
                    }
                }
                self.onInteraction?()
            }

            // Force CircleBackgroundLessButton styles
            ShareLink(item: URL(string: "https://twitch.tv/\(self.userLogin())")!)
            .labelStyle(.iconOnly)
            .buttonBorderShape(.circle)
            .buttonStyle(.borderless)
        }
    }

    func userLogin() -> String {
        switch self.streamableVideo {
        case .stream(let stream):
            return stream.userLogin
        case .video(let video):
            return video.userLogin
        }
    }
}

private func previewPlayer(_ isVideo: Bool = false) -> WebViewPlayer {
    let player = WebViewPlayer()
    player.quality = "1080p"
    player.availableQualities = [VideoQuality(quality: "chunked", name: "1080p"), VideoQuality(quality: "720p", name: "720p"), VideoQuality(quality: "480p", name: "480p"), VideoQuality(quality: "240p", name: "240p")]
    player.setIsVideo(isVideo)

    return player
}

#Preview("Basic") {
    PlayerOranamentControlsView(player: previewPlayer(), streamableVideo: .stream(STREAM_MOCK()), chatVisible: .constant(false)) {

    } activeChanged: { _ in

    }
    .environment(AuthController())
}

#Preview("On Window") {
    Rectangle()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            PlayerOranamentControlsView(player: previewPlayer(), streamableVideo: .stream(STREAM_MOCK()), chatVisible: .constant(true)) {

            } activeChanged: { _ in

            }
            .glassBackgroundEffect()
        }
        .environment(AuthController())
}

#Preview("On Window - VoD") {
    Rectangle()
        .ornament(attachmentAnchor: .scene(.bottom)) {
            PlayerOranamentControlsView(player: previewPlayer(true), streamableVideo: .video(VIDEO_MOCK()), chatVisible: .constant(true)) {

            } activeChanged: { _ in

            }
            .glassBackgroundEffect()
        }
        .environment(AuthController())
}

