//
//  AuthController+EnvironmentValues.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import SwiftUI

private struct AuthControllerEnvironmentKey: EnvironmentKey {
    static let defaultValue = AuthController()
}

extension EnvironmentValues {
    var authController: AuthController {
        get { self[AuthControllerEnvironmentKey.self] }
        set { self[AuthControllerEnvironmentKey.self] = newValue }
    }
}
