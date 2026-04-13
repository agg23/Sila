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
    let setIsLoading: (_ status: Bool) -> Void
    let completed: (_ status: OAuthStatus) -> Void

    init(setIsLoading: @escaping (_ status: Bool) -> Void, completed: @escaping (_ status: OAuthStatus) -> Void) {
        // Hide Twitch sign up, social login ("Continue with..."), "or" divider,
        // and "Trouble logging in" elements
        //
        // Twitch sign up is problematic for App Store review, and doesn't make much
        // sense in the app, as the user cannot follow new channels
        // "Trouble logging in" doesn't work because it links out, so we also hide it
        let hideSignUpAndTroubleLoggingIn = WKUserScript(source: """
            (function() {
              var ATTR = "data-sila-hide";

              var style = document.createElement("style");
              style.textContent = `
                [${ATTR}="true"] {
                  display: none !important;
                }
                
                /* Fix missing bottom scroll in OAuth Authorize page */
                .scrollable-area {
                  height: 100dvh !important;
                }
              `;
              document.head.appendChild(style);

              function hide(element) {
                if (element && element.getAttribute(ATTR) !== "true") {
                  element.setAttribute(ATTR, "true");
                }
              }

              function process() {
                // Hide "Trouble logging in?"
                var recoveryLinks = document.querySelectorAll('a[href*="account-recovery"]');
                for (var i = 0; i < recoveryLinks.length; i++) {
                  var container = recoveryLinks[i].closest("div");
                  if (container) {
                    hide(container);
                  }
                }

                // Hide "Need help?" on 2FA page (external links don't work right)
                var helpLinks = document.querySelectorAll('a[href*="help.twitch.tv"]');
                for (var i = 0; i < helpLinks.length; i++) {
                  var container = helpLinks[i].closest("div");
                  if (container) {
                    hide(container);
                  }
                }

                var form = document.querySelector('form[name="login-submit-form"]')
                        || document.querySelector('form:has(input[autocomplete="username"])');
                if (!form) {
                  return;
                }

                var submitBtn = form.querySelector('button[type="submit"]');
                if (!submitBtn) {
                  return;
                }

                // Walk up from the submit button to find the container level
                // where it sits alongside other buttons (social logins, sign up)
                var submitWrapper = submitBtn.parentElement;
                while (submitWrapper && submitWrapper.parentElement) {
                  var parent = submitWrapper.parentElement;
                  var siblings = Array.from(parent.children);
                  var hasOtherButtons = siblings.some(function(sibling) {
                    return sibling !== submitWrapper
                        && sibling.querySelector("button")
                        && !sibling.contains(submitBtn);
                  });

                  if (hasOtherButtons && siblings.length > 2) {
                    // Hide every sibling that does not contain the submit button
                    for (var i = 0; i < siblings.length; i++) {
                      if (!siblings[i].contains(submitBtn)) {
                        hide(siblings[i]);
                      }
                    }

                    break;
                  }

                  // Don't walk past the form
                  if (parent === form || parent.tagName === "FORM") {
                    break;
                  }
                  
                  submitWrapper = parent;
                }
              }

              if (document.body) {
                process();
              }

              // Re-run on every DOM change in case there's a rerender
              var observer = new MutationObserver(function() { process(); });
              observer.observe(document.documentElement, {
                childList: true,
                subtree: true
              });
            })();
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)

        let controller = WKUserContentController()
        controller.addUserScript(hideSignUpAndTroubleLoggingIn)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        self.setIsLoading = setIsLoading
        self.completed = completed
    }

    func makeCoordinator() -> OAuthWebViewCoordinator {
        OAuthWebViewCoordinator(webView: self.webView, setIsLoading: self.setIsLoading, completed: self.completed)
    }

    func makeUIView(context: Context) -> WKWebView {
        self.webView.isInspectable = true
        self.webView.uiDelegate = context.coordinator
        self.webView.navigationDelegate = context.coordinator
        self.webView.isOpaque = false
        // Match Twitch background color
        self.webView.scrollView.backgroundColor = UIColor(red: 14.0/255.0, green: 14.0/255.0, blue: 16.0/255.0, alpha: 1.0)

        var oauthUrl = URL(string: "https://id.twitch.tv/oauth2/authorize")!
        oauthUrl.append(queryItems: [
            URLQueryItem(name: "client_id", value: AuthController.CLIENT_ID),
            URLQueryItem(name: "redirect_uri", value: AuthController.REDIRECT_URL),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "scope", value: "chat:edit chat:read user:read:follows")
        ])
        self.webView.load(URLRequest(url: oauthUrl))

        return self.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.webView = self.webView
        context.coordinator.completed = self.completed
    }
}

class OAuthWebViewCoordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
    weak var webView: WKWebView?
    var setIsLoading: (_ status: Bool) -> Void
    var completed: (_ status: OAuthStatus) -> Void

    init(webView: WKWebView, setIsLoading: @escaping (_ status: Bool) -> Void, completed: @escaping (_ status: OAuthStatus) -> Void){
        self.webView = webView
        self.setIsLoading = setIsLoading
        self.completed = completed
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.setIsLoading(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.setIsLoading(false)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        self.setIsLoading(false)
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

    } completed: { _ in

    }
}
