//
//  StreamTimer.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/10/24.
//

import Foundation

@Observable class StreamTimer {
    let secondTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
}
