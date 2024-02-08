//
//  WebView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/7/24.
//

import SwiftUI
import WebKit

struct ChatWebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let webView: WKWebView

    init() {
        self.webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.isInspectable = true

        webView.load(URLRequest(url: URL(string: "https://www.twitch.tv/embed/GamesDoneQuick/chat?parent=twitch.tv&darkpopout")!))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {

    }
}

