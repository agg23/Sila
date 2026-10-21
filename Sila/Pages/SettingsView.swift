//
//  SettingsView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 3/4/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(Router.self) private var router
    #if os(tvOS)
    @Environment(AuthController.self) private var authController
    #endif

    @AppStorage(Setting.filterLanguage) var filterLanguage: String = "en"
    @AppStorage(Setting.hideMature) var hideMature: Bool = false
    @AppStorage(Setting.disableIncrementingStreamDuration) var disableIncrementingStreamDuration: Bool = false

    @AppStorage(Setting.smallBorderRadius) var smallBorderRadius: Bool = false
    @AppStorage(Setting.dimSurroundings) var dimSurroundings: Bool = false

    var body: some View {
        VStack {
            Form {
                #if os(tvOS)
                Section("Account") {
                    if let authUser = self.authController.status.user() {
                        LabeledContent("Signed In", value: authUser.username)
                        Button("Log Out", role: .destructive) {
                            self.authController.logOut()
                        }
                    } else {
                        Button("Log In") {
                            self.authController.requestLoginReauthWithUI()
                        }
                    }
                }
                #endif

                Section("Navigation") {
                    LanguageFilterPickerView(language: self.$filterLanguage, title: "Default Filter Language")
                    Toggle(isOn: self.$hideMature) {
                        Text("Hide Mature Streams")
                        Text("Will not hide mature streams from streamers you follow")
                    }
                    Toggle(isOn: self.$disableIncrementingStreamDuration) {
                        Text("Disable Updating Stream Durations")
                        Text("Minimizes motion by displaying a static duration for a live stream")
                    }
                }

                #if !os(tvOS)
                Section("Playback") {
                    Toggle("See More in Video Corners", isOn: self.$smallBorderRadius)
                    Toggle("Dim Surroundings", isOn: self.$dimSurroundings)
                }
                #endif

                Section {
                    NavigationLink {
                        LicensesView()
                    } label: {
                        Label("Licenses", systemImage: "newspaper")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    PreviewNavStack {
        SettingsView()
    }
}
