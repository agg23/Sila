//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct MainWindowView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scene

    @Environment(AuthController.self) private var authController

    @Environment(Router.self) private var router

    @State private var showOauth = false

    var body: some View {
        let hasActiveVideo = self.router.activeVideo != nil

        ZStack {
            TabView(selection: self.router.tabBinding) {
                TabPage(title: "Following", systemImage: Icon.following, tab: .following) {
                    FollowedStreamsView()
                        .toolbar {
                            defaultToolbar()
                        }
                }

                TabPage(title: "Popular", systemImage: Icon.popular, tab: .popular) {
                    PopularView()
                        .toolbar(hasActiveVideo ? .hidden : .automatic, for: .tabBar)
                }

                TabPage(title: "Categories", systemImage: Icon.category, tab: .categories) {
                    CategoryListView()
                        .toolbar(hasActiveVideo ? .hidden : .automatic, for: .tabBar)
                }

                TabPage(title: "Search", systemImage: Icon.search, tab: .search) {
                    SearchView()
                        .toolbar {
                            defaultToolbar()
                        }
                        .toolbar(hasActiveVideo ? .hidden : .automatic, for: .tabBar)
                }

                TabPage(title: "Settings", systemImage: Icon.settings, tab: .settings) {
                    SettingsView()
                        .toolbar {
                            defaultToolbar()
                        }
                        .toolbar(hasActiveVideo ? .hidden : .automatic, for: .tabBar)
                }
            }
            .environment(\.disablePrimaryOrnaments, hasActiveVideo)
            .roundedBackground(.glass)
            .scaleEffect(hasActiveVideo ? 0.8 : 1.0)
            .opacity(hasActiveVideo ? 0.3 : 1.0)
            .offset(z: hasActiveVideo ? -100 : 0)
            .blur(radius: hasActiveVideo ? 10 : 0)
            .animation(.easeInOut(duration: 0.2), value: hasActiveVideo)

            if let activeVideo = self.router.activeVideo {
                TwitchEmbeddedContentView(streamableVideo: activeVideo)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.5).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        )
                        .animation(.easeInOut(duration: 0.2))
                    )
                    .zIndex(1)
                    // Dismiss any open video when we close the window
                    .onChange(of: self.scene) { _, newValue in
                        switch newValue {
                        case .background, .inactive:
                            self.router.activeVideo = nil
                        default:
                            break
                        }
                    }
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
            case .video(let video):
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

            let (streams, _) = try await api.helix(endpoint: .getStreams(userLogins: [channel]))

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
    MainWindowView()
}
