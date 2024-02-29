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
}
