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

    @State private var loader = Loader()

    public var wrappedValue: WrappedValue {
        WrappedValue(dataLoader: self)
    }

    public class WrappedValue {
        let dataLoader: DataLoader<T, Changable>

        init(dataLoader: DataLoader<T, Changable>) {
            self.dataLoader = dataLoader
        }

        func get(task: @escaping () async throws -> T, onChange: Changable? = nil) -> Status {
            self.dataLoader.loader.get(task: task, onChange: onChange)
        }

        func refresh() async {
            await self.dataLoader.loader.refresh()
        }

        func refresh(minDurationSecs: UInt64) async {
            await self.dataLoader.loader.refresh(minDurationSecs: minDurationSecs)
        }

        func update(task: @escaping () async throws -> T) {
            self.dataLoader.loader.task = task
        }
    }

    @Observable class Loader {
        var status: Status = .idle
        var changable: Changable? = nil
        var task: (() async throws -> T)? = nil

        func get(task: @escaping () async throws -> T, onChange: Changable? = nil) -> Status {
            self.task = task

            switch self.status {
            case .idle:
                Task {
                    await self.refresh()
                }
                // Save changable for future updates
                self.changable = onChange
            default:
                if onChange != nil && onChange != self.changable {
                    // We need to refresh
                    Task {
                        await self.refresh()
                    }
                    self.changable = onChange
                }
                break
            }
            return self.status
        }

        func refresh() async {
            self.status = await self.refreshDeferredData()
        }

        func refresh(minDurationSecs: UInt64) async {
            async let newStatusAsync = await self.refreshDeferredData(preventLoadingState: true)
            async let sleep: ()? = try? await Task.sleep(nanoseconds: minDurationSecs * NSEC_PER_SEC)
            let (newStatus, _) = await (newStatusAsync, sleep)

            self.status = newStatus
        }

        private func refreshDeferredData(preventLoadingState: Bool = false) async -> Status {
            guard let task = self.task else {
                fatalError("Incorrectly set up DataLoader")
            }

            do {
                var existingData: T? = nil

                switch self.status {
                case .loading(let existing):
                    existingData = existing
                default:
                    break
                }

                if !preventLoadingState {
                    self.status = .loading(existingData)
                }

                return try await .finished(task())
            } catch {
                return .error(error)
            }
        }
    }
}
