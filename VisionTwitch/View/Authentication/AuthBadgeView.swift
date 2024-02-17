//
//  AuthBadgeView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI

struct AuthBadgeView: View {
    @State var showOauth = false

    var body: some View {
        Menu {
            Button("Log In") {
                self.showOauth = true
            }
        } label: {
            Image(systemName: "person.circle")
        }
        .buttonBorderShape(.circle)
        .sheet(isPresented: $showOauth) {
            OAuthView()
        }
    }
}

#Preview {
    AuthBadgeView()
}
