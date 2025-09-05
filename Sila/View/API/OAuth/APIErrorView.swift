//
//  APIErrorView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/24/24.
//

import SwiftUI

struct APIErrorView<TData, TDataAugment, TChange: Equatable>: View {
    let title: String
    let description: String
    let loader: Binding<DataLoader<TData, TDataAugment, TChange>>

    init(loader: Binding<DataLoader<TData, TDataAugment, TChange>>, title: String = "An error occurred", description: String = "Failed to load requested content") {
        self.title = title
        self.description = description
        self.loader = loader
    }

    var body: some View {
        EmptyContentView(title: self.title, systemImage: "exclamationmark.icloud.fill", description: self.description, buttonTitle: "Reload", buttonSystemImage: "arrow.clockwise", ignoreSafeArea: true) {
            Task {
                try? await self.loader.wrappedValue.refresh()
            }
        }
    }
}
