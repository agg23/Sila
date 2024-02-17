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
        self.webView = WKWebView()
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
