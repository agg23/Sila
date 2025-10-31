//
//  SearchRecentsView.swift
//  Sila
//
//  Created for issue #42
//

import SwiftUI

struct SearchRecentsView: View {
    @ObservedObject private var recentsStore = RecentsStore.shared
    let onSelectHistoryItem: (String) -> Void
    
    var body: some View {
        if !recentsStore.searchRecents.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Search History")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button("Clear") {
                        recentsStore.clearSearchRecents()
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 16)
                
                VStack(spacing: 8) {
                    ForEach(recentsStore.searchRecents, id: \.self) { query in
                        Button {
                            self.onSelectHistoryItem(query)
                        } label: {
                            HStack {
                                Image(systemName: Icon.search)
                                    .foregroundColor(.secondary)
                                Text(query)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(12)
                            .background(.tertiary)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .buttonBorderShape(.roundedRectangle(radius: 10))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
