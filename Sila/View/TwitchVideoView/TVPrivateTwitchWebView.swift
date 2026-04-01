//
//  TVPrivateTwitchWebView.swift
//  Sila
//
//  Created by Adam Gastineau on 3/31/26.
//

#if os(tvOS)
import UIKit

@MainActor
final class TVPrivateTwitchWebViewAdapter: NSObject, InternalTwitchWebView, TVPrivateWebViewNavigationDelegate {
    weak var delegate: (any InternalTwitchWebViewDelegate)?

    let privateWebView: TVPrivateWebView

    override init() {
        self.privateWebView = TVPrivateWebView(frame: .zero)
        super.init()
    }

    var platformView: TwitchWebViewPlatformView {
        self.privateWebView
    }

    func installStartupScripts(_ scripts: [TwitchUserScriptSpec], messageHandlerName: String, delegate: any InternalTwitchWebViewDelegate) {
        self.delegate = delegate

        _ = self.privateWebView.prepareRuntimeIfNeeded()
        _ = self.privateWebView.createRuntimeWebView()
        self.privateWebView.delegate = self
        _ = self.privateWebView.installScriptMessageHandlerNamed(messageHandlerName)

        for script in scripts {
            let injectionTime: Int
            switch script.injectionTime {
            case .atDocumentStart:
                injectionTime = 0
            case .atDocumentEnd:
                injectionTime = 1
            }

            self.privateWebView.addUserScript(script.source, injectionTime: injectionTime, forMainFrameOnly: script.forMainFrameOnly)
        }
    }

    func load(url: URL) {
        self.privateWebView.loadURLString(url.absoluteString)
    }

    func evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)?) {
        self.privateWebView.evaluateJavaScript(script, completion: completion)
    }

    func reload() {
        self.privateWebView.reloadPage()
    }

    func stopLoading() {
        self.privateWebView.stopLoadingPage()
    }

    func tearDownDelegates() {
        self.privateWebView.delegate = nil
    }

    func removeScriptMessageHandler(named name: String) {
        self.privateWebView.removeScriptMessageHandlerNamed(name)
    }

    func clearPage() {
        self.privateWebView.loadHTMLString("")
    }

    func removeFromSuperview() {
        self.privateWebView.removeAllUserScripts()
        self.privateWebView.removeFromSuperview()
    }

    func privateWebViewDidFinishLoad(_ webView: Any) {
        self.delegate?.internalWebViewDidFinishLoad(self)
    }

    func privateWebView(_ webView: Any, didReceiveScriptMessageBody body: Any) {
        self.delegate?.internalWebViewDidReceiveScriptMessageBody(body)
    }
}
#endif
