//
//  PresentableControllerRegistry.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

import Combine

// Type erased for storage
protocol PresentableControllerRegistryProtocol: AnyObject {}

/// Tracks all presentable "types" (represented by controllers)
class PresentableControllerRegistry {
    private static var storage: [ObjectIdentifier: PresentableControllerRegistryProtocol] = [:]

    static func shared<T: PresentableControllerBase>(for type: T.Type) -> SpecificPresentableControllerRegistry<T> {
        let registry = PresentableControllerRegistry.storage[ObjectIdentifier(type)] as? SpecificPresentableControllerRegistry<T>

        if let registry = registry {
            return registry
        } else {
            let registry = SpecificPresentableControllerRegistry<T>()
            PresentableControllerRegistry.storage[ObjectIdentifier(type)] = registry
            return registry
        }
    }
}

class SpecificPresentableControllerRegistry<T: PresentableControllerBase>: PresentableControllerRegistryProtocol {
    @MainActor
    private var storage: [String: T] = [:]
    @MainActor
    private var handles: [String: PresentableHandle<T>] = [:]

    @MainActor
    var all: [T] {
        Array(self.storage.values)
    }

    @MainActor
    func controller(for id: String) -> T? {
        self.storage[id]
    }

    @MainActor
    func controller(for id: String, factory: () -> T) -> T {
        if let existing = self.storage[id] {
            return existing
    }

        print("Instantiating \(id)")
        let newOne = factory()
        newOne.onDestroy = { [weak self] in
            self?.removeController(for: id)
        }
        self.storage[id] = newOne
        self.handle(for: id).attachController(newOne)
        return newOne
    }

    @MainActor
    func removeController(for id: String) {
        print("Destroying \(id)")
        self.storage.removeValue(forKey: id)
        self.handles[id]?.detachController()
    }

    @MainActor
    func handle(for id: String) -> PresentableHandle<T> {
        if let existing = self.handles[id] {
            return existing
        }
        let handle = PresentableHandle<T>()
        self.handles[id] = handle
        if let controller = self.storage[id] {
            handle.attachController(controller)
        }
        return handle
    }
}

@MainActor
final class PresentableHandle<T: PresentableControllerBase>: ObservableObject {
    /// Whether the presentable is known to be visible. Visibility will persist for some period after it stops being attached
    @Published var isVisible: Bool = false
    /// Whether the presentable is currently attached. This may flicker on/off if a view is transitioning between embedded and standalone versions
    @Published var isAttached: Bool = false

    @Published var hasEmbedded: Bool = false
    @Published var hasStandalone: Bool = false

    weak var controller: T?

    private var visibleCancellable: AnyCancellable?
    private var attachedCancellable: AnyCancellable?

    func attachController(_ controller: T) {
        guard self.controller !== controller else {
            return
        }
        self.visibleCancellable?.cancel()
        self.attachedCancellable?.cancel()

        self.controller = controller
        self.isVisible = controller.isVisible
        self.isAttached = !controller.activeRoles.isEmpty

        self.visibleCancellable = controller.$isVisible.sink { [weak self] newValue in
            self?.isVisible = newValue
        }
        self.attachedCancellable = controller.$activeRoles.sink { [weak self] newValue in
            print("isAttached \(newValue)")
            self?.isAttached = !newValue.isEmpty
            self?.hasEmbedded = newValue.contains(.embedded)
            self?.hasStandalone = newValue.contains(.standalone)
        }
    }

    func detachController() {
        self.visibleCancellable?.cancel()
        self.visibleCancellable = nil

        self.attachedCancellable?.cancel()
        self.attachedCancellable = nil
        
        self.controller = nil

        self.isVisible = false
        self.isAttached = false
    }
}
