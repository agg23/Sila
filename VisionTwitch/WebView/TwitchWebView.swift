//
//  WebView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
import WebKit

struct TwitchWebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let channel: String

    let webView: WKWebView
    let player: WebViewPlayer

    init(player: WebViewPlayer, channel: String) {
        self.player = player
        self.channel = channel

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
                      data: { eventName: event.data.eventName, params: event.data.params, namespace: "twitch-embed-player-proxy" },
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
            const script = document.createElement("script");
            script.src = "https://player.twitch.tv/js/embed/v1.js";

            document.head.appendChild(script);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let injectVideoGetter = WKUserScript(source: """
            window.getVideoTag = () => {
                const video = document.getElementsByTagName("video");

                if (video.length < 1) {
                    throw new Error("No video tag found");
                }

                return video;
            };
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        let hideChromeScript = WKUserScript(source: """
            const style = document.createElement("style");
            style.textContent = `
              video ~ * {
                display: none;
              }
            `;

            document.head.appendChild(style);
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        let disableZoomScript = WKUserScript(source: """
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
            var head = document.getElementsByTagName('head')[0];
            head.appendChild(meta);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        // One final script is injected after everything else has loaded in webView(:didFinish:)
        let controller = WKUserContentController()
        controller.addUserScript(overrideScript)
        controller.addUserScript(injectPlayerAPI)
        controller.addUserScript(injectVideoGetter)
        // TODO: It seems like hiding the Chrome is breaking the video playback somehow
//        controller.addUserScript(hideChromeScript)
        controller.addUserScript(disableZoomScript)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        // Allow videos to not play in the native player
        configuration.allowsInlineMediaPlayback = true

        // Disable selection of anything in WebView
        configuration.preferences.isTextInteractionEnabled = false

        // Enable Airplay support
        configuration.allowsAirPlayForMediaPlayback = true

        self.webView = WKWebView(frame: .zero, configuration: configuration)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(player: self.player, webView: self.webView)
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.isInspectable = true
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator

        webView.configuration.userContentController.add(context.coordinator, name: "twitch")

        // Also supports quality=auto&volume=0.39&muted=false
        webView.load(URLRequest(url: URL(string: "https://player.twitch.tv/?channel=\(self.channel)&parent=twitch.tv&controls=false&player=popout")!))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        self.player.webView = uiView
    }
}

class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    weak var player: WebViewPlayer?
    weak var webView: WKWebView?

    init(player: WebViewPlayer, webView: WKWebView){
        self.player = player
        self.webView = webView
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

            window.addEventListener("message", (event) => {
                if (event.data.eventName === "ready") {
                    console.log("Ready");
                    // TODO: Does this actually do anything?
                    Twitch._player.play();
                    // Twitch._player.setMute(false);
                    window.getVideoTag().muted = false;
                    console.log(Twitch._player);
                }
            });
        """)

        webView.evaluateJavaScript("""
            (() => {
                const video = document.getElementsByTagName("video");

                if (video.length < 1) {
                    console.error("No video tag found");
                    return;
                }

                video[0].addEventListener("webkitplaybacktargetavailabilitychanged", () => {
                    console.log("Showing picker");
                    video[0].webkitShowPlaybackTargetPicker();
                });
            });
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

//        print("Time: \(currentTime), muted: \(muted), playback: \(playback), volume: \(volume)")

        let status: PlaybackStatus
        switch (playback.lowercased) {
        case "idle":
            status = .idle
        case "buffering":
            status = .buffering
        case "playing":
            status = .playing
        case "ready":
            status = .ready
        default:
            print("Unknown playback status \(playback)")
            status = .idle
        }

        self.player?.applyEvent(TwitchEvent(currentTime: currentTime.doubleValue, muted: muted, playback: status, volume: volume.doubleValue))
    }
}

#Preview {
    TwitchWebView(player: WebViewPlayer(), channel: "BarbarousKing")
}
