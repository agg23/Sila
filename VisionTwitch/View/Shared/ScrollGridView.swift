//
//  ScrollGridView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/19/24.
//

import SwiftUI

struct ScrollGridView<Content: View>: View {
    var content: () -> Content

    var body: some View {
        ScrollView {
            content()
                // No padding on the top for NavBar
                // 10px matches NavBar padding
                .padding([.horizontal, .bottom], 10)
                // ScrollView has a safe area applied at the top that makes the content off center
                .safeAreaPadding([.horizontal, .bottom])
        }
    }
}
