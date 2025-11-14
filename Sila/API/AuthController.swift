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

@Observable final class AuthController: Sendable {
    // Embedding a secret into the client is insecure, but Twitch requires auth to access public APIs
    // and I don't want to set up a HTTP service to embed the secret into requests (especially given
    // this is OSS).
    static let CLIENT_ID = (Bundle.main.infoDictionary?["API_CLIENT_ID"] as! String).replacingOccurrences(of: "\"", with: "")
    static let CLIENT_SECRET = (Bundle.main.infoDictionary?["API_SECRET"] as! String).replacingOccurrences(of: "\"", with: "")
    static let REDIRECT_URL = "http://localhost"

    private static let USER_USERDEFAULTS_KEY = "user_info"
    private static let OAUTH_KEYCHAIN_KEY = "oauth_token"
    private static let PUBLIC_KEYCHAIN_KEY = "public_token"

    var status: AuthStatus
    let requestReauthSubject: PassthroughSubject<(), Never>

    private let session: URLSession

    init() {
        var user: AuthUser? = nil

        if let authUserData = UserDefaults.standard.object(forKey: AuthController.USER_USERDEFAULTS_KEY) as? Data, let authUser = try? JSONDecoder().decode(AuthUser.self, from: authUserData) {
            user = authUser
        }

        let oauthToken = KeychainWrapper.default.string(forKey: AuthController.OAUTH_KEYCHAIN_KEY)
        let publicToken = KeychainWrapper.default.string(forKey: AuthController.PUBLIC_KEYCHAIN_KEY)

        self.requestReauthSubject = PassthroughSubject()

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 30.0

        self.session = URLSession(configuration: config)

        if let oauthToken = oauthToken, let user = user {
            // We're logged in. Create authed Helix instance
            // Won't throw
            let client = TwitchClient(authentication: .init(oAuth: oauthToken, clientID: AuthController.CLIENT_ID, userID: user.id, userLogin: user.username), urlSession: self.session)
            self.status = .user(user: user, api: client)
        } else if let publicToken = publicToken {
            let client = Sila.createPublicClient(with: publicToken, session: self.session)
            self.status = .publicLoggedOut(api: client)
        } else {
            // No auth at all
            self.status = .none

            // Try to grab a public token
            Task {
                try? await self.requestPublicToken()
            }
        }
    }

    func setLoggedInCredentials(withToken token: String, authUser: AuthUser) {
        // Helix creation can not throw because we set all of the cred values
        let client = TwitchClient(authentication: TwitchCredentials(oAuth: token, clientID: AuthController.CLIENT_ID, userID: authUser.id, userLogin: authUser.username), urlSession: self.session)
        self.status = .user(user: authUser, api: client)

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

        let publicToken = KeychainWrapper.default.string(forKey: AuthController.PUBLIC_KEYCHAIN_KEY)

        if let publicToken = publicToken {
            let client = self.createPublicClient(with: publicToken)
            self.status = .publicLoggedOut(api: client)
        } else {
            // No auth at all
            self.status = .none
        }

        self.updateUserStore(token: nil, authUser: nil)

        // Send event to cause streaming windows to close
        NotificationCenter.default.post(name: .twitchLogOut, object: nil, userInfo: nil)
    }

    func isAuthorized() -> Bool {
        switch self.status {
        case .user:
            return true
        default:
            return false
        }
    }

    /// Request we rehandle authorization, whether logged in or public
    func requestReauth() {
        switch self.status {
        case .user:
            self.requestLoginReauthWithUI()
        case .publicLoggedOut, .none:
            Task {
                try? await self.requestPublicToken()
            }
        }
    }

    /// Request we show the sheet to relogin with current credentials
    func requestLoginReauthWithUI() {
        DispatchQueue.main.async {
            self.requestReauthSubject.send(())
        }
    }

    private func createPublicClient(with token: String) -> TwitchClient {
        Sila.createPublicClient(with: token, session: self.session)
    }

    private func requestPublicToken() async throws {
        // Already authorized
        if self.isAuthorized() {
            return
        }

        let token = try await self.fetchPublicToken()

        // We authorized since this request started, abort
        if self.isAuthorized() {
            return
        }

        // Public instance. Make sure we don't set user so we don't have permission issues
        let client = self.createPublicClient(with: token)
        self.status = .publicLoggedOut(api: client)
        self.updatePublicStore(token: token)
    }

    private func fetchPublicToken() async throws -> String {
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
            throw HelixError.networkError(wrapped: error)
        }

        guard let response = response as? HTTPURLResponse else {
            throw HelixError.noDataInResponse
        }

        if response.statusCode != 200 {
            let rawResponse = String(decoding: data, as: UTF8.self)
            throw HelixError.parsingErrorFailed(status: response.statusCode, responseData: rawResponse.data(using: .utf8) ?? Data())
        }

        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any], let accessToken = jsonResponse["access_token"] as? String {
                return accessToken
            }
        } catch {
            throw HelixError.networkError(wrapped: error)
        }

        throw HelixError.parsingResponseFailed(responseData: data)
    }

    private func updateUserStore(token: String?, authUser: AuthUser?) {
        if let authUser = authUser {
            if let encoded = try? JSONEncoder().encode(authUser) {
                UserDefaults.standard.setValue(encoded, forKey: AuthController.USER_USERDEFAULTS_KEY)
            }
        } else {
            UserDefaults.standard.setValue(nil, forKey: AuthController.USER_USERDEFAULTS_KEY)
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

private func createPublicClient(with token: String, session: URLSession) -> TwitchClient {
    // Public instance. Make sure we don't set user so we don't have permission issues
    TwitchClient(authentication: .init(oAuth: token, clientID: AuthController.CLIENT_ID, userID: "", userLogin: ""), urlSession: session)
}
