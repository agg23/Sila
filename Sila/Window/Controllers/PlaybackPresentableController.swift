//
//  PlaybackPresentableController.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Foundation

final class PlaybackPresentableController: PresentableControllerBase, Identifiable {
    var id: String {
        self.contentId
    }

    var isMuted: Bool = false

    var onMute: (() async -> Void)? = nil

    static func contentId(for stream: StreamableVideo) -> String {
        "stream-\(stream.id)"
    }

    static func muteAll(except exceptContentId: String? = nil) async {
        print("Sending mute to all windows")
        let _ = await MainActor.run {
            Task {
                for controller in PresentableControllerRegistry.shared(for: Self.self).all {
                    if controller.contentId == exceptContentId {
                        continue
                    }

                    await controller.onMute?()
                }
            }
        }
    }
}

extension PlaybackPresentableController: Equatable {
    static func == (lhs: PlaybackPresentableController, rhs: PlaybackPresentableController) -> Bool {
        lhs.id == rhs.id
    }
}
