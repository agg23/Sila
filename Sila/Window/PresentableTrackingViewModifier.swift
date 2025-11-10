//
//  PresentableTrackingViewModifier.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import SwiftUI

struct PresentableTrackingViewModifier<T: PresentableControllerBase>: ViewModifier {
    @StateObject private var presentableController: T
    @State private var token: PresenterToken?

    let withController: ((T) -> Void)?

    init(contentId: String, factory: @escaping () -> T, withController: ((T) -> Void)?) {
        self._presentableController = StateObject(wrappedValue: PresentableControllerRegistry.shared(for: T.self).controller(for: contentId, factory: factory) as! T)
        self.withController = withController
    }

    func body(content: Content) -> some View {
        content
            .task {
                if let withController = self.withController {
                    withController(self.presentableController)
                }

                if let token = self.token {
                    await self.presentableController.updateRole(token: token, newRole: .embedded)
                } else {
                    self.token = await self.presentableController.attach(role: .embedded)
                }
            }
            .onDisappear {
                if let token = self.token {
                    Task {
                        await self.presentableController.detach(token: token)
                        self.token = nil
                    }
                }
            }
    }
}

extension View {
    func presentableTracking<T: PresentableControllerBase>(contentId: String, factory: @escaping () -> T, withController: ((T) -> Void)? = nil) -> some View {
        self.modifier(PresentableTrackingViewModifier<T>(contentId: contentId, factory: factory, withController: withController))
    }
}
