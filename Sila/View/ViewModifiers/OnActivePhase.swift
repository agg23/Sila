//
//  OnActivePhase.swift
//  Sila
//
//  Created by Adam Gastineau on 12/1/25.
//

import SwiftUI

private struct OnActivePhase: ViewModifier {
    @Environment(\.scenePhase) var scenePhase

    let onActive: () -> ()

    func body(content: Content) -> some View {
        content
            .onChange(of: self.scenePhase, initial: true) { _, newValue in
                if newValue == .active {
                    self.onActive()
                }
            }
    }
}


extension View {
    func onActivePhase(_ onActive: @escaping () -> ()) -> some View {
        self.modifier(OnActivePhase(onActive: onActive))
    }
}
