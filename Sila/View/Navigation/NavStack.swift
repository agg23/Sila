//
//  NavStack.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/18/24.
//

import SwiftUI

struct NavStack<Content: View>: View {
    @State var router = Router()

    let content: () -> Content

    var body: some View {
        NavigationStack(path: self.router.pathBinding) {
            self.content()
        }
        .environment(self.router)
    }
}
