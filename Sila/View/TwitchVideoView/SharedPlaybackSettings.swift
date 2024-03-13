//
//  SharedPlaybackSettings.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/3/24.
//

import Foundation
import KeychainWrapper

struct SharedPlaybackSettings {
    @available(*, unavailable) private init() {}

    private static let VOLUME_USERDEFAULTS_KEY = "video_volume"
    private static let QUALITY_USERDEFAULTS_KEY = "video_quality"

    static func setVolume(_ volume: Double) {
        KeychainWrapper.default.set(volume, forKey: SharedPlaybackSettings.VOLUME_USERDEFAULTS_KEY)
    }

    static func getVolume() -> Double {
        KeychainWrapper.default.object(of: Double.self, forKey: SharedPlaybackSettings.VOLUME_USERDEFAULTS_KEY) ?? 0.5
    }

    static func setQuality(_ quality: String) {
        KeychainWrapper.default.set(quality, forKey: SharedPlaybackSettings.QUALITY_USERDEFAULTS_KEY)
    }

    static func getQuality() -> String {
        KeychainWrapper.default.string(forKey: SharedPlaybackSettings.QUALITY_USERDEFAULTS_KEY) ?? "auto"
    }
}
