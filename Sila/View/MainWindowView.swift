//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct MainWindowView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scene

    @Environment(AuthController.self) private var authController

    @Environment(Router.self) private var router

    @State private var showOauth = false

    /// Hack to prevent crash when saved stream windows are opened after reboot with a `nil` id
    /// Present in 1.1.1
    let id: String?

    var body: some View {
        TabView(selection: self.router.tabBinding) {
            TabPage(title: "Following", systemImage: Icon.following, tab: .following) {
                FollowedStreamsView()
                    .toolbar {
                        defaultToolbar()
                    }
            }

            TabPage(title: "Popular", systemImage: Icon.popular, tab: .popular, content: {
                PopularView()
            })

            TabPage(title: "Categories", systemImage: Icon.category, tab: .categories, content: {
                CategoryListView()
            })

            TabPage(title: "Search", systemImage: Icon.search, tab: .search) {
                SearchView()
                    .toolbar {
                        defaultToolbar()
                    }
            }

            TabPage(title: "Settings", systemImage: Icon.settings, tab: .settings, content: {
                SettingsView()
                    .toolbar {
                        defaultToolbar()
                    }
            })
        }
        .onAppear {
            if self.id == nil {
                // This window shouldn't exist
                dismissWindow()
            }
        }
        // Located at root of main window, as each of the tabs can be rendered at the same time
        .onChange(of: self.router.bufferedWindowOpen, initial: true, { _, newValue in
            guard let window = newValue else {
                return
            }

            self.router.bufferedWindowOpen = nil

            switch window {
            case .stream(let stream):
                openWindow(id: Window.stream, value: stream)
            case .vod(let video):
                openWindow(id: Window.vod, value: video)
            }
        })
        .onOpenURL { url in
            guard let host = url.host else {
                print("Malformed deeplink \(url)")
                return
            }

            var queryDict: [String: String] = [:]

            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
            queryItems.forEach { queryDict.updateValue($0.value?.lowercased() ?? "", forKey: $0.name.lowercased()) }

            switch host {
            case "watch":
                if let stream = queryDict["stream"] {
                    // Launch stream
                    self.open(stream: stream)
                    return
                }
                // TODO: Handle VoDs
            case "following":
                self.router.tab = .following
                return
            case "popular":
                self.router.tab = .popular
                return
            case "categories":
                self.router.tab = .categories
                return
            case "category":
                if let id = queryDict["id"] {
                    // Open particular category
                    self.router.tab = .categories
                    self.router.pushToActiveTab(route: .category(game: .id(id)))
                    return
                }
            default:
                print("Unknown deeplink \(url)")
            }

            print("Improperly handled deeplink \(url)")
        }
        .onReceive(self.authController.requestReauthSubject) { _ in
            // We need to reauth
            self.showOauth = true
        }
        .sheet(isPresented: $showOauth) {
            OAuthView()
        }
    }

    func open(stream channel: String) {
        Task {
            let api = try AuthShortcut.getAPI(self.authController)

            let (streams, _) = try await api.getStreams(userLogins: [channel])

            guard streams.count > 0 else {
                print("Channel \"\(channel)\" is not live.")
                return
            }

            let stream = streams[0]
            DispatchQueue.main.async {
                openWindow(id: Window.stream, value: stream)
            }
        }
    }
}

#Preview {
    MainWindowView(id: "main")
}
