//
//  SearchView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/23/24.
//

import SwiftUI
import Twitch

struct SearchView: View {
    @Environment(\.authController) private var authController

    @State private var loader = DataLoader<[Twitch.Category], String>()
    @State private var text = ""

    var body: some View {
        let _ = Self._printChanges()

        Group {
            switch self.$loader.wrappedValue.get(task: {
                guard let api = self.authController.status.api(), self.text.count > 0 else {
                    return []
                }

                let text = self.text

                try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)

                if Task.isCancelled {
                    print("Cancelled in sleep")
                    return []
                }

                print("Sending HTTP for \(text)")

                let (categories, _) = try await api.searchCategories(for: text)
                print("Results for \(text)")
                return categories
            }, onChange: self.text) {
            case .idle:
                Text("No data")
            case .loading(let data):
                ProgressView()
            case .finished(let data):
                List(data) { item in
                    Text(item.name)
                }
            case .error:
                Text("An error occurred")
            }
        }
        .searchable(text: self.$text, placement: .navigationBarDrawer)
    }
}

#Preview {
    SearchView()
}
