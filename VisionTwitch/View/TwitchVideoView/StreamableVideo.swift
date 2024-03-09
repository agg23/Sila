//
//  StreamableVideo.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/28/24.
//

import Twitch

enum StreamableVideo {
    case stream(Twitch.Stream)
    case video(Twitch.Video)

    func id() -> String {
        switch self {
        case .stream(let stream):
            return stream.id
        case .video(let video):
            return video.id
        }
    }
}
