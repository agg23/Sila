//
//  PresentableManager.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Foundation

/// Internal actor that manages presenters and debounced stop/start callback.
actor PresentableInternalManager {
    typealias VisibilityCallback = (_ visible: Bool) -> Void
    typealias ActiveRoleCallback = (_ roles: Set<PresentationRole>) -> Void

    private var presenters: [UUID: PresentationRole] = [:]
    private var visibilityChangeCallback: VisibilityCallback
    private var activeRoleChangeCallback: ActiveRoleCallback
    private var stopDebounceMilliseconds: Int

    private var pendingStopTask: Task<Void, Never>? = nil

    init(stopDebounceMilliseconds: Int = 200, visibilityChangeCallback: @escaping VisibilityCallback, activeRoleCallback: @escaping ActiveRoleCallback) {
        self.stopDebounceMilliseconds = stopDebounceMilliseconds
        self.visibilityChangeCallback = visibilityChangeCallback
        self.activeRoleChangeCallback = activeRoleCallback
    }

    func attach(role: PresentationRole) -> PresenterToken {
        let id = UUID()
        self.presenters[id] = role
        // We're visible again, cancel any pending
        self.pendingStopTask?.cancel()
        self.pendingStopTask = nil
        self.notifyRolesIfChanged()
        self.notifyVisibilityIfChanged()
        return PresenterToken(id: id, role: role)
    }

    func detach(token: PresenterToken) {
        self.presenters.removeValue(forKey: token.id)
        self.notifyRolesIfChanged()

        if self.presenters.isEmpty {
            // If no presenters, schedule stop
            self.pendingStopTask?.cancel()
            self.pendingStopTask = Task { [weak self] in
                do {
                    try await Task.sleep(nanoseconds: UInt64(self?.stopDebounceMilliseconds ?? 200) * 1_000_000)
                } catch {
                    return
                }
                await self?.notifyVisibilityIfChanged()
                await self?.clearPending()
            }
        } else {
            // Still visible
            self.notifyVisibilityIfChanged()
        }
    }

    func updateRole(token: PresenterToken, newRole: PresentationRole) {
        if self.presenters[token.id] != nil {
            self.presenters[token.id] = newRole
            self.notifyVisibilityIfChanged()
        }
    }

    private func clearPending() {
        self.pendingStopTask = nil
    }

    private func notifyVisibilityIfChanged() {
        self.visibilityChangeCallback(!self.presenters.isEmpty)
    }

    private func notifyRolesIfChanged() {
        self.activeRoleChangeCallback(Set(self.presenters.values))
    }
}
