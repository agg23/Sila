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
    let delayLoading: Bool

    init(player: WebViewPlayer, streamableVideo: StreamableVideo, loading: Binding<Bool>, delayLoading: Bool = false) {
        self.player = player
        self.streamableVideo = streamableVideo
        self.loading = loading
        self.delayLoading = delayLoading

        // Using the Twitch embed API would prevent ads from playing "normally" and using the user's auth;
        // the user wouldn't count as a viewer of the stream
        //
        // Instead, we load the player.twitch.tv player directly with certain query params and inject the
        // embed API in to control the player (surprisingly this works)
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

                    try {
                        listener({
                          type: "message",
                          data: { eventName: event.data.eventName, params: event.data.params, namespace: "twitch-embed-player-proxy" },
                          source: window.parent
                        });
                    } catch (e) {
                        console.error(`Twitch event listener forwarding error: ${e}`);
                    }

                    return;
                  }
                }

                listener(event);
              }, other);
            };
            """, injectionTime: .atDocumentStart, forMainFrameOnly: true)

        // Required to expose window.Twitch API to page. We use this to inject events. This is not part of the normal embedded player
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

        let hideLoadingAndDisclosureScript = WKUserScript(source: """
            const style = document.createElement("style");
            style.textContent = `
              .tw-loading-spinner {
                display: none !important;
              }

              #channel-player-disclosures {
                display: none !important;
              }

              [data-a-target="content-classification-gate-overlay"] {
                display: none !important;
              }

              .content-overlay-gate__content {
                display: none !important;
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
        controller.addUserScript(hideLoadingAndDisclosureScript)
        controller.addUserScript(disableZoomScript)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        // Allow videos to not play in the native player
        configuration.allowsInlineMediaPlayback = true

        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Disable selection of anything in WebView
        configuration.preferences.isTextInteractionEnabled = false

        // Enable Airplay support (doesn't work)
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
        TwitchWebViewCoordinator(player: self.player, webView: self.webView, loading: self.loading, lastVideo: self.streamableVideo, lastDelayLoading: self.delayLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        #if DEBUG
        self.webView.isInspectable = true
        #endif
        self.webView.uiDelegate = context.coordinator
        self.webView.navigationDelegate = context.coordinator

        self.webView.configuration.userContentController.add(context.coordinator, name: "twitch")

        if !self.delayLoading {
            self.loadContent(self.webView)
        }

        return self.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        self.player.webView = uiView

        guard self.streamableVideo != context.coordinator.lastVideo || self.delayLoading != context.coordinator.lastDelayLoading else {
            // Nothing to do
            return
        }

        context.coordinator.lastVideo = self.streamableVideo
        context.coordinator.lastDelayLoading = self.delayLoading

        if !self.delayLoading {
            self.loadContent(uiView)
        }
    }

    private func loadContent(_ webView: WKWebView) {
        // Also supports quality=auto&volume=0.39&muted=false
        var urlVideoSegment: String
        switch self.streamableVideo {
        case .stream(let stream):
            // userLogin instead of userName as their userName may not be in Roman characters
            urlVideoSegment = "channel=\(stream.userLogin)"
        case .video(let video):
            urlVideoSegment = "video=\(video.id)"
        }

        DispatchQueue.main.async {
            self.loading?.wrappedValue = true
        }

        let url = "https://player.twitch.tv/?\(urlVideoSegment)&parent=twitch.tv&quality=\(self.player.quality)&volume=\(self.player.volume)&controls=false&autoplay=true&muted=false&player=popout"
        webView.load(URLRequest(url: URL(string: url)!))
    }
}

class TwitchWebViewCoordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    weak var player: WebViewPlayer?
    weak var webView: WKWebView?
    let loading: Binding<Bool>?

    var lastStatus: PlaybackStatus = .idle
    var retriedPlayCount = 0

    var lastVideo: StreamableVideo
    var lastDelayLoading: Bool

    init(player: WebViewPlayer, webView: WKWebView, loading: Binding<Bool>?, lastVideo: StreamableVideo, lastDelayLoading: Bool){
        self.player = player
        self.webView = webView
        self.loading = loading
        self.lastVideo = lastVideo
        self.lastDelayLoading = lastDelayLoading
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Page has loaded. Inject last step of script
        webView.evaluateJavaScript("""
            // Inject all known content restrictions into localStorage
            // This must run before the client is started
            const existingContentRestrictions = localStorage.getItem("content-classification-labels-acknowledged");
            const loggedIn = existingContentRestrictions?.loggedIn ?? {};
            const loggedOut = existingContentRestrictions?.loggedOut ?? {};

            const contentRestrictionTime = Date.now();
            const newContentRestrictions = {
                SexualThemes: contentRestrictionTime,
                ViolentGraphic: contentRestrictionTime,
                DrugsIntoxication: contentRestrictionTime,
                Gambling: contentRestrictionTime
            };
            localStorage.setItem("content-classification-labels-acknowledged", JSON.stringify({
                loggedIn: {
                    ...loggedIn,
                    ...newContentRestrictions,
                },
                loggedOut: {
                    ...loggedOut,
                    ...newContentRestrictions,
                },
            }));

            // Setup Twitch client
            // Calling this, rather than treating it as a constructor, creates the _player object
            // This will throw an error
            try {
                console.log("Creating Twitch _player object");
                Twitch.Player();
            } catch {

            }

            // Mark video as in current window
            Twitch._player._embedWindow = window;
        
            console.log("Waiting for Twitch ready");

            window.addEventListener("message", (event) => {
                if (event.data.eventName === "ready") {
                    console.log("Twitch client ready");
                    // TODO: Does this actually do anything?
                    Twitch._player.play();
                    // Twitch._player.setMute(false);
                    window.getVideoTag().muted = false;
                    console.log("Twitch._player", Twitch._player);
                }
            });
        """)



        // Click on the fullscreen mute popup
        // Taken from https://stackoverflow.com/a/61511955
        webView.evaluateJavaScript("""
            const waitForElm = (selector) => {
                return new Promise(resolve => {
                    if (document.querySelector(selector)) {
                        return resolve(document.querySelector(selector));
                    }

                    const observer = new MutationObserver(_mutations => {
                        if (document.querySelector(selector)) {
                            observer.disconnect();
                            resolve(document.querySelector(selector));
                        }
                    });

                    // If you get "parameter 1 is not of type 'Node'" error, see https://stackoverflow.com/a/77855838/492336
                    observer.observe(document.body, {
                        childList: true,
                        subtree: true
                    });
                });
            }

            // Bypass content restriction screen
            waitForElm("#channel-player-gate").then(gate => {
                const buttons = gate?.getElementsByTagName("button");

                if (buttons?.length > 0) {
                    console.log("Bypassing content restriction");
                    buttons[0].click();
                }
            });

            // Click on the fullscreen mute popup
            // Taken from https://stackoverflow.com/a/61511955
            waitForElm(".click-to-unmute__container").then(element => {
                console.log("Found click to unmute");
                element.click();
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
        let duration = params["duration"] as? NSNumber ?? 0.0
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

        if (status != self.lastStatus) {
            print(status)
        }

        if self.lastStatus == .buffering {
            if status == .idle {
                // If we've gone from buffering straight to idle, something is wrong
                if self.retriedPlayCount < 2 {
                    // Try to play again
                    print("Retrying play")
                    self.retriedPlayCount += 1
                    self.player?.play()
                } else {
                    // Something is very wrong
                    self.retriedPlayCount = 0
                    self.player?.reload()

                    DispatchQueue.main.async {
                        self.loading?.wrappedValue = true
                    }
                }
            } else if status != .buffering  {
                // Not idle, not buffering
                // Complete loading
                DispatchQueue.main.async {
                    self.loading?.wrappedValue = false
                }

                self.retriedPlayCount = 0
            }
        } else if status == .buffering {
            // lastStatus is not buffering
            DispatchQueue.main.async {
                self.loading?.wrappedValue = true
            }
        }

        self.lastStatus = status

        self.player?.applyEvent(TwitchEvent(currentTime: currentTime.doubleValue, duration: duration.doubleValue, muted: muted, playback: status, volume: volume.doubleValue, channelId: channelId, channel: channelName, quality: quality, availableQualities: qualities))
    }
}

#Preview {
    TwitchWebView(player: WebViewPlayer(), streamableVideo: .stream(STREAM_MOCK()), loading: .constant(false))
}
