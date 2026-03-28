//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct MainWindowView: View {
    #if os(visionOS)
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    #endif

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.scenePhase) private var scene

    @Environment(AuthController.self) private var authController

    @Environment(Router.self) private var router

    @State private var showOauth = false

    var body: some View {
        #if !os(macOS)
        visionOSBody
        #else
        macOSBody
        #endif
    }

    #if !os(macOS)
    private var visionOSBody: some View {
        let hasActiveVideo = self.router.activeVideo != nil

        ZStack {
            // TODO: For some reason all windows expand their TabView ornament on hover in any window
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
            #if os(visionOS)
            .offset(z: hasActiveVideo ? -100 : 0)
            #endif
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
        .modifier(CommonMainWindowModifiers(router: self.router, authController: self.authController, openWindow: self.openWindow, showOauth: self.$showOauth))
    }
    #else
    private var macOSBody: some View {
        NavigationSplitView {
            List(selection: self.router.tabBinding) {
                Label("Following", systemImage: Icon.following)
                    .tag(SelectedTab.following)
                Label("Popular", systemImage: Icon.popular)
                    .tag(SelectedTab.popular)
                Label("Categories", systemImage: Icon.category)
                    .tag(SelectedTab.categories)
                Label("Search", systemImage: Icon.search)
                    .tag(SelectedTab.search)
                Label("Settings", systemImage: Icon.settings)
                    .tag(SelectedTab.settings)
            }
            .navigationTitle("Sila")
        } detail: {
            NavigationStack(path: self.router.pathBinding(for: self.router.tab)) {
                Group {
                    switch self.router.tab {
                    case .following:
                        FollowedStreamsView()
                            .navigationTitle("Following")
                    case .popular:
                        PopularView()
                            .navigationTitle("Popular")
                    case .categories:
                        CategoryListView()
                            .navigationTitle("Categories")
                    case .search:
                        SearchView()
                            .navigationTitle("Search")
                    case .settings:
                        SettingsView()
                            .navigationTitle("Settings")
                    }
                }
                .toolbar {
                    defaultToolbar()
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .category(game: let gameWrapper):
                        CategoryView(category: gameWrapper)
                    case .channel(user: let userWrapper):
                        ChannelView(channel: userWrapper)
                            .toolbar {
                                defaultToolbar()
                            }
                    }
                }
            }
        }
        .modifier(CommonMainWindowModifiers(router: self.router, authController: self.authController, openWindow: self.openWindow, showOauth: self.$showOauth))
    }
    #endif

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

// MARK: - Common Modifiers

private struct CommonMainWindowModifiers: ViewModifier {
    let router: Router
    let authController: AuthController
    let openWindow: OpenWindowAction
    @Binding var showOauth: Bool

    func body(content: Content) -> some View {
        content
            // Located at root of main window, as each of the tabs can be rendered at the same time
            .onChange(of: self.router.bufferedWindowOpen, initial: true) { _, newValue in
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
            }
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
            .sheet(isPresented: self.$showOauth) {
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
