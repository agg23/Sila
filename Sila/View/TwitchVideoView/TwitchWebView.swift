//
//  WebView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/2/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
#if !os(tvOS)
import WebKit
#endif

private let twitchScriptMessageHandlerName = "twitch"

enum TwitchUserScriptInjectionTime {
    case atDocumentStart
    case atDocumentEnd
}

struct TwitchUserScriptSpec {
    let source: String
    let injectionTime: TwitchUserScriptInjectionTime
    let forMainFrameOnly: Bool
}

@MainActor
protocol InternalTwitchWebViewDelegate: AnyObject {
    func internalWebViewDidFinishLoad(_ webView: any InternalTwitchWebView)
    func internalWebViewDidReceiveScriptMessageBody(_ body: Any)
}

@MainActor
protocol InternalTwitchWebView: AnyObject {
    var platformView: TwitchWebViewPlatformView { get }

    func installStartupScripts(_ scripts: [TwitchUserScriptSpec], messageHandlerName: String, delegate: any InternalTwitchWebViewDelegate)
    func load(url: URL)
    func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)?)
    func reload()
    func stopLoading()
    func tearDownDelegates()
    func removeScriptMessageHandler(named name: String)
    func clearPage()
    func removeFromSuperview()
}

#if canImport(UIKit)
typealias TwitchWebViewRepresentable = UIViewRepresentable
typealias TwitchWebViewPlatformView = UIView
#else
typealias TwitchWebViewRepresentable = NSViewRepresentable
typealias TwitchWebViewPlatformView = NSView
#endif

// Any slowness observed with this opening is solely due to Xcode being connected to the app launch
// Launching the app directly on device will result in instant loading of the web view
struct TwitchWebView: TwitchWebViewRepresentable {
    let streamableVideo: StreamableVideo
    let player: WebViewPlayer
    let delayLoading: Bool

    init(player: WebViewPlayer, streamableVideo: StreamableVideo, delayLoading: Bool = false) {
        self.player = player
        self.streamableVideo = streamableVideo
        self.delayLoading = delayLoading
    }

    func makeCoordinator() -> TwitchWebViewController {
        TwitchWebViewController(player: self.player, lastVideo: self.streamableVideo, lastDelayLoading: self.delayLoading)
    }

    #if canImport(UIKit)
    func makeUIView(context: Context) -> TwitchWebViewPlatformView {
        self.makePlatformView(context: context)
    }

    func updateUIView(_ uiView: TwitchWebViewPlatformView, context: Context) {
        self.updatePlatformView(context: context)
    }
    #else
    func makeNSView(context: Context) -> TwitchWebViewPlatformView {
        self.makePlatformView(context: context)
    }

    func updateNSView(_ nsView: TwitchWebViewPlatformView, context: Context) {
        self.updatePlatformView(context: context)
    }
    #endif

    private func makePlatformView(context: Context) -> TwitchWebViewPlatformView {
        let webView = self.makeInternalWebView()
        context.coordinator.attach(webView: webView)
        self.player.attachBackend(context.coordinator)

        if !self.delayLoading {
            context.coordinator.loadContent(for: self.streamableVideo)
        }

        return webView.platformView
    }

    private func updatePlatformView(context: Context) {
        guard context.coordinator.update(streamableVideo: self.streamableVideo, delayLoading: self.delayLoading) else {
            return
        }

        if !self.delayLoading {
            context.coordinator.loadContent(for: self.streamableVideo)
        }
    }

    private func makeInternalWebView() -> any InternalTwitchWebView {
        #if os(tvOS)
        TVPrivateTwitchWebViewAdapter()
        #else
        WKTwitchWebViewAdapter()
        #endif
    }
}

@MainActor
final class TwitchWebViewController: NSObject, TwitchPlaybackBackend, InternalTwitchWebViewDelegate {
    weak var player: WebViewPlayer?

    private var webView: (any InternalTwitchWebView)?

    var lastStatus: PlaybackStatus = .idle
    var retriedPlayCount = 0

    var lastVideo: StreamableVideo
    var lastDelayLoading: Bool

    init(player: WebViewPlayer, lastVideo: StreamableVideo, lastDelayLoading: Bool) {
        self.player = player
        self.lastVideo = lastVideo
        self.lastDelayLoading = lastDelayLoading
    }

    func attach(webView: any InternalTwitchWebView) {
        self.webView = webView
        webView.installStartupScripts(Self.startupScripts, messageHandlerName: twitchScriptMessageHandlerName, delegate: self)
    }

    @discardableResult
    func update(streamableVideo: StreamableVideo, delayLoading: Bool) -> Bool {
        guard streamableVideo != self.lastVideo || delayLoading != self.lastDelayLoading else {
            return false
        }

        self.lastVideo = streamableVideo
        self.lastDelayLoading = delayLoading
        return true
    }

    func loadContent(for streamableVideo: StreamableVideo) {
        var urlVideoSegment: String
        switch streamableVideo {
        case .stream(let stream):
            // userLogin instead of userName as their userName may not be in Roman characters
            urlVideoSegment = "channel=\(stream.userLogin)"
        case .video(let video):
            urlVideoSegment = "video=\(video.id)"
        }

        self.player?.loading = true

        let quality = self.player?.quality ?? "auto"
        let volume = self.player?.volume ?? 0.5
        let url = URL(string: "https://player.twitch.tv/?\(urlVideoSegment)&parent=twitch.tv&quality=\(quality)&volume=\(volume)&controls=false&autoplay=true&muted=false&player=popout")!
        self.webView?.load(url: url)
    }

