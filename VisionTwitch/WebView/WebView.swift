//
//  WebView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import WebKit
import FlyingFox

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let webView: WKWebView

    init() {
        let configuration = WKWebViewConfiguration()

        // Allow videos to not play in the native player
        configuration.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: .zero, configuration: configuration)
    }

    func makeCoordinator() -> Coordinator {
       Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.isInspectable = true
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
//        guard let url = Bundle.main.url(forResource: "index", withExtension: "html") else {
//            fatalError("Could not get index.html")
//        }

//        uiView.loadFileURL(url, allowingReadAccessTo: url)
        Task {
            let server = HTTPServer(port:8080)
            await server.appendRoute("/") { request in
                let channel = request.query["channel"]

                let destination: String

                if let channel = channel {
                    destination = "channel=\(channel)"
                } else {
                    fatalError("Invalid request")
                }

                let html = """
                    <html>
                        <body>
                            Hello world from Web
                            <iframe
                                src="https://player.twitch.tv/?\(destination)&parent=localhost"
                                height="100%"
                                width="100%"
                                autoplay>
                            </iframe>
                        </body>
                    </html>
                """

                return HTTPResponse(statusCode: .ok, body: html.data(using: .utf8)!)
            }
            do {
                try await server.start()
            } catch {
                print(error)
            }
        }

//        uiView.load(URLRequest(url: URL(string: "http://localhost:8080?channel=nobletofu")!))
    }

    func reload() {
//        self.webView.reload()
        self.webView.load(URLRequest(url: URL(string: "https://apple.com")!))
    }
}

class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
    var parent: WebView

    init(_ parent: WebView){
        self.parent = parent
    }

//     func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        self.parent.reload()
//    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print(navigationAction.request.url, navigationAction.navigationType)
        if let url = navigationAction.request.url,
            navigationAction.navigationType == .other {

            // Check if the URL matches the one you want to modify
            if url.deletingLastPathComponent().absoluteString == "https://usher.ttvnw.net/api/channel/hls" {
                // Modify the URL if needed
                let modifiedURL = url.absoluteURL
                print(modifiedURL.query())
                let modifiedRequest = URLRequest(url: modifiedURL)

                // Load the modified request
                webView.load(modifiedRequest)

                // Cancel the original request
                decisionHandler(.cancel)
                return
            }
        }

        // Allow the request to proceed unchanged
        decisionHandler(.allow)
    }
}

#Preview {
    WebView()
}
