//
//  AuthController.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import Foundation
import Combine
import Twitch
import KeychainWrapper
import WebKit

class AuthController {
    static let shared = AuthController()

    static let CLIENT_ID = "r5reitw2z0vqow78wxi78x7h88rptf"
    static let REDIRECT_URL = "http://localhost:8080"

    private static let USER_USER_DEFAULTS_KEY = "user_info"
    private static let OAUTH_KEYCHAIN_KEY = "oauth_token"

    var helixApi: Helix
    let subject: any Subject<(), Error>
    var authUser: AuthUser?
    var isAuthorized: Bool = false

    private init() {
        if let authUserData = UserDefaults.standard.object(forKey: AuthController.USER_USER_DEFAULTS_KEY) as? Data, let authUser = try? JSONDecoder().decode(AuthUser.self, from: authUserData) {
            self.authUser = authUser
        }
        let oauthToken = KeychainWrapper.default.string(forKey: AuthController.OAUTH_KEYCHAIN_KEY)

        // Create authed or unauthed Helix instance. Set userId to empty string so Helix doesn't throw
        self.helixApi = try! Helix(authentication: .init(oAuth: oauthToken ?? "", clientID: AuthController.CLIENT_ID, userId: authUser?.id ?? ""))
        self.subject = PassthroughSubject<(), Error>()

        if oauthToken != nil && authUser != nil {
            self.isAuthorized = true
        }
    }

    func setCredientials(withToken token: String, authUser: AuthUser) {
        self.authUser = authUser
        // Helix creation can not throw because we set all of the cred values
        self.helixApi = try! Helix(authentication: TwitchCredentials(oAuth: token, clientID: AuthController.CLIENT_ID, userId: authUser.id))
        self.isAuthorized = true
        self.subject.send(())

        self.updateStore(token: token, authUser: authUser)
    }

    func logOut() {
        print("Logging out")
        // Clear cookies
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("Cookie: \(record) deleted")
            }
        }

        self.helixApi = try! Helix(authentication: .init(oAuth: "", clientID: AuthController.CLIENT_ID, userId: ""))
        self.authUser = nil
        self.isAuthorized = false

        self.updateStore(token: nil, authUser: nil)

        // Send event to cause streaming windows to close
        NotificationCenter.default.post(name: .twitchLogOut, object: nil, userInfo: nil)

        self.subject.send(())
    }

    private func updateStore(token: String?, authUser: AuthUser?) {
        if let authUser = authUser {
            if let encoded = try? JSONEncoder().encode(authUser) {
                UserDefaults.standard.setValue(encoded, forKey: AuthController.USER_USER_DEFAULTS_KEY)
            }
        } else {
            UserDefaults.standard.setValue(nil, forKey: AuthController.USER_USER_DEFAULTS_KEY)
        }

        KeychainWrapper.default.set(token, forKey: AuthController.OAUTH_KEYCHAIN_KEY)
    }
}
