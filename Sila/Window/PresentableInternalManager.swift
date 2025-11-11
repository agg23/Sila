//
//  PresentableManager.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Foundation

/// Internal actor that manages presenters and debounced stop/start callback.
actor PresentableInternalManager {
    typealias VisibilityCallback = (_ visible: Bool, _ roles: Set<PresentationRole>) -> Void

    private var presenters: [UUID: PresentationRole] = [:]
    private var visibilityChangeCallback: VisibilityCallback
    private var stopDebounceMilliseconds: Int

    private var pendingStopTask: Task<Void, Never>? = nil

    init(stopDebounceMilliseconds: Int = 200, visibilityChangeCallback: @escaping VisibilityCallback) {
        self.stopDebounceMilliseconds = stopDebounceMilliseconds
        self.visibilityChangeCallback = visibilityChangeCallback
    }

    func attach(role: PresentationRole) -> PresenterToken {
        let id = UUID()
        self.presenters[id] = role
        // We're visible again, cancel any pending
        self.pendingStopTask?.cancel()
        self.pendingStopTask = nil
        self.notifyIfChanged()
        return PresenterToken(id: id, role: role)
    }

    func detach(token: PresenterToken) {
        self.presenters.removeValue(forKey: token.id)
        if self.presenters.isEmpty {
            // If no presenters, schedule stop
            self.pendingStopTask?.cancel()
            self.pendingStopTask = Task { [weak self] in
                do {
                    try await Task.sleep(nanoseconds: UInt64(self?.stopDebounceMilliseconds ?? 200) * 1_000_000)
                } catch {
                    return
                }
                await self?.notifyIfChanged()
                await self?.clearPending()
            }
        } else {
            // Still visible
            self.notifyIfChanged()
        }
    }

    func updateRole(token: PresenterToken, newRole: PresentationRole) {
        if self.presenters[token.id] != nil {
            self.presenters[token.id] = newRole
            self.notifyIfChanged()
        }
    }

    private func clearPending() {
        self.pendingStopTask = nil
    }

    private func notifyIfChanged() {
        let visible = !self.presenters.isEmpty
        let roles = Set(self.presenters.values)
        self.visibilityChangeCallback(visible, roles)
    }
}
