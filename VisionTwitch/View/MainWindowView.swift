//
//  MainWindowView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI

struct MainWindowView: View {
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                AuthBadgeView()
            }

            FollowedStreamsView()
        }
    }
}

#Preview {
    MainWindowView()
}
