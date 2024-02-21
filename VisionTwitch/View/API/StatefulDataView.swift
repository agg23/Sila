//
//  StatefulDataView.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/20/24.
//

import SwiftUI
import Twitch

//struct StatefulDataView<T, E: Error, Content: View, Loading: View, ErrorView: View>: View {
//    private let taskClosure: (_: Helix) -> Task<T, E>
//
//    private let content: (_: T) -> Content
//    private let loading: (_: T?) -> Loading
//    private let error: (_: E) -> ErrorView
//
//    private let requiresAuth: Bool
//
//    @State private var state: DataProvider<T, E>?
//    @State private var hasRendered = false
//
//    var body: some View {
//        DataView(provider: <#T##DataProvider<T, Error>?#>, content: <#T##(T) -> View#>, loading: <#T##(T?) -> View#>, error: <#T##(Error) -> View#>, requiresAuth: <#T##Bool#>)
//    }
//}
