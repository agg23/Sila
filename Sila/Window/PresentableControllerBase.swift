//
//  PresentableControllerBase.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Combine

/// Represents a class of presentable that should be tracked. Discriminated on contentId
open class PresentableControllerBase: ObservableObject {
    @Published private(set) var isVisible: Bool = false
    @Published private(set) var activeRoles: Set<PresentationRole> = []

    let contentId: String
    var onDestroy: (() -> Void)? = nil
    private var manager: PresentableInternalManager!

    /// Tracks internal visibility state
    private var lastTriggeredVisible = false

    public init(contentId: String) {
        self.contentId = contentId
        self.manager = PresentableInternalManager(visibilityChangeCallback: { [weak self] visible in
            Task { @MainActor in
                await self?.handleVisibilityChange(visible: visible)
            }
        }, activeRoleCallback: { [weak self] roles in
            Task { @MainActor in
                self?.handleRolesChange(roles: roles)
            }
        })
    }

    func attach(role: PresentationRole) async -> PresenterToken {
        await self.manager.attach(role: role)
    }

    func detach(token: PresenterToken) async {
        await self.manager.detach(token: token)
    }

    func updateRole(token: PresenterToken, newRole: PresentationRole) async {
        await self.manager.updateRole(token: token, newRole: newRole)
    }

    open func willBecomeVisible() async {}
    open func didBecomeVisible() async {}
    open func willBecomeHidden() async {}
    open func didBecomeHidden() async {}

    @MainActor
    private func handleVisibilityChange(visible: Bool) async {
        self.isVisible = visible

        if visible && !self.lastTriggeredVisible {
            self.lastTriggeredVisible = true
            await self.willBecomeVisible()
            print("Did become visible \(self.contentId)")
            await self.didBecomeVisible()
        } else if !visible && self.lastTriggeredVisible {
            self.lastTriggeredVisible = false
            await self.willBecomeHidden()
            print("Did become hidden \(self.contentId)")
            await self.didBecomeHidden()
            self.onDestroy?()
            // TODO: Destroy controller
        }
    }

    @MainActor
    private func handleRolesChange(roles: Set<PresentationRole>) {
        self.activeRoles = roles
    }
}
