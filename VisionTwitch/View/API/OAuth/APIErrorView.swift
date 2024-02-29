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
        VStack {
            Text("An error occurred")
            Button {
                Task {
                    try? await self.loader.wrappedValue.refresh()
                }
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
        }
    }
}
