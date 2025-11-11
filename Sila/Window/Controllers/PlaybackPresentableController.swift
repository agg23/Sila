//
//  PlaybackPresentableController.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Foundation

final class PlaybackPresentableController: PresentableControllerBase {
    var isMuted: Bool = false

    var onMute: (() -> Void)? = nil

    static func contentId(for stream: StreamableVideo) -> String {
        "stream-\(stream.id)"
    }

    static func muteAll(except exceptContentId: String? = nil) async {
        print("Sending mute to all windows")
        await MainActor.run {
            for controller in PresentableControllerRegistry.shared(for: Self.self).all {
                if controller.contentId == exceptContentId {
                    continue
                }

                controller.onMute?()
            }
        }
    }
}
