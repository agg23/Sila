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
    private var callback: VisibilityCallback
    private var stopDebounceMilliseconds: Int

    // For debounce: store scheduled Task
    private var pendingStopTask: Task<Void, Never>? = nil

    init(stopDebounceMilliseconds: Int = 200, callback: @escaping VisibilityCallback) {
        self.callback = callback
        self.stopDebounceMilliseconds = stopDebounceMilliseconds
    }

    func attach(role: PresentationRole) -> PresenterToken {
        // create token, add presenter
        let id = UUID()
        presenters[id] = role
        // If we had a pending stop, cancel it because we're visible again
        pendingStopTask?.cancel()
        pendingStopTask = nil
        // immediately notify state change
        notifyIfChanged()
        return PresenterToken(id: id, role: role)
    }

    func detach(token: PresenterToken) {
        presenters.removeValue(forKey: token.id)
        // If presenters empty, schedule a debounced stop
        if presenters.isEmpty {
            // cancel previous pending (should be nil)
            pendingStopTask?.cancel()
            pendingStopTask = Task { [weak self] in
                // sleep with cancellation support
                do {
                    try await Task.sleep(nanoseconds: UInt64(self?.stopDebounceMilliseconds ?? 200) * 1_000_000)
                } catch {
                    return // cancelled
                }
                await self?.notifyIfChanged()
                // clear pending
                await self?.clearPending()
            }
        } else {
            // still visible, notify immediately
            notifyIfChanged()
        }
    }

    func updateRole(token: PresenterToken, newRole: PresentationRole) {
        if presenters[token.id] != nil {
            presenters[token.id] = newRole
            notifyIfChanged()
        }
    }

    private func clearPending() {
        pendingStopTask = nil
    }

    private func notifyIfChanged() {
        let visible = !presenters.isEmpty
        let roles = Set(presenters.values)
        callback(visible, roles)
    }
}
