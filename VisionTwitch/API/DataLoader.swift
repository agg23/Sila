//
//  DataLoader.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import SwiftUI

@propertyWrapper
struct DataLoader<T, Changable: Equatable>: DynamicProperty {
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
        let dataLoader: DataLoader<T, Changable>

        init(dataLoader: DataLoader<T, Changable>) {
            self.dataLoader = dataLoader
        }

        func get(task: @escaping () async throws -> T, onChange: Changable? = nil) -> Status {
            self.dataLoader.status.get(task: task, onChange: onChange)
        }

        func refresh(task: @escaping () async throws -> T) -> Status {
            self.dataLoader.status.get(task: task)
        }
    }

    @Observable class Loader {
        var status: Status = .idle
        var changable: Changable? = nil

        func get(task: @escaping () async throws -> T, onChange: Changable? = nil) -> Status {
            switch self.status {
            case .idle:
                self.refresh(task: task)
                // Save changable for future updates
                self.changable = onChange
            default:
                if onChange != self.changable {
                    // We need to refresh
                    self.changable = onChange
                    self.refresh(task: task)
                }
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
