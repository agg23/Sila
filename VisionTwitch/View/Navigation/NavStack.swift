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
        // For some reason @Environment doesn't give us bindings by default, though they're internally there
        NavigationStack(path: router.pathBinding) {
            self.content()
                .environment(\.router, self.router)
        }
    }
}
