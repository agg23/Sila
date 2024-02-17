//
//  AuthController.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import Foundation
import Twitch
import Combine

class AuthController {
    static let shared = AuthController()

    static let CLIENT_ID = "r5reitw2z0vqow78wxi78x7h88rptf"
    static let REDIRECT_URL = "http://localhost:8080"

    var helixApi: Helix
    let subject: any Subject<(), Error>

    private init() {
        // Create unauthed Helix instance. Set userId to empty string so Helix doesn't throw
        self.helixApi = try! Helix(authentication: .init(oAuth: "", clientID: AuthController.CLIENT_ID, userId: ""))
        self.subject = PassthroughSubject<(), Error>()
    }

    func setCredientials(withToken token: String, userId: String) {
        // Helix creation can not throw because we set all of the cred values
        self.helixApi = try! Helix(authentication: TwitchCredentials(oAuth: token, clientID: AuthController.CLIENT_ID, userId: userId))
        self.subject.send(())
    }
}
