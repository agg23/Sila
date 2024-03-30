//
//  DataLoader.swift
//  VisionTwitch
//
//  Created by Adam Gastineau on 2/21/24.
//

import SwiftUI
import Twitch

enum Status<T> {
    case loading(T?)
    case idle
    case finished(T)
    /// Loading additional pages of data
    case loadingMore(T)
    case error(Error)
}

typealias StandardDataLoader<T> = DataLoader<T, (Helix, AuthUser?), AuthStatus>

@Observable class DataLoader<T, DataAugment, Changable: Equatable> {
    var status: Status<T> = .idle

    @ObservationIgnored private var changable: Changable? = nil
    @ObservationIgnored private var task: ((_: DataAugment) async throws -> T)? = nil
    @ObservationIgnored private var dataAugment: DataAugment? = nil
    @ObservationIgnored private var runningTask: Task<Status<T>, Error>? = nil

    func loadIfNecessary(task: @escaping (_: DataAugment) async throws -> T, dataAugment: DataAugment, onChange: Changable? = nil) async throws {
        self.task = task
        self.dataAugment = dataAugment

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

    func requestMore(withGetter task: (_: T, _: DataAugment) async throws -> T) async {
        guard let dataAugment = self.dataAugment else {
            fatalError("Incorrectly set up DataLoader")
        }

        switch self.status {
        case .finished(let data):
            self.status = .loadingMore(data)

            do {
                let newData = try await task(data, dataAugment)

                self.status = .finished(newData)
            } catch {
                self.status = .finished(data)
                return
            }
        default:
            break
        }
    }

    func isLoadingMore() -> Bool {
        if case .loadingMore = status {
            return true
        }

        return false
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
        guard let task = self.task, let dataAugment = self.dataAugment else {
            // This occurs in a race against the render `loadIfNecessary` call
            // Ignore the request if this occurs
            // fatalError("Incorrectly set up DataLoader")
            return self.status
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

            let result = try await Status<T>.finished(task(dataAugment))

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
