//
//  OAuthWebView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/16/24.
//

import SwiftUI
import WebKit

enum OAuthStatus {
    case success(token: String)
    case failure
}

struct OAuthWebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let webView: WKWebView
    let completed: (_ status: OAuthStatus) -> Void

    init(completed: @escaping (_ status: OAuthStatus) -> Void) {
        // Hide Twitch sign up and "Trouble logging in" links
        // Twitch sign up is problematic for App Store review, and doesn't make much
        // sense in the app, as the user cannot follow new channels
        // "Trouble logging in" doesn't work because it links out, so we also hide it
        let hideSignUpAndTroubleLoggingIn = WKUserScript(source: """
            const style = document.createElement("style");
            style.textContent = `
              li:nth-child(2) {
                display: none !important;
              }

              a[href="https://www.twitch.tv/user/account-recovery"] {
                display: none !important;
              }
            `;

            document.head.appendChild(style);
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        let controller = WKUserContentController()
        controller.addUserScript(hideSignUpAndTroubleLoggingIn)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        self.completed = completed
    }

    func makeCoordinator() -> OAuthWebViewCoordinator {
        OAuthWebViewCoordinator(webView: self.webView, completed: self.completed)
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.isInspectable = true
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator

        var oauthUrl = URL(string: "https://id.twitch.tv/oauth2/authorize")!
        oauthUrl.append(queryItems: [
            URLQueryItem(name: "client_id", value: AuthController.CLIENT_ID),
            URLQueryItem(name: "redirect_uri", value: AuthController.REDIRECT_URL),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "scope", value: "chat:edit chat:read user:read:follows")
        ])
        webView.load(URLRequest(url: oauthUrl))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.webView = self.webView
        context.coordinator.completed = self.completed
    }
}

class OAuthWebViewCoordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
    weak var webView: WKWebView?
    var completed: (_ status: OAuthStatus) -> Void

    init(webView: WKWebView, completed: @escaping (_ status: OAuthStatus) -> Void){
        self.webView = webView
        self.completed = completed
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.absoluteString.starts(with: AuthController.REDIRECT_URL) {
            let url = url.absoluteString.replacingOccurrences(of: "#", with: "?")

            let queryItems = URLComponents(string: url)?.queryItems
            if let tokenItem = queryItems?.first(where: { item in
                item.name == "access_token"
            }), let value = tokenItem.value {
                self.completed(.success(token: value))
            } else {
                self.completed(.failure)
            }

            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}

#Preview {
    OAuthWebView { _ in

    }
}
