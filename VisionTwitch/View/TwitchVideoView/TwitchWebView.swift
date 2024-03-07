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

    let streamableVideo: StreamableVideo

    let webView: WKWebView
    let player: WebViewPlayer

    let loading: Binding<Bool>?

    init(player: WebViewPlayer, streamableVideo: StreamableVideo, loading: Binding<Bool>) {
        self.player = player
        self.streamableVideo = streamableVideo
        self.loading = loading

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

//        let hideChromeScript = WKUserScript(source: """
//            const style = document.createElement("style");
//            style.textContent = `
//              video ~ * {
//                display: none;
//              }
//            `;
//
//            document.head.appendChild(style);
//            """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

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

        configuration.requiresUserActionForMediaPlayback = false
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Disable selection of anything in WebView
        configuration.preferences.isTextInteractionEnabled = false

        // Enable Airplay support (doesn't work)s
        configuration.allowsAirPlayForMediaPlayback = true

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        self.webView.isOpaque = false
        self.webView.scrollView.backgroundColor = .clear

        // Disable all interaction with WKWebView
        for subview in self.webView.scrollView.subviews {
            subview.isUserInteractionEnabled = false
        }
    }

    func makeCoordinator() -> TwitchWebViewCoordinator {
        TwitchWebViewCoordinator(player: self.player, webView: self.webView, loading: self.loading)
    }

    func makeUIView(context: Context) -> WKWebView {
        self.webView.isInspectable = true
        self.webView.uiDelegate = context.coordinator
        self.webView.navigationDelegate = context.coordinator

        self.webView.configuration.userContentController.add(context.coordinator, name: "twitch")

        // Also supports quality=auto&volume=0.39&muted=false
        var urlVideoSegment: String
        switch self.streamableVideo {
        case .stream(let stream):
            urlVideoSegment = "channel=\(stream.userName)"
        case .video(let video):
            urlVideoSegment = "video=\(video.id)"
        }

        DispatchQueue.main.async {
            self.loading?.wrappedValue = true
        }
        self.webView.load(URLRequest(url: URL(string: "https://player.twitch.tv/?\(urlVideoSegment)&parent=twitch.tv&quality=\(self.player.quality)&volume=\(self.player.volume)&controls=false&autoplay=true&muted=false&player=popout")!))

        return self.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        self.player.webView = uiView
    }
}

class TwitchWebViewCoordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    weak var player: WebViewPlayer?
    weak var webView: WKWebView?
    let loading: Binding<Bool>?

    var lastStatus: PlaybackStatus = .buffering

    init(player: WebViewPlayer, webView: WKWebView, loading: Binding<Bool>?){
        self.player = player
        self.webView = webView
        self.loading = loading
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

        // TODO: Vision doesn't seem to let you AirPlay
//        webView.evaluateJavaScript("""
//            (() => {
//                const video = document.getElementsByTagName("video");
//
//                if (video.length < 1) {
//                    console.error("No video tag found");
//                    return;
//                }
//
//                video[0].addEventListener("webkitplaybacktargetavailabilitychanged", () => {
//                    console.log("Showing picker");
//                    video[0].webkitShowPlaybackTargetPicker();
//                });
//            });
//        """)
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
        let body = message.body as! NSDictionary
        let params = body["params"] as? NSDictionary ?? [:]

        // Playback info
        let currentTime = params["currentTime"] as? NSNumber ?? 0.0
        let muted = ((params["muted"] as? NSNumber) ?? 0) == 1
        let playback = params["playback"] as? String ?? "Idle"
        let volume = params["volume"] as? NSNumber ?? 0.0
        let quality = params["quality"] as? String ?? "auto"

        let channelId = params["channelID"] as? String
        let channelName = params["channelName"] as? String
        let rawQualities = params["qualitiesAvailable"] as? [NSDictionary] ?? []

        // compactMap is not inferring type here for some reason
        let qualities: [VideoQuality] = rawQualities.compactMap { quality in
            let group = quality["group"] as? String

            guard let group = group else {
                return nil
            }

            return VideoQuality(quality: group, name: (quality["name"] as? String) ?? group)
        }

        let status: PlaybackStatus
        switch (playback.lowercased()) {
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

        if status != .buffering && self.lastStatus == .buffering {
            // Complete loading
            DispatchQueue.main.async {
                self.loading?.wrappedValue = false
            }
        }

        self.lastStatus = status

        self.player?.applyEvent(TwitchEvent(currentTime: currentTime.doubleValue, muted: muted, playback: status, volume: volume.doubleValue, channelId: channelId, channel: channelName, quality: quality, availableQualities: qualities))
    }
}

#Preview {
    TwitchWebView(player: WebViewPlayer(), streamableVideo: .stream(STREAM_MOCK()), loading: .constant(false))
}
