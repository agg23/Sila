//
//  APIErrorView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/24/24.
//

import SwiftUI

struct APIErrorView<TData, TDataAugment, TChange: Equatable>: View {
    let loader: Binding<DataLoader<TData, TDataAugment, TChange>>

    var body: some View {
        EmptyContentView(title: "An error occurred", systemImage: "exclamationmark.icloud.fill", description: "Failed to load requested content", buttonTitle: "Reload", buttonSystemImage: "arrow.clockwise", ignoreSafeArea: true) {
            Task {
                try? await self.loader.wrappedValue.refresh()
            }
        }
    }
}