    func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)?) {
        self.webView?.evaluateJavaScript(script, completion: completion)
    }

    func reload() {
        self.webView?.reload()
    }

    func dispose() {
        self.webView?.evaluateJavaScript(#"""
            try {
                Twitch._player.pause();
            } catch (e) {
                console.error(`Failed to pause during cleanup: ${e}`);
            }
        """#, completion: nil)
        self.webView?.stopLoading()
        self.webView?.tearDownDelegates()
        self.webView?.removeScriptMessageHandler(named: twitchScriptMessageHandlerName)
        self.webView?.clearPage()
        self.webView?.removeFromSuperview()
        self.webView = nil
    }

    func internalWebViewDidFinishLoad(_ webView: any InternalTwitchWebView) {
        webView.evaluateJavaScript(Self.playerBootstrapScript, completion: nil)
        webView.evaluateJavaScript(Self.clickToUnmuteScript, completion: nil)
    }

    func internalWebViewDidReceiveScriptMessageBody(_ body: Any) {
        let body = body as! NSDictionary
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

                    self.player?.loading = true
                }
            } else if status != .buffering  {
                // Not idle, not buffering
                // Complete loading
                self.player?.loading = false

                self.retriedPlayCount = 0
            }
        } else if status == .buffering {
            // lastStatus is not buffering
            self.player?.loading = true
        }

        self.lastStatus = status

        self.player?.applyEvent(TwitchEvent(currentTime: currentTime.doubleValue, duration: duration.doubleValue, muted: muted, playback: status, volume: volume.doubleValue, channelId: channelId, channel: channelName, quality: quality, availableQualities: qualities))
    }

    private static var startupScripts: [TwitchUserScriptSpec] {
        [
            TwitchUserScriptSpec(source: #"""
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
                """#, injectionTime: .atDocumentStart, forMainFrameOnly: true),
            TwitchUserScriptSpec(source: #"""
                const script = document.createElement("script");
                script.src = "https://player.twitch.tv/js/embed/v1.js";

                document.head.appendChild(script);
                """#, injectionTime: .atDocumentEnd, forMainFrameOnly: true),
            TwitchUserScriptSpec(source: #"""
                window.getVideoTag = () => {
                    const video = document.getElementsByTagName("video");

                    if (video.length < 1) {
                        throw new Error("No video tag found");
                    }

                    return video;
                };
                """#, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            TwitchUserScriptSpec(source: #"""
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
                """#, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
            TwitchUserScriptSpec(source: #"""
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                var head = document.getElementsByTagName('head')[0];
                head.appendChild(meta);
                """#, injectionTime: .atDocumentEnd, forMainFrameOnly: false),
        ]
    }

    private static let playerBootstrapScript = #"""
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
        """#

    private static let clickToUnmuteScript = #"""
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
        """#
}

#if !os(tvOS)
final class WKTwitchWebViewAdapter: NSObject, InternalTwitchWebView, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    weak var delegate: (any InternalTwitchWebViewDelegate)?

    let webView: WKWebView

    override init() {
        self.webView = Self.makeConfiguredWebView()
        super.init()
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
    }

    var platformView: TwitchWebViewPlatformView {
        self.webView
    }

    private static func makeConfiguredWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()

        #if canImport(UIKit)
        // Allow videos to not play in the native player
        configuration.allowsInlineMediaPlayback = true

        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Disable selection of anything in WebView
        configuration.preferences.isTextInteractionEnabled = false
        #endif

        // Enable Airplay support (doesn't work)
        configuration.allowsAirPlayForMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)

        #if canImport(UIKit)
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear

        // Disable all interaction with WKWebView
        for subview in webView.scrollView.subviews {
            subview.isUserInteractionEnabled = false
        }
        #else
        webView.setValue(false, forKey: "drawsBackground")
        #endif

        #if DEBUG
        webView.isInspectable = true
        #endif

        return webView
    }

    func installStartupScripts(_ scripts: [TwitchUserScriptSpec], messageHandlerName: String, delegate: any InternalTwitchWebViewDelegate) {
        self.delegate = delegate

        let controller = self.webView.configuration.userContentController
        for script in scripts {
            let injectionTime: WKUserScriptInjectionTime
            switch script.injectionTime {
            case .atDocumentStart:
                injectionTime = .atDocumentStart
            case .atDocumentEnd:
                injectionTime = .atDocumentEnd
            }

            controller.addUserScript(WKUserScript(source: script.source, injectionTime: injectionTime, forMainFrameOnly: script.forMainFrameOnly))
        }

        controller.add(self, name: messageHandlerName)
    }

    func load(url: URL) {
        self.webView.load(URLRequest(url: url))
    }

    func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)?) {
        self.webView.evaluateJavaScript(script, completionHandler: completion)
    }

    func reload() {
        self.webView.reload()
    }

    func stopLoading() {
        self.webView.stopLoading()
    }

    func tearDownDelegates() {
        self.webView.navigationDelegate = nil
        self.webView.uiDelegate = nil
    }

    func removeScriptMessageHandler(named name: String) {
        self.webView.configuration.userContentController.removeScriptMessageHandler(forName: name)
    }

    func clearPage() {
        self.webView.loadHTMLString("", baseURL: nil)
    }

    func removeFromSuperview() {
        self.webView.removeFromSuperview()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.delegate?.internalWebViewDidFinishLoad(self)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.internalWebViewDidReceiveScriptMessageBody(message.body)
    }
}
#endif

#Preview {
    TwitchWebView(player: WebViewPlayer(), streamableVideo: .stream(STREAM_MOCK()))
}
