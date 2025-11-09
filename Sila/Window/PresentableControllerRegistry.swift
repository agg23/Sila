//
//  PresentableControllerRegistry.swift
//  Sila
//
//  Created by Adam Gastineau on 11/9/25.
//

/// Tracks all presentable "types" (represented by controllers)
class PresentableControllerRegistry {
    static let shared = PresentableControllerRegistry()

    @MainActor
    private var storage: [String: PresentableControllerBase] = [:]

    @MainActor
    func controller(for id: String, factory: () -> PresentableControllerBase) -> PresentableControllerBase {
        if let existing = self.storage[id] { return existing }
        let newOne = factory()
        self.storage[id] = newOne
        return newOne
    }

    @MainActor
    func removeController(for id: String) {
        self.storage.removeValue(forKey: id)
    }
}
