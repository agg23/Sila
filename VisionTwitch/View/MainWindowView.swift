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
            AuthBadgeView()
                // Force filling window and position in top right corner
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.all, 32)

            FollowedStreamsView()
        }
    }
}

#Preview {
    MainWindowView()
}
