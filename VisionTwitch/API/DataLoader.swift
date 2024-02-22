//
//  DataLoader.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import SwiftUI

@propertyWrapper
struct DataLoader<T>: DynamicProperty {
    enum Status {
        case loading(T?)
        case idle
        case finished(T)
        case error(Error)
    }

    @State
    private var status = Loader()

    public var wrappedValue: WrappedValue {
        WrappedValue(dataLoader: self)
    }

    public class WrappedValue {
        let dataLoader: DataLoader<T>

        init(dataLoader: DataLoader<T>) {
            self.dataLoader = dataLoader
        }

        func get(task: @escaping () async throws -> T) -> Status {
            self.dataLoader.status.get(task: task)
        }

        func refresh(task: @escaping () async throws -> T) -> Status {
            self.dataLoader.status.get(task: task)
        }
    }

    @Observable class Loader {
        var status: Status = .idle

        func get(task: @escaping () async throws -> T) -> Status {
            switch self.status {
            case .idle:
                self.refresh(task: task)
            default:
                break
            }
            return self.status
        }

        func refresh(task: @escaping () async throws -> T) {
            Task {
                do {
                    var existingData: T? = nil

                    switch self.status {
                    case .loading(let existing):
                        existingData = existing
                    default:
                        break
                    }

                    self.status = .loading(existingData)
                    self.status = try await .finished(task())
                } catch {
                    self.status = .error(error)
                }
            }
        }
    }
}
