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
    @ObservationIgnored var changable: Changable? = nil
    @ObservationIgnored var task: (() async throws -> T)? = nil
    @ObservationIgnored var runningTask: Task<Status<T>, Error>? = nil

    func get(task: @escaping () async throws -> T, onChange: Changable? = nil) -> Status<T> {
        self.task = task

        // Check changes before updating it (if in idle)
        if onChange != nil && onChange != self.changable {
            // We need to refresh
            Task {
                await self.refresh()
            }
            self.changable = onChange
        }

        switch self.status {
        case .idle:
            // Save changable for future updates
            self.changable = onChange
            break
        default:
            break
        }

        return self.status
    }

    func onAppear() async {
        switch self.status {
        case .idle:
            // We want to refresh only if we haven't fetched data before
            await self.refresh()
        default:
            break
        }
    }

    func cancel() {
        if let runningTask = self.runningTask {
            runningTask.cancel()
            self.runningTask = nil
        }
    }

    private func refreshWithRunningTask(_ task: Task<Status<T>, Error>) async -> Status<T> {
        self.cancel()

        self.runningTask = task

        // Can not throw
        return try! await task.value
    }

    func refresh() async {
        self.status = await self.refreshWithRunningTask(Task {
            await self.refreshDeferredData()
        })
    }

    func refresh(minDurationSecs: UInt64) async {
        async let newStatusAsync = await self.refreshWithRunningTask(Task {
            await self.refreshDeferredData(preventLoadingState: true)
        })
        async let sleep: ()? = try? await Task.sleep(nanoseconds: minDurationSecs * NSEC_PER_SEC)
        let (newStatus, _) = await (newStatusAsync, sleep)

        guard !Task.isCancelled else {
            return
        }

        self.status = newStatus
    }

    private func refreshDeferredData(preventLoadingState: Bool = false) async -> Status<T> {
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

            guard !Task.isCancelled else {
                return self.status
            }

            if !preventLoadingState {
                self.status = .loading(existingData)
            }

            let result = try await Status<T>.finished(task())

            self.runningTask = nil

            guard !Task.isCancelled else {
                // We've cancelled. Don't assign data
                return self.status
            }

            return result
        } catch {
            guard !Task.isCancelled else {
                return self.status
            }

            self.runningTask = nil

            return .error(error)
        }
    }
}
