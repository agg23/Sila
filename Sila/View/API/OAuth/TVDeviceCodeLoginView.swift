//
//  TVDeviceCodeLoginView.swift
//  Sila
//

#if os(tvOS)
import SwiftUI
import Twitch
import CoreImage.CIFilterBuiltins

struct OAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthController.self) private var authController

    @State private var code: TwitchTVSession.DeviceCode?
    @State private var error: String?
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: 48) {
            Text("Sign in to Twitch")
                .font(.title)

            if let code = self.code, let url = URL(string: code.verificationURI) {
                HStack(spacing: 80) {
                    if let qrCode = Self.qrCode(for: url) {
                        Image(uiImage: qrCode)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 320, height: 320)
                    }

                    VStack(alignment: .leading, spacing: 24) {
                        Text("On your phone or computer, go to")
                            .foregroundStyle(.secondary)
                        Text(url.absoluteString.replacingOccurrences(of: "https://", with: ""))
                        Text("and enter")
                            .foregroundStyle(.secondary)
                        Text(code.userCode)
                            .font(.system(size: 96, weight: .bold, design: .monospaced))
                    }
                }
            } else if let error = self.error {
                Text(error)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Try Again") {
                    self.attempt += 1
                }
            } else {
                ProgressView()
                    .controlSize(.large)
            }

            Button("Cancel") {
                self.dismiss()
            }
        }
        .frame(maxWidth: 1400)
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.95))
        .ignoresSafeArea()
        .onExitCommand {
            self.dismiss()
        }
        .task(id: self.attempt) {
            await self.signIn()
        }
    }

    private func signIn() async {
        self.error = nil
        self.code = nil

        do {
            var token: String?
            while token == nil {
                let code = try await TwitchTVSession.requestDeviceCode()
                self.code = code

                do {
                    token = try await TwitchTVSession.waitForApproval(of: code)
                } catch TwitchTVSession.Failure.expired {
                    continue
                }
            }

            self.code = nil
            try await self.completeLogin(with: token!)
        } catch is CancellationError {
            // Dismissed
        } catch {
            self.code = nil
            self.error = error.localizedDescription
        }
    }

    private func completeLogin(with token: String) async throws {
        let client = TwitchClient(authentication: .init(oAuth: token, clientID: AuthController.USER_CLIENT_ID, userID: "", userLogin: ""))
        guard let user = try await client.helix(endpoint: .getUsers(ids: [], names: [])).first else {
            throw TwitchTVSession.Failure.unexpected("Signed in, but could not load your account.")
        }

        let authUser = AuthUser(id: user.id, username: user.displayName, avatarUrl: URL(string: user.profileImageUrl))
        self.authController.setLoggedInCredentials(withToken: token, authUser: authUser)
        self.dismiss()
    }

    private static func qrCode(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        guard let output = filter.outputImage,
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
#endif
