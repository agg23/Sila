//
//  StreamableVideo.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/28/24.
//

import Twitch

enum StreamableVideo: Equatable, Hashable, Encodable, Decodable {
    case stream(Twitch.Stream)
    case video(Twitch.Video)

    var id: String {
        switch self {
        case .stream(let stream):
            return stream.id
        case .video(let video):
            return video.id
        }
    }

    var userId: String {
        switch self {
        case .stream(let stream):
            return stream.userID
        case .video(let video):
            return video.userID
        }
    }

    var userName: String {
        switch self {
        case .stream(let stream):
            return stream.userName
        case .video(let video):
            return video.userName
        }
    }

    var title: String {
        switch self {
        case .stream(let stream):
            return stream.title
        case .video(let video):
            return video.title
        }
    }
}
