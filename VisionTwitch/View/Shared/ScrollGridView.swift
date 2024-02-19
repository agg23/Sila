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
                // 24px matches NavBar padding
                .padding([.horizontal, .bottom], 24)
                // We control our own padding to match NavBar. Only apply to bottom
                .safeAreaPadding(.bottom)
        }
    }
}
