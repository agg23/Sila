//
//  PresentableControllerRegistry.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

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
        newOne.onDestroy = {
            self.removeController(for: id)
        }
        self.storage[id] = newOne
        return newOne
    }

    @MainActor
    func removeController(for id: String) {
        print("Destroying \(id)")
        self.storage.removeValue(forKey: id)
    }
}
