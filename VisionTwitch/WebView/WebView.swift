//
//  WebView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import WebKit
//import FlyingFox

enum PlaybackStatus {
    case playing
    case idle
    case buffering
    case ready
}

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let webView: WKWebView
//    let serverTask: Task<Void, Error>

    @Binding var reload: Bool
    @Binding var status: PlaybackStatus

    init(reload: Binding<Bool>, status: Binding<PlaybackStatus>) {
//        self.serverTask = Task {
//            let server = HTTPServer(port:8080)
//            await server.appendRoute("/") { request in
//                let channel = request.query["channel"]
//
//                let destination: String
//
//                if let channel = channel {
//                    destination = "channel=\(channel)"
//                } else {
//                    fatalError("Invalid request")
//                }
//
//                let html = """
//                    <html>
//                        <body>
//                            Hello world from Web
//                            <!--<iframe
//                                src="https://player.twitch.tv/?\(destination)&parent=localhost"
//                                height="100%"
//                                width="100%"
//                                autoplay>
//                            </iframe>-->
//                            <script src= "https://player.twitch.tv/js/embed/v1.js"></script>
//                            <div id="player"></div>
//                            <script type="text/javascript">
//                              var options = {
//                                width: "100%",
//                                height: "100%",
//                                channel: "barbarousking",
//                                //video: "<video ID>",
//                                //collection: "<collection ID>",
//                                // only needed if your site is also embedded on embed.example.com and othersite.example.com
//                                // parent: ["embed.example.com", "othersite.example.com"]
//                              };
//                              var player = new Twitch.Player("player", options);
//                              player.setVolume(0.5);
//
//                              window.player = player;
//                            </script>
//                        </body>
//                    </html>
//                """
//
//                return HTTPResponse(statusCode: .ok, body: html.data(using: .utf8)!)
//            }
//            do {
//                try await server.start()
//            } catch {
//                print(error)
//            }
//        }
        let overrideScript = WKUserScript(source: """
            // Set custom window parent
            window.parent = {
              postMessage: (message, options) => {
                window.postMessage(message, options);
              }
            }

            window._addEventListener = window.addEventListener;
            window.addEventListener = (type, listener, other) => {
              console.log("Registration for", type);
              window._addEventListener(type, (event) => {
                if (event.type === "message") {
                  if (event.data.namespace === "twitch-embed-player-proxy") {
                    // The client sends eventName: "UPDATE_STATE" from the iframe to the host page. The command `message` listener
                    // filters these out by checking for messages where the window is not the same as the parent. Due to our hacking,
                    // they will not be the same, so it will constantly warn.
                    // Instead, just ignore "UPDATE_STATE"
                    if (event.data.eventName === "UPDATE_STATE") {
                      window.webkit.messageHandlers.twitch.postMessage(event.data)
                      return;
                    }

                    listener({
                      type: "message",
                      data: { eventName: event.data.eventName, params: null, namespace: "twitch-embed-player-proxy" },
                      source: window.parent
                    });

                    return;
                  }
                }

                listener(event);
              }, other);
            };
            """, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        let injectPlayerAPI = WKUserScript(source: """
        console.log("Injecting player");
            const script = document.createElement("script");
            script.src = "https://player.twitch.tv/js/embed/v1.js";

            document.head.appendChild(script);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let hideChromeScript = WKUserScript(source: """
            const style = document.createElement("style");
            style.textContent = `
              video ~ * {
                display: none;
              }
            `;

            document.head.appendChild(style);
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        // One final script is injected after everything else has loaded in webView(:didFinish:)
        let controller = WKUserContentController()
        controller.addUserScript(overrideScript)
        controller.addUserScript(injectPlayerAPI)
        controller.addUserScript(hideChromeScript)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        // Allow videos to not play in the native player
        configuration.allowsInlineMediaPlayback = true

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        self._reload = reload
        self._status = status
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(status: self.$status)
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.isInspectable = true
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator

        webView.configuration.userContentController.add(context.coordinator, name: "twitch")

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
//        guard let url = Bundle.main.url(forResource: "index", withExtension: "html") else {
//            fatalError("Could not get index.html")
//        }

//        uiView.loadFileURL(url, allowingReadAccessTo: url)

        if self.reload {
//            self.webView.load(URLRequest(url: URL(string: "https://apple.com")!))
//            uiView.load(URLRequest(url: URL(string: "https://player.twitch.tv/?channel=nobletofu&parent=localhost")!))
//            uiView.load(URLRequest(url: URL(string: "http://localhost:8080?channel=nobletofu")!))
            uiView.load(URLRequest(url: URL(string: "https://player.twitch.tv/?channel=barbarousking&parent=twitch.tv&player=popout")!))
            DispatchQueue.main.async {
                self.reload = false
            }
        }

        if context.coordinator.cachedStatus != self.status {
            context.coordinator.cachedStatus = self.status

            switch(self.status) {
            case .playing:
                uiView.evaluateJavaScript("""
                    Twitch._player.play()
                """)
            case .idle:
                uiView.evaluateJavaScript("""
                    Twitch._player.pause()
                """)
            default:
                // Do nothing
                break
            }
        }
    }
}

class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var cachedStatus: PlaybackStatus = .idle

    @Binding var status: PlaybackStatus

    init(status: Binding<PlaybackStatus>){
        _status = status
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Page has loaded. Inject last step of script
        webView.evaluateJavaScript("""
            // Setup Twitch client
            // Calling this, rather than treating it as a constructor, creates the _player object
            // This will throw an error
            try {
                Twitch.Player();
            } catch {

            }

            // Mark video as in current window
            Twitch._player._embedWindow = window;
        """)
    }

//     func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        self.parent.reload()
//    }
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        print(navigationAction.request.url, navigationAction.navigationType)
//        if let url = navigationAction.request.url,
//            navigationAction.navigationType == .other {
//
//            // Check if the URL matches the one you want to modify
//            if url.deletingLastPathComponent().absoluteString == "https://usher.ttvnw.net/api/channel/hls" {
//                // Modify the URL if needed
//                let modifiedURL = url.absoluteURL
//                print(modifiedURL.query())
//                let modifiedRequest = URLRequest(url: modifiedURL)
//
//                // Load the modified request
//                webView.load(modifiedRequest)
//
//                // Cancel the original request
//                decisionHandler(.cancel)
//                return
//            }
//        }
//
//        // Allow the request to proceed unchanged
//        decisionHandler(.allow)
//    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//        print(message)
        let body = message.body as! NSDictionary
        let params = body["params"] as? NSDictionary ?? [:]

        let currentTime = params["currentTime"] as? NSNumber ?? 0.0
        let muted = ((params["muted"] as? NSNumber) ?? 0) == 1
        let playback = params["playback"] as? NSString ?? "Idle"
        let volume = params["volume"] as? NSNumber ?? 0.0

        print("Time: \(currentTime), muted: \(muted), playback: \(playback), volume: \(volume)")
    }
}

#Preview {
    WebView(reload: .constant(false), status: .constant(.idle))
}
