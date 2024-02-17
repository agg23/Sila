//
//  FollowedStreamsModel.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import Foundation
import Twitch

class FollowedStreamsModel: ObservableObject {
    @Published var streams: [Twitch.Stream] = []

    func fetchData() {
        Task {
            let streamsTuple = try? await AuthController.shared.helixApi.getFollowedStreams(limit: nil, after: nil)

            DispatchQueue.main.async {
                if let streams = streamsTuple?.streams {
                    self.streams = streams
                } else {
                    print("Request for followed streams failed")
                    self.streams = []
                }
            }
        }
    }
}
