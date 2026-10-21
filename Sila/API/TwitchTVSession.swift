//
//  TwitchTVSession.swift
//  Sila
//
//  Custom auth flow for tvOS
//

#if os(tvOS)
import Foundation

enum TwitchTVSession {
    /// Twitch's own Android TV app
    static let clientID = "ue6666qo983tsx6so1t0vnawi233wa"
    static let scopes = "chat:read chat:edit user:read:follows"

    struct DeviceCode: Decodable {
        let deviceCode: String
        let userCode: String
        let verificationURI: String
        let interval: Int
        let expiresIn: Int

        enum CodingKeys: String, CodingKey {
            case deviceCode = "device_code"
            case userCode = "user_code"
            case verificationURI = "verification_uri"
            case interval
            case expiresIn = "expires_in"
        }
    }

    enum Failure: LocalizedError {
        case expired
        case denied
        case unexpected(String)

        var errorDescription: String? {
            switch self {
            case .expired: "The code expired."
            case .denied: "The request was declined."
            case .unexpected(let message): message
            }
        }
    }

    // MARK: - Device code flow

    static func requestDeviceCode() async throws -> DeviceCode {
        let (data, status) = try await self.post("https://id.twitch.tv/oauth2/device", [
            "client_id": self.clientID,
            "scopes": self.scopes,
        ])

        guard status == 200 else {
            throw Failure.unexpected("Twitch returned \(status): \(String(decoding: data, as: UTF8.self))")
        }

        return try JSONDecoder().decode(DeviceCode.self, from: data)
    }

    /// Polls until the code is approved on another device. Returns the resulting access token
    static func waitForApproval(of code: DeviceCode) async throws -> String {
        let deadline = Date().addingTimeInterval(TimeInterval(code.expiresIn))
        var interval = max(code.interval, 1)

        while Date() < deadline {
            try await Task.sleep(for: .seconds(interval))

            let (data, status) = try await self.post("https://id.twitch.tv/oauth2/token", [
                "client_id": self.clientID,
                "device_code": code.deviceCode,
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                "scopes": self.scopes,
            ])

            if status == 200 {
                struct TokenResponse: Decodable { let access_token: String }
                return try JSONDecoder().decode(TokenResponse.self, from: data).access_token
            }

            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.message ?? ""

            switch message {
            case "authorization_pending":
                continue
            case "slow_down":
                interval += 5
            case "invalid device code":
                throw Failure.expired
            case "access_denied":
                throw Failure.denied
            default:
                throw Failure.unexpected("Twitch returned \(status): \(String(decoding: data, as: UTF8.self))")
            }
        }
        throw Failure.expired
    }

    // MARK: - Web session

    /// Builds and injects Twitch login cookies
    @MainActor
    static func installWebSession(token: String) async {
        guard let identity = await self.validate(token: token) else {
            print("TVSession: token failed validation; not installing web session")
            return
        }

        let twilightUser: [String: Any] = [
            "authToken": token,
            "displayName": identity.login,
            "id": identity.userID,
            "login": identity.login,
            "roles": ["isStaff": false],
            "version": 2,
        ]
        let twilightJSON = (try? JSONSerialization.data(withJSONObject: twilightUser)).map { String(decoding: $0, as: UTF8.self) } ?? "{}"

        let values = [
            "auth-token": token,
            "login": identity.login,
            "name": identity.login,
            "twilight-user": twilightJSON.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "",
        ]

        let cookies = values.compactMap { name, value in
            HTTPCookie(properties: [
                .domain: ".twitch.tv",
                .path: "/",
                .name: name,
                .value: value,
                .secure: "TRUE",
                .expires: Date().addingTimeInterval(60 * 60 * 24 * 365),
            ])
        }

        let success = await withCheckedContinuation { continuation in
            TVPrivateWebView.setWebsiteCookies(cookies) { continuation.resume(returning: $0) }
        }

        print("TVSession: installed web session for \(identity.login) success=\(success)")
    }

    @MainActor
    static func removeWebSession() async {
        await withCheckedContinuation { continuation in
            TVPrivateWebView.removeAllWebsiteData { continuation.resume() }
        }
    }

    // MARK: - Helpers

    private struct ErrorResponse: Decodable {
        let message: String
    }

    private struct Identity: Decodable {
        let login: String
        let userID: String

        enum CodingKeys: String, CodingKey {
            case login
            case userID = "user_id"
        }
    }

    private static func validate(token: String) async -> Identity? {
        var request = URLRequest(url: URL(string: "https://id.twitch.tv/oauth2/validate")!)
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else {
              return nil
        }

        return try? JSONDecoder().decode(Identity.self, from: data)
    }

    private static func post(_ url: String, _ form: [String: String]) async throws -> (Data, Int) {
        var components = URLComponents()
        components.queryItems = form.map { URLQueryItem(name: $0.key, value: $0.value) }

        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
}
#endif
