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

    // Embedding a secret into the client is insecure, but Twitch requires auth to access public APIs
    // and I don't want to set up a HTTP service to embed the secret into requests (especially given
    // this is OSS).
    static let CLIENT_ID = (Bundle.main.infoDictionary?["API_CLIENT_ID"] as! String).replacingOccurrences(of: "\"", with: "")
    static let CLIENT_SECRET = (Bundle.main.infoDictionary?["API_SECRET"] as! String).replacingOccurrences(of: "\"", with: "")
    static let REDIRECT_URL = "http://localhost"

    private static let USER_USER_DEFAULTS_KEY = "user_info"
    private static let OAUTH_KEYCHAIN_KEY = "oauth_token"
    private static let PUBLIC_KEYCHAIN_KEY = "public_token"

    var helixApi: Helix
    let authChangeSubject: PassthroughSubject<(), Never>
    let requestReauthSubject: PassthroughSubject<(), Never>
    var authUser: AuthUser?
    var isAuthorized: Bool = false
    var currentToken: String

    private init() {
        if let authUserData = UserDefaults.standard.object(forKey: AuthController.USER_USER_DEFAULTS_KEY) as? Data, let authUser = try? JSONDecoder().decode(AuthUser.self, from: authUserData) {
            self.authUser = authUser
        }
        let oauthToken = KeychainWrapper.default.string(forKey: AuthController.OAUTH_KEYCHAIN_KEY)
        let publicToken = KeychainWrapper.default.string(forKey: AuthController.PUBLIC_KEYCHAIN_KEY)

        if let oauthToken = oauthToken {
            // Create authed Helix instance. Set userId to empty string so Helix doesn't throw
            self.helixApi = try! Helix(authentication: .init(oAuth: oauthToken, clientID: AuthController.CLIENT_ID, userId: authUser?.id ?? ""))
            self.currentToken = oauthToken
        } else {
            // Public instance. Make sure we don't set user so we don't have permission issues
            let token = publicToken ?? ""
            self.helixApi = try! Helix(authentication: .init(oAuth: token, clientID: AuthController.CLIENT_ID, userId: ""))
            self.currentToken = token
        }

        self.authChangeSubject = PassthroughSubject<(), Never>()
        self.requestReauthSubject = PassthroughSubject<(), Never>()

        if oauthToken != nil && authUser != nil {
            self.isAuthorized = true
        }
    }

    func setUserCredientials(withToken token: String, authUser: AuthUser) {
        self.authUser = authUser
        // Helix creation can not throw because we set all of the cred values
        self.helixApi = try! Helix(authentication: TwitchCredentials(oAuth: token, clientID: AuthController.CLIENT_ID, userId: authUser.id))
        self.currentToken = token
        self.isAuthorized = true
        self.authChangeSubject.send(())

        self.updateUserStore(token: token, authUser: authUser)
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
        self.currentToken = ""
        self.authUser = nil
        self.isAuthorized = false

        self.updateUserStore(token: nil, authUser: nil)

        // Send event to cause streaming windows to close
        NotificationCenter.default.post(name: .twitchLogOut, object: nil, userInfo: nil)

        self.authChangeSubject.send(())
    }

    /// Request we show the sheet to relogin with current credentials
    func requestReauth() {
        DispatchQueue.main.async {
            self.requestReauthSubject.send(())
        }
    }

    func updatePublicToken() async throws {
        if self.isAuthorized {
            return
        }

        let token = try await requestPublicToken()

        self.helixApi = try! Helix(authentication: TwitchCredentials(oAuth: token, clientID: AuthController.CLIENT_ID, userId: ""))
        self.currentToken = token
        self.updatePublicStore(token: token)
    }

    private func requestPublicToken() async throws -> String {
        var url = URL(string: "https://id.twitch.tv/oauth2/token")!
        url.append(queryItems: [
            URLQueryItem(name: "client_id", value: AuthController.CLIENT_ID),
            URLQueryItem(name: "client_secret", value: AuthController.CLIENT_SECRET),
            URLQueryItem(name: "grant_type", value: "client_credentials"),
        ])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw HelixError.invalidResponse(rawResponse: error.localizedDescription)
        }

        guard let response = response as? HTTPURLResponse else {
            throw HelixError.invalidResponse(rawResponse: "Response is not HTTPURLResponse")
        }

        if response.statusCode != 200 {
            let rawResponse = String(decoding: data, as: UTF8.self)
            throw HelixError.invalidErrorResponse(status: response.statusCode, rawResponse: rawResponse)
        }

        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any], let accessToken = jsonResponse["access_token"] as? String {
                return accessToken
            }
        } catch {
            let rawResponse = String(decoding: data, as: UTF8.self)
            throw HelixError.invalidErrorResponse(status: response.statusCode, rawResponse: "Error: \(error.localizedDescription). Data: \(rawResponse)")
        }

        let rawResponse = String(decoding: data, as: UTF8.self)
        throw HelixError.invalidErrorResponse(status: response.statusCode, rawResponse: rawResponse)
    }

    private func updateUserStore(token: String?, authUser: AuthUser?) {
        if let authUser = authUser {
            if let encoded = try? JSONEncoder().encode(authUser) {
                UserDefaults.standard.setValue(encoded, forKey: AuthController.USER_USER_DEFAULTS_KEY)
            }
        } else {
            UserDefaults.standard.setValue(nil, forKey: AuthController.USER_USER_DEFAULTS_KEY)
        }

        if let token = token {
            KeychainWrapper.default.set(token, forKey: AuthController.OAUTH_KEYCHAIN_KEY)
        } else {
            KeychainWrapper.default.removeObject(forKey: AuthController.OAUTH_KEYCHAIN_KEY)
        }
    }

    private func updatePublicStore(token: String?) {
        if let token = token {
            KeychainWrapper.default.set(token, forKey: AuthController.PUBLIC_KEYCHAIN_KEY)
        } else {
            KeychainWrapper.default.removeObject(forKey: AuthController.PUBLIC_KEYCHAIN_KEY)
        }
    }
}
