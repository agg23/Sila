//
//  DataLoader.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import SwiftUI

enum Status<T> {
    case loading(T?)
    case idle
    case finished(T)
    case error(Error)
}

@Observable class DataLoader<T, Changable: Equatable> {
    var status: Status<T> = .idle
    @ObservationIgnored private var changable: Changable? = nil
    @ObservationIgnored private var task: (() async throws -> T)? = nil
    @ObservationIgnored private var runningTask: Task<Status<T>, Error>? = nil

    func loadIfNecessary(task: @escaping () async throws -> T, onChange: Changable? = nil) async throws {
        self.task = task

        // Check changes before updating it (if in idle)
        if onChange != nil && onChange != self.changable {
            // We need to refresh
            self.changable = onChange

            try await self.refresh()
        } else {
            switch self.status {
            case .idle:
                // Save changable for future updates
                self.changable = onChange
                break
            default:
                break
            }
        }
    }

    func refresh() async throws {
        self.status = try await self.refreshWithRunningTask {
            try await self.refreshDeferredData()
        }
    }

    func completeCancel() {
        self.runningTask = nil
        // Drop out of loading state
        switch self.status {
        case .loading(let data):
            if let data = data {
                self.status = .finished(data)
            } else {
                self.status = .idle
            }
        default:
            break
        }
    }

    func refresh(minDurationSecs: UInt64) async throws {
        async let newStatusAsync = try await self.refreshWithRunningTask {
            try await self.refreshDeferredData(preventLoadingState: true)
        }
        async let sleep: ()? = try? await Task.sleep(nanoseconds: minDurationSecs * NSEC_PER_SEC)
        let (newStatus, _) = await (try newStatusAsync, sleep)

        guard !Task.isCancelled else {
            return
        }

        self.status = newStatus
    }

    private func cancel() {
        if let runningTask = self.runningTask {
            runningTask.cancel()
            self.completeCancel()
        }
    }

    private func refreshWithRunningTask(_ thunk: @escaping () async throws -> Status<T>) async throws -> Status<T> {
        self.cancel()

        let task = Task {
            try await thunk()
        } as Task<Status<T>, Error>
        self.runningTask = task

        // Can only throw CancellationError
        return try await task.value
    }

    private func refreshDeferredData(preventLoadingState: Bool = false) async throws -> Status<T> {
        guard let task = self.task else {
            fatalError("Incorrectly set up DataLoader")
        }

        do {
            var existingData: T? = nil

            switch self.status {
            case .loading(let existing):
                existingData = existing
            case .finished(let existing):
                existingData = existing
            default:
                break
            }

            try Task.checkCancellation()

            if !preventLoadingState {
                self.status = .loading(existingData)
            }

            let result = try await Status<T>.finished(task())

            self.runningTask = nil

            try Task.checkCancellation()

            return result
        } catch let error as CancellationError {
            throw error
        } catch {
            self.runningTask = nil

            if let error = error as? DecodingError {
                print(error)
            }

            return .error(error)
        }
    }
}
