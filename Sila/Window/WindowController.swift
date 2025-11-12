//
//  WindowController.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/6/24.
//

import Foundation
import Combine

class WindowController {
    static let shared = WindowController()

    let popoutChatSubject: PassthroughSubject<String, Never> = PassthroughSubject()
}
