//
//  DataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/17/24.
//

import SwiftUI
import Twitch

struct DataView<T, E: Error, Content: View, Loading: View, ErrorView: View>: View {
    private let taskClosure: (_: Helix) -> Task<T, E>

    private let content: (_: T) -> Content
    private let loading: (_: T?) -> Loading
    private let error: (_: E) -> ErrorView

    @State private var state: DataProvider<T, E>?

    init(taskClosure: @escaping (_: Helix) -> Task<T, E>, @ViewBuilder content: @escaping (_: T) -> Content, @ViewBuilder loading: @escaping (_: T?) -> Loading, @ViewBuilder error: @escaping (_: E) -> ErrorView) {
        self.taskClosure = taskClosure

        self.content = content
        self.loading = loading
        self.error = error
    }

    var body: some View {
        // TODO: Remove
        ZStack {
            if let data = self.state?.data {
                switch data {
                case .success(let data):
                    self.content(data)
                case .failure(let error):
                    self.error(error)
                case .loading(let data):
                    self.loading(data)
                case .noData:
                    Text("no data")
                }
            } else {
                // Do nothing
            }
        }
        .onAppear {
            self.state = DataProvider(taskClosure: taskClosure)
        }
    }
}

extension DataView where Loading == CustomProgressView {
    init(taskClosure: @escaping (_: Helix) -> Task<T, E>, @ViewBuilder content: @escaping (_: T) -> Content, @ViewBuilder error: @escaping (_: E) -> ErrorView) {
        self.init(taskClosure: taskClosure, content: content, loading: { _ in
            CustomProgressView()
        }, error: error)
    }
}

struct CustomProgressView: View {
    var body: some View {
        ProgressView()
    }
}
